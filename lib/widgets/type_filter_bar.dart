import 'package:flutter/material.dart';
import 'type_chip.dart';

class TypeFilterBar extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const TypeFilterBar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: TypeChip.allTypes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final type = TypeChip.allTypes[index];
          final isSelected = type == selected;
          final color = TypeChip.colorOf(type);
          final textColor = color.computeLuminance() > 0.4
              ? Colors.black87
              : Colors.white;
          return ChoiceChip(
            label: Text(TypeChip.labelOf(type)),
            selected: isSelected,
            onSelected: (_) => onSelect(type),
            selectedColor: color,
            backgroundColor: color.withValues(alpha: 0.25),
            labelStyle: TextStyle(
              color: isSelected ? textColor : null,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide.none,
            shape: const StadiumBorder(),
          );
        },
      ),
    );
  }
}
