class EvolutionStage {
  final String id;
  final String name;

  const EvolutionStage({required this.id, required this.name});

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  String get shinyImageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/shiny/$id.png';
}
