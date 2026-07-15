import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TypeChip extends StatelessWidget {
  final String type;

  const TypeChip({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: SvgPicture.asset(
        'assets/images/icons/${_iconoDelTipo(type)}.svg',
        width: 18,
        height: 18,
      ),
      label: Text(type),
      backgroundColor: _colorDelTipo(type),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }

  static String _iconoDelTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'fuego':
        return 'fire';
      case 'agua':
        return 'water';
      case 'planta':
        return 'grass';
      case 'eléctrico':
      case 'electrico':
        return 'electric';
      default:
        return 'normal';
    }
  }

  static Color _colorDelTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'fuego':
        return Colors.red.shade300;
      case 'agua':
        return Colors.blue.shade300;
      case 'planta':
        return Colors.green.shade300;
      case 'eléctrico':
      case 'electrico':
        return Colors.yellow.shade600;
      default:
        return Colors.grey.shade300;
    }
  }
}
