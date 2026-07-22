import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TypeChip extends StatelessWidget {
  final String type;

  const TypeChip({super.key, required this.type});

  static const _labels = {
    'normal': 'Normal',
    'fire': 'Fuego',
    'water': 'Agua',
    'grass': 'Planta',
    'electric': 'Eléctrico',
    'ice': 'Hielo',
    'fighting': 'Lucha',
    'poison': 'Veneno',
    'ground': 'Tierra',
    'flying': 'Volador',
    'psychic': 'Psíquico',
    'bug': 'Bicho',
    'rock': 'Roca',
    'ghost': 'Fantasma',
    'dragon': 'Dragón',
    'dark': 'Siniestro',
    'steel': 'Acero',
    'fairy': 'Hada',
  };

  static final _colors = {
    'normal': Colors.grey.shade300,
    'fire': Colors.red.shade300,
    'water': Colors.blue.shade300,
    'grass': Colors.green.shade300,
    'electric': Colors.yellow.shade600,
    'ice': Colors.cyan.shade200,
    'fighting': Colors.deepOrange.shade300,
    'poison': Colors.purple.shade300,
    'ground': Colors.brown.shade300,
    'flying': Colors.indigo.shade200,
    'psychic': Colors.pink.shade300,
    'bug': Colors.lightGreen.shade400,
    'rock': Colors.grey.shade400,
    'ghost': Colors.deepPurple.shade300,
    'dragon': Colors.indigo.shade400,
    'dark': Colors.blueGrey.shade400,
    'steel': Colors.blueGrey.shade200,
    'fairy': Colors.pink.shade200,
  };

  static Color colorOf(String type) =>
      _colors[type.toLowerCase()] ?? _colors['normal']!;

  @override
  Widget build(BuildContext context) {
    final key = _labels.containsKey(type.toLowerCase())
        ? type.toLowerCase()
        : 'normal';
    return Chip(
      avatar: SvgPicture.asset(
        'assets/images/icons/$key.svg',
        width: 18,
        height: 18,
      ),
      label: Text(_labels[key]!),
      backgroundColor: _colors[key],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }
}
