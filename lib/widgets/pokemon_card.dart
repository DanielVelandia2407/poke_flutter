import 'package:flutter/material.dart';
import 'package:poke_app/models/pokemon.dart';
import 'package:poke_app/widgets/type_chip.dart';

class PokemonCard extends StatelessWidget {
  Pokemon pokemon;

  PokemonCard({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: .all(16),
        child: Column(children: [
        Image.network(
              pokemon.imagenUrl,
              height: 120,
              width: 120,
            ),
            const SizedBox(height: 8),
            Text(pokemon.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            TypeChip(type: pokemon.type),
      ],),
      ),
    );
  }
}
