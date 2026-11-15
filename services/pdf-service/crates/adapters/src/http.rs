//! The HTTP API (driving adapter, axum): `POST /internal/pdf/match-sheet` and `/internal/pdf/team-roster` of
//! `pdf.yaml`, behind bearer authentication; `/q/health/*` and `/q/metrics` as the Quarkus services (probes and
//! scraping; not routed by any gateway). Every error is Problem+JSON. The request body is read, parsed and rendered,
//! never logged nor put on a span: the request span carries the method, the route template and the status only.

use std::sync::Arc;
use std::time::Instant;

use axum::Router;
use axum::body::Body;
use axum::extract::{MatchedPath, Request, State};
use axum::http::{HeaderMap, HeaderValue, StatusCode, header};
use axum::middleware::{self, Next};
use axum::response::{IntoResponse, Response};
use axum::routing::{get, post};
use pdf_application::{PrintError, PrintSheets, RenderedPdf};
use pdf_domain::SheetError;
use tokio::sync::Semaphore;
use tracing::Instrument;

use crate::auth::{AuthFailure, TokenVerifier};
use crate::dto::{self, MatchSheetRequest, TeamRosterRequest};
use crate::problem::Problem;
use crate::security::{DenialKind, SecurityEvents};
use crate::telemetry;

/// Largest request body (`pdf.yaml`: 413 `PAYLOAD_TOO_LARGE` above it).
pub const BODY_LIMIT: usize = 256 * 1024;
pub const MATCH_SHEET: &str = "/internal/pdf/match-sheet";
pub const TEAM_ROSTER: &str = "/internal/pdf/team-roster";

/// What the handlers share.
#[derive(Debug, Clone)]
pub struct AppState {
    pub sheets: PrintSheets,
    pub verifier: Arc<TokenVerifier>,
    pub events: Arc<SecurityEvents>,
    /// Renders run on the blocking pool; at most this many at once (the rest wait).
    pub renders: Arc<Semaphore>,
}

impl AppState {
    pub fn new(sheets: PrintSheets, verifier: TokenVerifier, events: Arc<SecurityEvents>, parallel: usize) -> Self {
        Self { sheets, verifier: Arc::new(verifier), events, renders: Arc::new(Semaphore::new(parallel.max(1))) }
    }
}

pub fn router(state: AppState) -> Router {
    let internal = Router::new()
        .route(MATCH_SHEET, post(match_sheet))
        .route(TEAM_ROSTER, post(team_roster))
        .route_layer(middleware::from_fn_with_state(state.clone(), authenticate));
    Router::new()
        .merge(internal)
        .route("/q/health", get(health))
        .route("/q/health/live", get(health))
        .route("/q/health/ready", get(health))
        .route("/q/health/started", get(health))
        .route("/q/metrics", get(metrics))
        .fallback(|| async { Problem::not_found().into_response() })
        .method_not_allowed_fallback(|| async { Problem::method_not_allowed().into_response() })
        .layer(middleware::from_fn(observe))
        .with_state(state)
}

/// One server span and one access-log line per request: method, route template, status, duration. Nothing else.
async fn observe(request: Request, next: Next) -> Response {
    let method = request.method().clone();
    let route = request.extensions().get::<MatchedPath>().map_or("unmatched", MatchedPath::as_str).to_owned();
    let span = tracing::info_span!(
        "request",
        otel.name = %format!("{method} {route}"),
        otel.kind = "server",
        http.request.method = %method,
        http.route = %route,
        http.response.status_code = tracing::field::Empty,
    );
    telemetry::link_remote_parent(&span, request.headers());
    let started = Instant::now();
    let response = next.run(request).instrument(span.clone()).await;
    let status = response.status().as_u16();
    span.record("http.response.status_code", status);
    let millis = started.elapsed().as_millis();
    span.in_scope(|| {
        tracing::info!(target: "pdf_service::access", method = %method, route = %route, status, duration_ms = millis, "request");
    });
    response
}

async fn authenticate(
    State(state): State<AppState>,
    matched: MatchedPath,
    mut request: Request,
    next: Next,
) -> Response {
    let resource = format!("{} {}", request.method(), matched.as_str());
    match state.verifier.verify(request.headers().get(header::AUTHORIZATION)).await {
        Ok(caller) => {
            request.extensions_mut().insert(caller);
            next.run(request).await
        }
        Err(AuthFailure::Denied(denial)) => {
            state.events.deny(&denial, &resource);
            let problem = match denial.kind {
                DenialKind::Unauthenticated => Problem::unauthenticated(),
                DenialKind::InvalidToken => Problem::invalid_token(),
                DenialKind::RealmRole => Problem::forbidden(),
            };
            let mut response = problem.at(matched.as_str()).into_response();
            if denial.kind.status() == 401 {
                response.headers_mut().insert(header::WWW_AUTHENTICATE, HeaderValue::from_static("Bearer"));
            }
            response
        }
        Err(AuthFailure::Unavailable) => Problem::auth_unavailable().at(matched.as_str()).into_response(),
    }
}

