import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesController extends ChangeNotifier {
  static const _key = 'favorites';

  final SharedPreferences _prefs;
  final Set<String> _ids;

  FavoritesController(this._prefs)
    : _ids = (_prefs.getStringList(_key) ?? []).toSet();

  bool contains(String id) => _ids.contains(id);

  Future<void> toggle(String id) async {
    if (!_ids.remove(id)) {
      _ids.add(id);
    }
    notifyListeners();
    await _prefs.setStringList(_key, _ids.toList());
  }
}
