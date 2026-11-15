//! pdf-service: wiring and the HTTP server (ADR-0051 §3, ADR-0052).

use std::collections::HashMap;
use std::process::ExitCode;
use std::sync::Arc;

use pdf_adapters::auth::TokenVerifier;
use pdf_adapters::config::Config;
use pdf_adapters::http::{AppState, router};
use pdf_adapters::render::KrillaRenderer;
use pdf_adapters::security::SecurityEvents;
use pdf_adapters::{SystemClock, telemetry};
use pdf_application::PrintSheets;

fn main() -> ExitCode {
    let vars: HashMap<String, String> = std::env::vars().collect();
    let config = match Config::from_vars(&vars) {
        Ok(config) => config,
        Err(error) => {
            eprintln!("pdf-service: {error}");
            return ExitCode::FAILURE;
        }
    };
    let runtime = match tokio::runtime::Builder::new_multi_thread().enable_all().build() {
        Ok(runtime) => runtime,
        Err(error) => {
            eprintln!("pdf-service: cannot start the runtime: {error}");
            return ExitCode::FAILURE;
        }
    };
    match runtime.block_on(serve(config)) {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("pdf-service: {error}");
            ExitCode::FAILURE
        }
    }
}

async fn serve(config: Config) -> Result<(), String> {
    let _telemetry = telemetry::init(&config)?;
    let renderer = KrillaRenderer::new().map_err(|e| e.to_string())?;
    let sheets = PrintSheets::new(Arc::new(renderer), Arc::new(SystemClock));
    let verifier = TokenVerifier::remote(&config)?;
    let parallel = std::thread::available_parallelism().map_or(2, std::num::NonZero::get);
    let app = router(AppState::new(sheets, verifier, Arc::new(SecurityEvents::default()), parallel));
    let listener = tokio::net::TcpListener::bind(("0.0.0.0", config.port))
        .await
        .map_err(|e| format!("cannot listen on port {}: {e}", config.port))?;
    tracing::info!(target: "pdf_service", port = config.port, realm = %config.auth_server_url, "pdf-service listening");
    axum::serve(listener, app).with_graceful_shutdown(shutdown()).await.map_err(|e| format!("server: {e}"))
}

/// SIGTERM (Kubernetes, Podman) or Ctrl-C.
async fn shutdown() {
    let interrupt = async {
        let _ = tokio::signal::ctrl_c().await;
    };
    let terminate = async {
        match tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate()) {
            Ok(mut signal) => {
                signal.recv().await;
            }
            Err(_) => std::future::pending::<()>().await,
        }
    };
    tokio::select! {
        () = interrupt => {},
        () = terminate => {},
    }
    tracing::info!(target: "pdf_service", "shutting down");
}
