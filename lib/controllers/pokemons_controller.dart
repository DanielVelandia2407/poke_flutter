import 'package:flutter/foundation.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';

class PokemonsController extends ChangeNotifier {
  final PokeApiService _service;

  static const _pageSize = 20;

  List<Pokemon> _pokemons = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;

  List<({String name, String url})>? _index;
  List<Pokemon> _searchResults = [];
  String _query = '';
  bool _searching = false;
  Object? _searchFailure;

  String? _typeFilter;
  List<({String name, String url})> _typeMembers = [];
  List<Pokemon> _filterResults = [];
  bool _filtering = false;
  bool _filteringMore = false;
  Object? _filterFailure;

  PokemonsController(this._service);

  List<Pokemon> get pokemons => _pokemons;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  Object? get error => _error;

  List<Pokemon> get searchResults => _searchResults;
  String get query => _query;
  bool get searching => _searching;
  bool get searchFailed => _searchFailure != null;
  Object? get searchFailure => _searchFailure;

  String? get typeFilter => _typeFilter;
  List<Pokemon> get filterResults => _filterResults;
  bool get filtering => _filtering;
  bool get filteringMore => _filteringMore;
  bool get filterFailed => _filterFailure != null;
  Object? get filterFailure => _filterFailure;
  bool get filterHasMore => _filterResults.length < _typeMembers.length;

  Future<void> load() async {
    _loading = true;
    _error = null;
    _hasMore = true;
    notifyListeners();
    try {
      _pokemons = await _service.fetchPokemons(limit: _pageSize);
    } catch (e) {
      _error = e;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> search(String query) async {
    _query = query;
    if (query.isEmpty) {
      _searchResults = [];
      _searching = false;
      _searchFailure = null;
      notifyListeners();
      return;
    }
    _searching = true;
    _searchFailure = null;
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
    } catch (e) {
      if (_query != query) return;
      _searchFailure = e;
    } finally {
      if (_query == query) {
        _searching = false;
        notifyListeners();
      }
    }
  }

  Future<Object?> loadMore() async {
    if (_loadingMore || !_hasMore) return null;
    _loadingMore = true;
    notifyListeners();
    try {
      final more = await _service.fetchPokemons(
        offset: _pokemons.length,
        limit: _pageSize,
      );
      _pokemons = [..._pokemons, ...more];
      _hasMore = more.length == _pageSize;
      return null;
    } catch (e) {
      return e;
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> filterByType(String? type) async {
    _typeFilter = type;
    _filterFailure = null;
    if (type == null) {
      _typeMembers = [];
      _filterResults = [];
      notifyListeners();
      return;
    }
    _filtering = true;
    _filterResults = [];
    notifyListeners();
    try {
      _typeMembers = await _service.fetchTypeMembers(type);
      if (_typeFilter != type) return;
      final batch = _typeMembers.take(_pageSize).toList();
      final loadedByName = {
        for (final pokemon in _pokemons) pokemon.name.toLowerCase(): pokemon,
      };
      final results = await Future.wait(
        batch.map(
          (m) async => loadedByName[m.name] ?? await _service.fetchDetail(m.url),
        ),
      );
      if (_typeFilter != type) return;
      _filterResults = results;
    } catch (e) {
      if (_typeFilter != type) return;
      _filterFailure = e;
    } finally {
      if (_typeFilter == type) {
        _filtering = false;
        notifyListeners();
      }
    }
  }

  Future<void> filterLoadMore() async {
    if (_filteringMore || _typeFilter == null || !filterHasMore) return;
    final type = _typeFilter;
    _filteringMore = true;
    notifyListeners();
    try {
      final next = _typeMembers
          .skip(_filterResults.length)
          .take(_pageSize)
          .toList();
      final loadedByName = {
        for (final pokemon in _pokemons) pokemon.name.toLowerCase(): pokemon,
      };
      final more = await Future.wait(
        next.map(
          (m) async => loadedByName[m.name] ?? await _service.fetchDetail(m.url),
        ),
      );
      if (_typeFilter != type) return;
      _filterResults = [..._filterResults, ...more];
    } catch (_) {
    } finally {
      if (_typeFilter == type) {
        _filteringMore = false;
        notifyListeners();
      }
    }
  }
}
