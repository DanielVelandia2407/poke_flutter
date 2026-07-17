import 'package:flutter/foundation.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';

class PokemonsController extends ChangeNotifier {
  final PokeApiService _service;

  List<Pokemon> _pokemons = [];
  bool _loading = false;
  String? _error;

  PokemonsController(this._service);

  List<Pokemon> get pokemons => _pokemons;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _pokemons = await _service.fetchPokemons();
    } catch (_) {
      _error = 'No se pudieron cargar los Pokémon';
    }
    _loading = false;
    notifyListeners();
  }
}
