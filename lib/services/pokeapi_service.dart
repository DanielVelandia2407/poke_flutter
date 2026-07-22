import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/move.dart';
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

  Future<Pokemon> _fetchDetail(String url) async {
    final response = await http.get(Uri.parse(url)).timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('Error ${response.statusCode}');
    }
    return Pokemon.fromApi(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
