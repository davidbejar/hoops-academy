// Entry point of the drift web worker (offline match store, WP13).
// Compiled to web/drift_worker.js by tool/fetch_web_db_assets.sh.
import 'package:drift/wasm.dart';

void main() => WasmDatabase.workerMainForOpen();
