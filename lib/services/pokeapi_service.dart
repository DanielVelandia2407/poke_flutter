import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/evolution_stage.dart';
import '../models/move.dart';
import '../models/pokemon_variant.dart';
import '../models/pokemon.dart';
import '../models/pokemon_detail.dart';
import '../models/type_relations.dart';

class PokeApiService {
  static const _baseUrl = 'https://pokeapi.co/api/v2';
  static const _timeout = Duration(seconds: 10);

  Future<List<Pokemon>> fetchPokemons({int offset = 0, int limit = 20}) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/pokemon?offset=$offset&limit=$limit'))
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('Error ${response.statusCode}');
    }
    final results = (jsonDecode(response.body)['results'] as List)
        .cast<Map<String, dynamic>>();
    return Future.wait(
      results.map((result) => _fetchDetail(result['url'] as String)),
    );
  }

  Future<List<({String name, String url})>> fetchIndex() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/pokemon?limit=2000'))
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('Error ${response.statusCode}');
    }
    final results = (jsonDecode(response.body)['results'] as List)
        .cast<Map<String, dynamic>>();
    return results
        .map((r) => (name: r['name'] as String, url: r['url'] as String))
        .toList();
  }

  Future<Pokemon> fetchDetail(String url) => _fetchDetail(url);

  Future<PokemonDetail> fetchPokemonDetail(String id) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/pokemon/$id'))
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('Error ${response.statusCode}');
    }
    return PokemonDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<TypeRelations> fetchTypeRelations(String type) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/type/$type'))
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('Error ${response.statusCode}');
    }
    return TypeRelations.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Move> fetchMove(String url) async {
    final response = await http.get(Uri.parse(url)).timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('Error ${response.statusCode}');
    }
    return Move.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<PokemonVariant>> fetchVariants(String pokemonId) async {
    const base =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork';
    final variants = <PokemonVariant>[
      PokemonVariant(label: 'Normal', imageUrl: '$base/$pokemonId.png'),
      PokemonVariant(label: 'Shiny', imageUrl: '$base/shiny/$pokemonId.png'),
    ];
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/pokemon-species/$pokemonId'))
          .timeout(_timeout);
      if (res.statusCode != 200) return variants;
      for (final v in (jsonDecode(res.body) as Map<String, dynamic>)['varieties']
          as List) {
        if (v['is_default'] as bool) continue;
        final name = v['pokemon']['name'] as String;
        final url = v['pokemon']['url'] as String;
        final id = url.split('/').where((s) => s.isNotEmpty).last;
        variants.add(PokemonVariant(
          label: name
              .split('-')
              .map((w) => w[0].toUpperCase() + w.substring(1))
              .join(' '),
          imageUrl: '$base/$id.png',
        ));
      }
    } catch (_) {}
    return variants;
  }

  Future<List<EvolutionStage>> fetchEvolutionChain(String pokemonId) async {
    final speciesRes = await http
        .get(Uri.parse('$_baseUrl/pokemon-species/$pokemonId'))
        .timeout(_timeout);
    if (speciesRes.statusCode != 200) {
      throw http.ClientException('Error ${speciesRes.statusCode}');
    }
    final chainUrl =
        (jsonDecode(speciesRes.body) as Map<String, dynamic>)['evolution_chain']['url']
            as String;

    final chainRes = await http.get(Uri.parse(chainUrl)).timeout(_timeout);
    if (chainRes.statusCode != 200) {
      throw http.ClientException('Error ${chainRes.statusCode}');
    }
    return _parseChain(
      (jsonDecode(chainRes.body) as Map<String, dynamic>)['chain']
          as Map<String, dynamic>,
    );
  }

  List<EvolutionStage> _parseChain(Map<String, dynamic> chain) {
    final stages = <EvolutionStage>[];
    final url = chain['species']['url'] as String;
    final id = url.split('/').where((s) => s.isNotEmpty).last;
    final rawName = chain['species']['name'] as String;
    final name = rawName
        .split('-')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
    stages.add(EvolutionStage(id: id, name: name));
    for (final next in chain['evolves_to'] as List) {
      stages.addAll(_parseChain(next as Map<String, dynamic>));
    }
    return stages;
  }

  Future<Pokemon> _fetchDetail(String url) async {
    final response = await http.get(Uri.parse(url)).timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('Error ${response.statusCode}');
    }
    return Pokemon.fromApi(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
