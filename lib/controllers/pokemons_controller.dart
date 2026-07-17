import 'package:flutter/foundation.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';

class PokemonsController extends ChangeNotifier {
  final PokeApiService _service;

  List<Pokemon> _pokemons = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  PokemonsController(this._service);

  List<Pokemon> get pokemons => _pokemons;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _pokemons = await _service.fetchPokemons();
    } catch (_) {
      _error = 'No pudimos cargar los Pokémon';
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> loadMore() async {
    _loadingMore = true;
    notifyListeners();
    try {
      final more = await _service.fetchPokemons(offset: _pokemons.length);
      _pokemons = [..._pokemons, ...more];
      return true;
    } catch (_) {
      return false;
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }
}
