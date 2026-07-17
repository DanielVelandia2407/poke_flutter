import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../widgets/error_view.dart';
import '../widgets/pokemon_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _service = PokemonService();
  late Future<List<Pokemon>> _pokemonsFuture;

  Set<String> _favoriteIds = {};
  late final SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _pokemonsFuture = _service.fetchPokemons(); // same pattern as HomeScreen
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteIds = (_prefs.getStringList('favorites') ?? []).toSet();
    });
  }

  Future<void> _toggleFavorite(String id) async {
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
    await _prefs.setStringList('favorites', _favoriteIds.toList());
  }

  void _retry() {
    setState(() {
      _pokemonsFuture = _service.fetchPokemons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: FutureBuilder<List<Pokemon>>(
        future: _pokemonsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(onRetry: _retry);
          }

          final favorites = snapshot.data!
              .where((p) => _favoriteIds.contains(p.id))
              .toList();

          if (favorites.isEmpty) {
            return const Center(child: Text('Todavía no tienes favoritos :('));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (_, index) {
              final pokemon = favorites[index];
              return GestureDetector(
                onTap: () =>
                    context.push('/pokemon/${pokemon.id}', extra: pokemon),
                child: PokemonCard(
                  pokemon: pokemon,
                  isFavorite: true,
                  onFavoriteTap: () => _toggleFavorite(pokemon.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