async fn match_sheet(State(state): State<AppState>, request: Request) -> Response {
    let sheet = match read::<MatchSheetRequest>(request, MATCH_SHEET).await {
        Ok(body) => match body.into_domain() {
            Ok(sheet) => sheet,
            Err(violation) => {
                return Problem::from_sheet(&SheetError::Invalid(vec![violation])).at(MATCH_SHEET).into_response();
            }
        },
        Err(problem) => return (*problem).into_response(),
    };
    render(&state, MATCH_SHEET, move |sheets| sheets.match_sheet(&sheet)).await
}

async fn team_roster(State(state): State<AppState>, request: Request) -> Response {
    let roster = match read::<TeamRosterRequest>(request, TEAM_ROSTER).await {
        Ok(body) => match body.into_domain() {
            Ok(roster) => roster,
            Err(violation) => {
                return Problem::from_sheet(&SheetError::Invalid(vec![violation])).at(TEAM_ROSTER).into_response();
            }
        },
        Err(problem) => return (*problem).into_response(),
    };
    render(&state, TEAM_ROSTER, move |sheets| sheets.team_roster(&roster)).await
}

/// The body as `T`: JSON only, at most [`BODY_LIMIT`] bytes.
async fn read<T: serde::de::DeserializeOwned>(request: Request, path: &str) -> Result<T, Box<Problem>> {
    if !is_json(request.headers()) {
        return Err(Box::new(Problem::unsupported_media_type().at(path)));
    }
    let declared = request
        .headers()
        .get(header::CONTENT_LENGTH)
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.parse::<usize>().ok());
    if declared.is_some_and(|length| length > BODY_LIMIT) {
        return Err(Box::new(Problem::too_large(BODY_LIMIT).at(path)));
    }
    let bytes = axum::body::to_bytes(request.into_body(), BODY_LIMIT)
        .await
        .map_err(|_| Box::new(Problem::too_large(BODY_LIMIT).at(path)))?;
    dto::parse::<T>(&bytes).map_err(|problem| Box::new(problem.at(path)))
}

fn is_json(headers: &HeaderMap) -> bool {
    headers
        .get(header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.split(';').next())
        .is_some_and(|media| media.trim().eq_ignore_ascii_case("application/json"))
}

async fn render<F>(state: &AppState, path: &'static str, print: F) -> Response
where
    F: FnOnce(&PrintSheets) -> Result<RenderedPdf, PrintError> + Send + 'static,
{
    let Ok(_permit) = state.renders.acquire().await else {
        return Problem::internal().at(path).into_response();
    };
    let sheets = state.sheets.clone();
    let span = tracing::info_span!("render");
    let result = tokio::task::spawn_blocking(move || span.in_scope(|| print(&sheets))).await;
    match result {
        Ok(Ok(pdf)) => pdf_response(pdf),
        Ok(Err(PrintError::Rejected(error))) => Problem::from_sheet(&error).at(path).into_response(),
        Ok(Err(PrintError::Failed(error))) => {
            tracing::error!(target: "pdf_service::render", error = %error, "rendering failed");
            Problem::internal().at(path).into_response()
        }
        Err(_) => {
            tracing::error!(target: "pdf_service::render", "the rendering task failed");
            Problem::internal().at(path).into_response()
        }
    }
}

fn pdf_response(pdf: RenderedPdf) -> Response {
    let disposition = format!("attachment; filename=\"{}\"", pdf.file_name);
    let mut response = (StatusCode::OK, Body::from(pdf.bytes)).into_response();
    let headers = response.headers_mut();
    headers.insert(header::CONTENT_TYPE, HeaderValue::from_static("application/pdf"));
    headers.insert(header::CACHE_CONTROL, HeaderValue::from_static("no-store"));
    headers.insert(header::X_CONTENT_TYPE_OPTIONS, HeaderValue::from_static("nosniff"));
    // the file name is ASCII by construction (file_name::ascii); a failure would only drop the header
    if let Ok(value) = HeaderValue::from_str(&disposition) {
        headers.insert(header::CONTENT_DISPOSITION, value);
    }
    response
}

async fn health() -> Response {
    let mut response = (StatusCode::OK, r#"{"status":"UP","checks":[]}"#).into_response();
    response.headers_mut().insert(header::CONTENT_TYPE, HeaderValue::from_static("application/json"));
    response
}

async fn metrics(State(state): State<AppState>) -> Response {
    let mut response = (StatusCode::OK, state.events.prometheus()).into_response();
    response
        .headers_mut()
        .insert(header::CONTENT_TYPE, HeaderValue::from_static("text/plain; version=0.0.4; charset=utf-8"));
    response
}
