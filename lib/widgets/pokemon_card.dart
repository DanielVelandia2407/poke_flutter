import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import 'type_chip.dart';

class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  const PokemonCard({
    super.key,
    required this.pokemon,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Stack(
        alignment: .center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Image.network(
                    pokemon.imagenUrl,
                    height: 120,
                    width: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Image.asset(
                      'assets/images/error.png',
                      height: 120,
                      width: 120,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(pokemon.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                if (pokemon.type.isNotEmpty) TypeChip(type: pokemon.type),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
              onPressed: onFavoriteTap,
            ),
          ),
        ],
      ),
    );
  }
}
