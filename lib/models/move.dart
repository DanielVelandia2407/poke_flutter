class Move {
  final String name;
  final String type;
  final int? power;
  final int? accuracy;
  final int pp;
  final String damageClass;

  const Move({
    required this.name,
    required this.type,
    required this.power,
    required this.accuracy,
    required this.pp,
    required this.damageClass,
  });

  factory Move.fromJson(Map<String, dynamic> json) {
    return Move(
      name: json['name'] as String,
      type: json['type']['name'] as String,
      power: json['power'] as int?,
      accuracy: json['accuracy'] as int?,
      pp: json['pp'] as int? ?? 0,
      damageClass: json['damage_class']['name'] as String,
    );
  }
}
