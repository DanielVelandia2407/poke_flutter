import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/pokemons_controller.dart';
import '../widgets/pokemon_card.dart';

class FavoritesScreen extends StatelessWidget {
  final FavoritesController favorites;
  final PokemonsController pokemons;

  const FavoritesScreen({
    super.key,
    required this.favorites,
    required this.pokemons,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: ListenableBuilder(
        listenable: Listenable.merge([pokemons, favorites]),
        builder: (_, _) {
          final favoritePokemons = pokemons.pokemons
              .where((p) => favorites.contains(p.id))
              .toList();

          if (favoritePokemons.isEmpty) {
            return const Center(child: Text('Todavía no tienes favoritos :('));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoritePokemons.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (_, index) {
              final pokemon = favoritePokemons[index];
              return GestureDetector(
                onTap: () => context.push('/pokemon/${pokemon.id}'),
                child: PokemonCard(
                  pokemon: pokemon,
                  isFavorite: true,
                  onFavoriteTap: () => favorites.toggle(pokemon.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
