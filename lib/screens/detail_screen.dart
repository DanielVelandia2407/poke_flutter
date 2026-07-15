import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../widgets/type_chip.dart';

class DetailScreen extends StatelessWidget {
  final String id;
  final Pokemon? pokemon;

  const DetailScreen({super.key, required this.id, this.pokemon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (pokemon == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/unavailable.png', height: 160),
              const SizedBox(height: 16),
              const Text('Pokémon no encontrado'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(pokemon!.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Image.network(
              pokemon!.imagenUrl,
              height: 200,
              width: 200,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/images/error.png',
                height: 200,
                width: 200,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(pokemon!.name, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          TypeChip(type: pokemon!.type),
        ],
      ),
    );
  }
}
