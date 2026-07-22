import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/pokemons_controller.dart';
import '../models/pokemon.dart';
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
  Timer? _debounce;

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
      _searchError = value.contains(RegExp(r'[0-9]'))
          ? 'El nombre solo lleva letras'
          : null;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.pokemons.search(_searchQuery);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadMore() async {
    final error = await widget.pokemons.loadMore();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error))),
      );
    }
  }

  Widget _grid(List<Pokemon> pokemons, {Widget? footer}) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.builder(
            itemCount: pokemons.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (_, index) {
              final pokemon = pokemons[index];
              return GestureDetector(
                onTap: () => context.push('/pokemon/${pokemon.id}'),
                child: PokemonCard(
                  pokemon: pokemon,
                  isFavorite: widget.favorites.contains(pokemon.id),
                  onFavoriteTap: () => widget.favorites.toggle(pokemon.id),
                ),
              );
            },
          ),
        ),
        if (footer != null) SliverToBoxAdapter(child: footer),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (widget.pokemons.searching || widget.pokemons.query != _searchQuery) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.pokemons.searchFailed) {
      return ErrorView(
        error: widget.pokemons.searchFailure,
        onRetry: () => widget.pokemons.search(_searchQuery),
      );
    }
    if (widget.pokemons.searchResults.isEmpty) {
      return const Center(child: Text('Ningún Pokémon coincide'));
    }
    return _grid(widget.pokemons.searchResults);
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
                if (_searchQuery.isNotEmpty) {
                  return _buildSearchResults();
                }

                if (widget.pokemons.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (widget.pokemons.error != null) {
                  return ErrorView(
                    error: widget.pokemons.error,
                    onRetry: widget.pokemons.load,
                  );
                }

                return _grid(
                  widget.pokemons.pokemons,
                  footer: Padding(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
