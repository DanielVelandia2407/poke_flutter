import 'pokemon_stat.dart';

class PokemonDetail {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> types;
  final List<String> abilities;
  final List<PokemonStat> stats;
  final int height;
  final int weight;
  final List<({String name, String url})> moves;

  const PokemonDetail({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
    required this.abilities,
    required this.stats,
    required this.height,
    required this.weight,
    required this.moves,
  });

  factory PokemonDetail.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    return PokemonDetail(
      id: (json['id'] as int).toString(),
      name: name[0].toUpperCase() + name.substring(1),
      imageUrl:
          json['sprites']['other']['official-artwork']['front_default']
              as String? ??
          '',
      types: (json['types'] as List)
          .map((item) => item['type']['name'] as String)
          .toList(),
      abilities: (json['abilities'] as List)
          .map((item) => item['ability']['name'] as String)
          .toList(),
      stats: (json['stats'] as List)
          .map((item) => PokemonStat.fromJson(item as Map<String, dynamic>))
          .toList(),
      height: json['height'] as int,
      weight: json['weight'] as int,
      moves: (json['moves'] as List)
          .map(
            (item) => (
              name: item['move']['name'] as String,
              url: item['move']['url'] as String,
            ),
          )
          .toList(),
    );
  }
}
