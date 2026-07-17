import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

class PokeApiService {
  static const _baseUrl = 'https://pokeapi.co/api/v2';

  Future<List<Pokemon>> fetchPokemons({int limit = 30}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/pokemon?limit=$limit'),
    );
    if (response.statusCode != 200) {
      throw http.ClientException('Error ${response.statusCode}');
    }
    final results = (jsonDecode(response.body)['results'] as List)
        .cast<Map<String, dynamic>>();
    return Future.wait(
      results.map((result) => _fetchDetail(result['url'] as String)),
    );
  }

  Future<Pokemon> _fetchDetail(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw http.ClientException('Error ${response.statusCode}');
    }
    return Pokemon.fromApi(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
