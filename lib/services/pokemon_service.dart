import 'package:dio/dio.dart';

import '../models/pokemon.dart';

class PokemonService {
  PokemonService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://pokeapi.co/api/v2',
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
              headers: const {'Accept': 'application/json'},
            ),
          );

  final Dio _dio;

  Future<Pokemon> fetchPokemon(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/pokemon/$id/');
    final data = response.data;
    if (data == null) {
      throw const FormatException('La API devolvió una respuesta vacía.');
    }
    return Pokemon.fromJson(data);
  }

  Future<List<PokemonPreview>> fetchPokemonCatalog({
    required int offset,
    int limit = 24,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/pokemon/',
      queryParameters: {'offset': offset, 'limit': limit},
    );
    final data = response.data;
    if (data == null || data['results'] is! List<dynamic>) {
      throw const FormatException('La API devolvió un catálogo no válido.');
    }
    return (data['results'] as List<dynamic>)
        .map((entry) => PokemonPreview.fromJson(entry as Map<String, dynamic>))
        .toList();
  }
}
