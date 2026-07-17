import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../widgets/error_view.dart';
import '../widgets/pokemon_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = PokemonService();
  late Future<List<Pokemon>> _pokemonsFuture;
  
  List<Pokemon> _pokemons = []; // accumulated across pages
  bool _isLoadingMore = false;

  String _searchQuery = '';
  String? _searchError; // null = no error
  Set<String> _favoriteIds = {};
  late final SharedPreferences _prefs; // single instance

  @override
  void initState() {
    super.initState();
    _pokemonsFuture = _loadFirstPage(); // fired ONCE, not per build
    _loadFavorites();
  }

  Future<List<Pokemon>> _loadFirstPage() async {
    final pokemons = await _service.fetchPokemons();
    _pokemons = pokemons; // no setState: FutureBuilder rebuilds on completion
    return pokemons;
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final more = await _service.fetchPokemons(offset: _pokemons.length);
      setState(() => _pokemons = [..._pokemons, ...more]);
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos cargar más Pokémon')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadFavorites() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteIds = (_prefs.getStringList('favorites') ?? []).toSet();
    });
  }

  Future<void> _toggleFavorite(String id) async {
    // Update UI immediately, then persist to disk.
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
    await _prefs.setStringList('favorites', _favoriteIds.toList());
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _searchError = value.contains(RegExp(r'[0-9]'))
          ? 'El nombre solo lleva letras'
          : null;
    });
  }

  void _retry() {
    setState(() {
      _pokemonsFuture = _loadFirstPage(); // a brand new Future
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pokédex')),
      body: FutureBuilder<List<Pokemon>>(
        future: _pokemonsFuture,
        builder: (context, snapshot) {
          // 1. LOADING — the Future is still incomplete
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. ERROR — the Future completed with an exception
          if (snapshot.hasError) {
            return ErrorView(onRetry: _retry);
          }

          // 3. SUCCESS — paint the accumulated list, not the snapshot,
          // so "Cargar más" can append pages to it
          return _buildContent(_pokemons);
        },
      ),
    );
  }

  Widget _buildContent(List<Pokemon> pokemons) {
    final filtered = pokemons
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Column(
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
          // GridView is a shorthand for CustomScrollView + SliverGrid; using
          // them directly lets a full-width button scroll after the grid.
          child: filtered.isEmpty
              ? const Center(child: Text('Ningún Pokémon coincide'))
              : CustomScrollView(
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
                              isFavorite: _favoriteIds.contains(pokemon.id),
                              onFavoriteTap: () => _toggleFavorite(pokemon.id),
                            ),
                          );
                        },
                      ),
                    ),
                    // scrolls with the grid: only visible at the very end
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isLoadingMore ? null : _loadMore,
                            child: _isLoadingMore
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
                ),
        ),
      ],
    );
  }
}
