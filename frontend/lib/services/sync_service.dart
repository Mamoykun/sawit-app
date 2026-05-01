// Stub for SyncService — full implementation in a future task.
import '../database/app_database.dart';
import 'api_service.dart';

class SyncService {
  final AppDatabase _db;
  final ApiService _api;

  SyncService({required AppDatabase db, required ApiService api})
      : _db = db, _api = api;

  void init() {
    // TODO: start connectivity listener and flush sync queue on reconnect
  }
}
