import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import 'pokemon_detail_page.dart';

const _ink = Color(0xFF20243A);
const _muted = Color(0xFF85899B);
const _page = Color(0xFFF6F5F2);
const _catalogColors = [
  Color(0xFFFF8A73),
  Color(0xFF73C9B2),
  Color(0xFF8D9AF1),
  Color(0xFFFFC86F),
  Color(0xFFBE91DE),
  Color(0xFF67BEE0),
  Color(0xFFF08FA7),
  Color(0xFF91C876),
];

class PokemonCatalogPage extends StatefulWidget {
  const PokemonCatalogPage({super.key});

  @override
  State<PokemonCatalogPage> createState() => _PokemonCatalogPageState();
}

class _PokemonCatalogPageState extends State<PokemonCatalogPage> {
  static const _pageSize = 24;
  static const _generationOffsets = {
    1: 0,
    2: 151,
    3: 251,
    4: 386,
    5: 493,
    6: 649,
    7: 721,
    8: 809,
    9: 905,
  };

  final PokemonService _service = PokemonService();
  final TextEditingController _searchController = TextEditingController();
  final List<PokemonPreview> _pokemon = [];
  int _nextOffset = 0;
  int _selectedGeneration = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _loadMoreError;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog({int generation = 0}) async {
    final offset = _generationOffsets[generation] ?? 0;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedGeneration = generation;
    });
    try {
      final results = await _service.fetchPokemonCatalog(
        offset: offset,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _pokemon
          ..clear()
          ..addAll(results);
        _nextOffset = offset + results.length;
        _isLoading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _networkMessage(error);
        _isLoading = false;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo procesar el catálogo. $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });
    try {
      final results = await _service.fetchPokemonCatalog(
        offset: _nextOffset,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _pokemon.addAll(results);
        _nextOffset += results.length;
        _isLoadingMore = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadMoreError = _networkMessage(error);
        _isLoadingMore = false;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadMoreError = error.message;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadMoreError = 'No se pudieron procesar los resultados. $error';
        _isLoadingMore = false;
      });
    }
  }

  String _networkMessage(DioException error) {
    if (error.type == DioExceptionType.connectionError) {
      return 'No hay conexión a internet. Comprueba tu conexión e inténtalo de nuevo.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'La conexión tardó demasiado. Inténtalo de nuevo.';
    }
    return 'No se pudo cargar el catálogo. ${error.message ?? 'Inténtalo de nuevo.'}';
  }

  List<PokemonPreview> get _visiblePokemon {
    final query = _searchController.text.trim().toLowerCase();
    return _pokemon.where((pokemon) {
      final matchesGeneration =
          _selectedGeneration == 0 || pokemon.generation == _selectedGeneration;
      final matchesSearch =
          query.isEmpty || pokemon.name.toLowerCase().contains(query);
      return matchesGeneration && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 960
        ? 4
        : width >= 650
        ? 3
        : 2;
    final spacing = width < 380 ? 11.0 : 15.0;
    final pokemon = _visiblePokemon;

    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    width < 400 ? 17 : 24,
                    16,
                    width < 400 ? 17 : 24,
                    40,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildTopBar(),
                      const SizedBox(height: 24),
                      const _CatalogHero(),
                      const SizedBox(height: 28),
                      _buildCollectionHeading(),
                      const SizedBox(height: 15),
                      _buildSearchField(),
                      const SizedBox(height: 14),
                      _buildGenerationFilters(),
                      const SizedBox(height: 20),
                      if (_isLoading)
                        const _CatalogLoading()
                      else if (_errorMessage != null)
                        _CatalogError(
                          message: _errorMessage!,
                          onRetry: _loadCatalog,
                        )
                      else if (pokemon.isEmpty)
                        const _EmptySearch()
                      else
                        _buildGrid(pokemon, columns, spacing),
                      if (!_isLoading && _errorMessage == null) ...[
                        const SizedBox(height: 24),
                        if (_loadMoreError != null) ...[
                          Text(
                            _loadMoreError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: _isLoadingMore ? null : _loadMore,
                            icon: _isLoadingMore
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add_rounded, size: 20),
                            label: Text(
                              _isLoadingMore
                                  ? 'Cargando…'
                                  : 'Descubrir más Pokémon',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _ink,
                              side: const BorderSide(color: Color(0xFFE2E1E4)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 15,
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Text(
                            '${_pokemon.length} Pokémon cargados · Datos de PokéAPI',
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE2D9),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.catching_pokemon_rounded,
            color: Color(0xFFE65F4C),
            size: 25,
          ),
        ),
        const SizedBox(width: 11),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'POKÉDEX',
              style: TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            Text(
              'TU COLECCIÓN, TU AVENTURA',
              style: TextStyle(
                color: _muted,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFFFB84D),
                size: 15,
              ),
              SizedBox(width: 5),
              Text(
                'CATÁLOGO',
                style: TextStyle(
                  color: _ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionHeading() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TU COLECCIÓN',
                style: TextStyle(
                  color: Color(0xFFE16F58),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Explora los Pokémon',
                style: TextStyle(
                  color: _ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ),
        if (!_isLoading && _errorMessage == null)
          Text(
            '${_visiblePokemon.length} resultados',
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Busca por nombre…',
        hintStyle: const TextStyle(color: Color(0xFFA1A3AF), fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 21),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFECEBF0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE89B86), width: 1.4),
        ),
      ),
    );
  }

  Widget _buildGenerationFilters() {
    final filters = [
      (0, 'Todos'),
      (1, 'Gen. I'),
      (2, 'Gen. II'),
      (3, 'Gen. III'),
      (4, 'Gen. IV'),
      (5, 'Gen. V'),
      (6, 'Gen. VI'),
      (7, 'Gen. VII'),
      (8, 'Gen. VIII'),
      (9, 'Gen. IX'),
    ];

    return SizedBox(
      height: 37,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedGeneration == filter.$1;
          return ChoiceChip(
            label: Text(filter.$2),
            selected: isSelected,
            onSelected: (_) => _loadCatalog(generation: filter.$1),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : _muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
            backgroundColor: Colors.white,
            selectedColor: _ink,
            side: BorderSide(
              color: isSelected ? _ink : const Color(0xFFECEBF0),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }

  Widget _buildGrid(List<PokemonPreview> pokemon, int columns, double spacing) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;
        final cardHeight = cardWidth * 1.08;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final entry in pokemon)
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _PokemonCatalogCard(
                  pokemon: entry,
                  color: _catalogColors[(entry.id - 1) % _catalogColors.length],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          PokemonDetailPage(initialPokemonId: entry.id),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CatalogHero extends StatelessWidget {
  const _CatalogHero();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      height: width < 400 ? 204 : 224,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8C72), Color(0xFFE85E5D), Color(0xFFD94E69)],
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE66A61).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -66,
            child: Container(
              width: 225,
              height: 225,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.13),
                  width: 22,
                ),
              ),
            ),
          ),
          Positioned(
            right: width < 400 ? 74 : 105,
            bottom: -17,
            height: width < 400 ? 151 : 174,
            width: width < 400 ? 151 : 174,
            child: Opacity(
              opacity: 0.85,
              child: Image.network(
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/6.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned(
            right: -17,
            bottom: 0,
            height: width < 400 ? 130 : 154,
            width: width < 400 ? 130 : 154,
            child: Opacity(
              opacity: 0.68,
              child: Image.network(
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '¡COMIENZA TU AVENTURA!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  '¡Encuentra\na tu equipo!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1.04,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Cada Pokémon tiene una historia.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 15,
            top: 14,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white.withValues(alpha: 0.72),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _PokemonCatalogCard extends StatelessWidget {
  const _PokemonCatalogCard({
    required this.pokemon,
    required this.color,
    required this.onTap,
  });

  final PokemonPreview pokemon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final number = '#${pokemon.id.toString().padLeft(3, '0')}';
    final background = Color.lerp(color, Colors.white, 0.76)!;
    final accent = Color.lerp(color, const Color(0xFF34344A), 0.2)!;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              right: -21,
              top: 25,
              child: Container(
                width: 113,
                height: 113,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 43,
              right: -2,
              width: 116,
              height: 116,
              child: Image.network(
                pokemon.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.catching_pokemon_rounded,
                  color: accent.withValues(alpha: 0.45),
                  size: 75,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 13, 11, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.76),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          number,
                          style: TextStyle(
                            color: accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_outward_rounded,
                        color: accent.withValues(alpha: 0.7),
                        size: 15,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'GENERACIÓN ${_roman(pokemon.generation)}',
                      style: TextStyle(
                        color: accent,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _capitalize(pokemon.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ver ficha Pokémon',
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.83),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogLoading extends StatelessWidget {
  const _CatalogLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 84),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: Color(0xFFE66A61)),
            SizedBox(height: 14),
            Text(
              'Preparando tu Pokédex…',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFE66A61),
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'No se pudo abrir el catálogo',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE66A61),
              ),
              child: const Text('Volver a intentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 55),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, color: Color(0xFFB1B4C0), size: 42),
            SizedBox(height: 10),
            Text(
              'No hay Pokémon con esos filtros',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

String _capitalize(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

String _roman(int generation) =>
    const {
      1: 'I',
      2: 'II',
      3: 'III',
      4: 'IV',
      5: 'V',
      6: 'VI',
      7: 'VII',
      8: 'VIII',
      9: 'IX',
    }[generation] ??
    '$generation';
