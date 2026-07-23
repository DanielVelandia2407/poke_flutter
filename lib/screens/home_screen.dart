import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/pokemons_controller.dart';
import '../models/pokemon.dart';
import '../widgets/error_view.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/type_filter_bar.dart';

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
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_searchQuery.isNotEmpty) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 400) return;
    if (widget.pokemons.typeFilter != null) {
      widget.pokemons.filterLoadMore();
    } else {
      _loadMore();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
      _searchError = value.contains(RegExp(r'[0-9]'))
          ? 'El nombre solo lleva letras'
          : null;
    });
    if (_searchQuery.isNotEmpty && widget.pokemons.typeFilter != null) {
      widget.pokemons.filterByType(null);
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.pokemons.search(_searchQuery);
    });
  }

  void _onTypeSelected(String type) {
    if (_searchQuery.isNotEmpty) {
      _searchController.clear();
      setState(() {
        _searchQuery = '';
        _searchError = null;
      });
      _debounce?.cancel();
      widget.pokemons.search('');
    }
    final next = widget.pokemons.typeFilter == type ? null : type;
    widget.pokemons.filterByType(next);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
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

  Widget _grid(List<Pokemon> pokemons, {Widget? footer, ScrollController? controller}) {
    return CustomScrollView(
      controller: controller,
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
                onTap: () {
                  precacheImage(
                    CachedNetworkImageProvider(pokemon.imageUrl),
                    context,
                  );
                  context.push('/pokemon/${pokemon.id}', extra: pokemon.type);
                },
                child: PokemonCard(
                  pokemon: pokemon,
                  favorites: widget.favorites,
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

  Widget _buildFilterResults() {
    if (widget.pokemons.filtering) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.pokemons.filterFailed) {
      return ErrorView(
        error: widget.pokemons.filterFailure,
        onRetry: () => widget.pokemons.filterByType(widget.pokemons.typeFilter),
      );
    }
    if (widget.pokemons.filterResults.isEmpty) {
      return const Center(child: Text('Ningún Pokémon de ese tipo'));
    }
    return _grid(
      widget.pokemons.filterResults,
      controller: _scrollController,
      footer: widget.pokemons.filteringMore
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pokédex')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Busca un Pokémon...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                errorText: _searchError,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListenableBuilder(
              listenable: widget.pokemons,
              builder: (_, _) => TypeFilterBar(
                selected: widget.pokemons.typeFilter,
                onSelect: _onTypeSelected,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.pokemons,
              builder: (_, _) {
                if (_searchQuery.isNotEmpty) {
                  return _buildSearchResults();
                }

                if (widget.pokemons.typeFilter != null) {
                  return _buildFilterResults();
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
                  controller: _scrollController,
                  footer: widget.pokemons.loadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
