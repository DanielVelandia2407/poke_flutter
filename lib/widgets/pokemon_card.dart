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
    final baseColor = TypeChip.colorOf(pokemon.type);
    final darkColor = Color.lerp(baseColor, Colors.black, 0.45)!;

    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [baseColor, darkColor],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -25,
              bottom: -25,
              child: Icon(
                Icons.catching_pokemon,
                size: 140,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              top: 12,
              left: 14,
              child: Text(
                '#${pokemon.id.padLeft(3, '0')}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Hero(
                        tag: 'pokemon-${pokemon.id}',
                        child: Image.network(
                          pokemon.imageUrl,
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
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pokemon.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        shadows: const [
                          Shadow(blurRadius: 6, color: Colors.black45),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (pokemon.type.isNotEmpty) TypeChip(type: pokemon.type),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? Colors.redAccent
                      : Colors.white.withValues(alpha: 0.9),
                ),
                onPressed: onFavoriteTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
