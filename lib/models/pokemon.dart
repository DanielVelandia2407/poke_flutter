class Pokemon {
  final String id;
  final String name;
  final String type;
  final String imagenUrl;

  const Pokemon({
    required this.id,
    required this.name,
    required this.type,
    required this.imagenUrl,
  });

  factory Pokemon.fromApi(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final types = json['types'] as List;
    final artwork =
        json['sprites']['other']['official-artwork']['front_default']
            as String?;
    return Pokemon(
      id: (json['id'] as int).toString(),
      name: name[0].toUpperCase() + name.substring(1),
      type: types.first['type']['name'] as String,
      imagenUrl: artwork ?? '',
    );
  }
}
