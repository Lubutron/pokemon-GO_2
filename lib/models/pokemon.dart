class Pokemon {
  const Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.imageUrl,
    required this.types,
    required this.abilities,
    required this.stats,
  });

  final int id;
  final String name;
  final int height;
  final int weight;
  final String? imageUrl;
  final List<String> types;
  final List<PokemonAbility> abilities;
  final List<PokemonStat> stats;

  int get totalStats => stats.fold(0, (total, stat) => total + stat.value);

  PokemonStat get strongestStat =>
      stats.reduce((strongest, stat) => stat.value > strongest.value ? stat : strongest);

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final sprites = json['sprites'] as Map<String, dynamic>;
    final otherSprites = sprites['other'] as Map<String, dynamic>?;
    final officialArtwork =
        otherSprites?['official-artwork'] as Map<String, dynamic>?;
    final artworkUrl = officialArtwork?['front_default'] as String?;

    return Pokemon(
      id: json['id'] as int,
      name: json['name'] as String,
      height: json['height'] as int,
      weight: json['weight'] as int,
      imageUrl: artworkUrl ?? sprites['front_default'] as String?,
      types: (json['types'] as List<dynamic>)
          .map((entry) {
            final type = (entry as Map<String, dynamic>)['type']
                as Map<String, dynamic>;
            return type['name'] as String;
          })
          .toList(),
      abilities: (json['abilities'] as List<dynamic>)
          .map((entry) {
            final abilityEntry = entry as Map<String, dynamic>;
            final ability = abilityEntry['ability'] as Map<String, dynamic>;
            return PokemonAbility(
              name: ability['name'] as String,
              isHidden: abilityEntry['is_hidden'] as bool,
            );
          })
          .toList(),
      stats: (json['stats'] as List<dynamic>)
          .map((entry) {
            final statEntry = entry as Map<String, dynamic>;
            final stat = statEntry['stat'] as Map<String, dynamic>;
            return PokemonStat(
              name: stat['name'] as String,
              value: statEntry['base_stat'] as int,
            );
          })
          .toList(),
    );
  }
}

class PokemonAbility {
  const PokemonAbility({required this.name, required this.isHidden});

  final String name;
  final bool isHidden;
}

class PokemonStat {
  const PokemonStat({required this.name, required this.value});

  final String name;
  final int value;
}

class PokemonPreview {
  const PokemonPreview({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  int get generation {
    if (id <= 151) return 1;
    if (id <= 251) return 2;
    if (id <= 386) return 3;
    if (id <= 493) return 4;
    if (id <= 649) return 5;
    if (id <= 721) return 6;
    if (id <= 809) return 7;
    if (id <= 905) return 8;
    return 9;
  }

  factory PokemonPreview.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String;
    final id = int.parse(
      Uri.parse(url).pathSegments.where((segment) => segment.isNotEmpty).last,
    );
    return PokemonPreview(id: id, name: json['name'] as String);
  }
}
