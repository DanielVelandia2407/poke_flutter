import 'package:flutter/foundation.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';

class PokemonsController extends ChangeNotifier {
  final PokeApiService _service;

  List<Pokemon> _pokemons = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  List<({String name, String url})>? _index;
  List<Pokemon> _searchResults = [];
  String _query = '';
  bool _searching = false;
  bool _searchFailed = false;

  PokemonsController(this._service);

  List<Pokemon> get pokemons => _pokemons;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;

  List<Pokemon> get searchResults => _searchResults;
  String get query => _query;
  bool get searching => _searching;
  bool get searchFailed => _searchFailed;

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

  Future<void> search(String query) async {
    _query = query;
    if (query.isEmpty) {
      _searchResults = [];
      _searching = false;
      _searchFailed = false;
      notifyListeners();
      return;
    }
    _searching = true;
    _searchFailed = false;
    notifyListeners();
    try {
      _index ??= await _service.fetchIndex();
      final lower = query.toLowerCase();
      final matches = _index!
          .where((entry) => entry.name.contains(lower))
          .take(20)
          .toList();
      final loadedByName = {
        for (final pokemon in _pokemons) pokemon.name.toLowerCase(): pokemon,
      };
      final results = await Future.wait(
        matches.map(
          (match) async =>
              loadedByName[match.name] ?? await _service.fetchDetail(match.url),
        ),
      );
      if (_query != query) return;
      _searchResults = results;
    } catch (_) {
      if (_query != query) return;
      _searchFailed = true;
    } finally {
      if (_query == query) {
        _searching = false;
        notifyListeners();
      }
    }
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
