import 'package:dio/dio.dart';
import 'package:poke_app/models/pokemon.dart';

class PokemonService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://pokeapi.co/api/v2',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<List<Pokemon>> fetchPokemons({int offset = 0, int limit = 20}) async {
    final response = await _dio.get(
      '/pokemon',
      queryParameters: {'limit': limit, 'offset': offset},
    );

    final List results = response.data['results'] as List;
    return results.map((item) {
      // url: https://pokeapi.co/api/v2/pokemon/25/ → id = '25'
      final segments = Uri.parse(item['url'] as String).pathSegments;
      final id = segments[segments.length - 2];
      final name = item['name'] as String;

      return Pokemon(
        id: id,
        name: name[0].toUpperCase() + name.substring(1),
        type: '', // the list endpoint has no types — they arrive in Session 8
        imagenUrl:
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png',
      );
    }).toList();
  }
}
