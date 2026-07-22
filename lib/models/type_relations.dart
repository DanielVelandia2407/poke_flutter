class TypeRelations {
  final List<String> doubleDamageTo;
  final List<String> doubleDamageFrom;
  final List<String> halfDamageFrom;
  final List<String> noDamageFrom;

  const TypeRelations({
    required this.doubleDamageTo,
    required this.doubleDamageFrom,
    required this.halfDamageFrom,
    required this.noDamageFrom,
  });

  factory TypeRelations.fromJson(Map<String, dynamic> json) {
    final relations = json['damage_relations'] as Map<String, dynamic>;
    List<String> names(String key) => (relations[key] as List)
        .map((item) => item['name'] as String)
        .toList();
    return TypeRelations(
      doubleDamageTo: names('double_damage_to'),
      doubleDamageFrom: names('double_damage_from'),
      halfDamageFrom: names('half_damage_from'),
      noDamageFrom: names('no_damage_from'),
    );
  }
}
