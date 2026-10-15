import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon/models/pokemon.dart';

void main() {
  test('construye el modelo y calcula la suma de atributos base', () {
    final pokemon = Pokemon.fromJson({
      'id': 1,
      'name': 'bulbasaur',
      'height': 7,
      'weight': 69,
      'sprites': {
        'front_default': 'https://example.com/front.png',
        'other': {
          'official-artwork': {
            'front_default': 'https://example.com/artwork.png',
          },
        },
      },
      'types': [
        {
          'slot': 1,
          'type': {'name': 'grass'},
        },
        {
          'slot': 2,
          'type': {'name': 'poison'},
        },
      ],
      'abilities': [
        {
          'is_hidden': false,
          'ability': {'name': 'overgrow'},
        },
        {
          'is_hidden': true,
          'ability': {'name': 'chlorophyll'},
        },
      ],
      'stats': [
        {
          'base_stat': 45,
          'stat': {'name': 'hp'},
        },
        {
          'base_stat': 49,
          'stat': {'name': 'attack'},
        },
        {
          'base_stat': 49,
          'stat': {'name': 'defense'},
        },
        {
          'base_stat': 65,
          'stat': {'name': 'special-attack'},
        },
        {
          'base_stat': 65,
          'stat': {'name': 'special-defense'},
        },
        {
          'base_stat': 45,
          'stat': {'name': 'speed'},
        },
      ],
    });

    expect(pokemon.name, 'bulbasaur');
    expect(pokemon.types, ['grass', 'poison']);
    expect(pokemon.imageUrl, 'https://example.com/artwork.png');
    expect(pokemon.height, 7);
    expect(pokemon.weight, 69);
    expect(pokemon.abilities.last.isHidden, isTrue);
    expect(pokemon.totalStats, 318);
    expect(pokemon.strongestStat.name, 'special-attack');
  });

  test('obtiene el número y la generación para las tarjetas del catálogo', () {
    final preview = PokemonPreview.fromJson({
      'name': 'chikorita',
      'url': 'https://pokeapi.co/api/v2/pokemon/152/',
    });

    expect(preview.id, 152);
    expect(preview.generation, 2);
    expect(preview.imageUrl, contains('/152.png'));
  });
}
