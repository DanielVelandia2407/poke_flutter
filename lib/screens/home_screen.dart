import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/pokemons_controller.dart';
import '../widgets/error_view.dart';
import '../widgets/pokemon_card.dart';

class HomeScreen extends StatefulWidget {
  final FavoritesController favorites;
  final PokemonsController pokemons;

  const HomeScreen({
    super.key,
    required this.favorites,
    required this.pokemons,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String? _searchError;

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _searchError = value.contains(RegExp(r'[0-9]'))
          ? 'El nombre solo lleva letras'
          : null;
    });
  }

  Future<void> _loadMore() async {
    final ok = await widget.pokemons.loadMore();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos cargar más Pokémon')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pokédex')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Busca un Pokémon...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                errorText: _searchError,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                widget.pokemons,
                widget.favorites,
              ]),
              builder: (_, _) {
                if (widget.pokemons.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (widget.pokemons.error != null) {
                  return ErrorView(onRetry: widget.pokemons.load);
                }

                final filtered = widget.pokemons.pokemons
                    .where(
                      (p) => p.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Ningún Pokémon coincide'));
                }

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid.builder(
                        itemCount: filtered.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                        itemBuilder: (_, index) {
                          final pokemon = filtered[index];
                          return GestureDetector(
                            onTap: () => context.push(
                              '/pokemon/${pokemon.id}',
                              extra: pokemon,
                            ),
                            child: PokemonCard(
                              pokemon: pokemon,
                              isFavorite: widget.favorites.contains(
                                pokemon.id,
                              ),
                              onFavoriteTap: () =>
                                  widget.favorites.toggle(pokemon.id),
                            ),
                          );
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: widget.pokemons.loadingMore
                                ? null
                                : _loadMore,
                            child: widget.pokemons.loadingMore
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Cargar más'),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
