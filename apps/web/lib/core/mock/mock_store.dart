import 'package:shared_preferences/shared_preferences.dart';

/// Where the demo mock keeps what the user changed, so a reload does not lose it (decision 35).
/// Reads are synchronous (the mock replays its log while it is built); writes are fire and forget.
abstract interface class MockStore {
  String? read(String key);

  void write(String key, String value);

  /// Forgets everything the mock stored (and nothing else).
  Future<void> clearAll();
}

/// Key prefix of every entry the mock owns; [PrefsMockStore.clearAll] removes only these.
const mockStorePrefix = 'hoops.mock.';

/// Nothing survives the object: the default, so tests and a fresh adapter start from the seed.
class MemoryMockStore implements MockStore {
  final Map<String, String> _values = {};

  @override
  String? read(String key) => _values[key];

  @override
  void write(String key, String value) => _values[key] = value;

  @override
  Future<void> clearAll() async => _values.clear();
}

/// Browser storage through the `shared_preferences` the app already loads at start (local storage on the web).
class PrefsMockStore implements MockStore {
  const PrefsMockStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  void write(String key, String value) {
    // A full or blocked storage must not break the demo; the change just does not survive a reload.
    _prefs.setString(key, value).catchError((_) => false);
  }

  @override
  Future<void> clearAll() async {
    for (final key in _prefs.getKeys().toList()) {
      if (key.startsWith(mockStorePrefix)) await _prefs.remove(key);
    }
  }
}
