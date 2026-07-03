import 'package:flutter/material.dart';

class TypeChip extends StatelessWidget {
  final String type;

  const TypeChip({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(type),
      backgroundColor: _colorDelTipo(type),
      // cambiua el radius
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
    );
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
