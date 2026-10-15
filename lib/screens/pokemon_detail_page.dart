import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../services/pokemon_service.dart';

const _ink = Color(0xFF20243A);
const _muted = Color(0xFF85899B);
const _red = Color(0xFFEF5B55);

class PokemonDetailPage extends StatefulWidget {
  const PokemonDetailPage({super.key, this.initialPokemonId = 1});

  final int initialPokemonId;

  @override
  State<PokemonDetailPage> createState() => _PokemonDetailPageState();
}

class _PokemonDetailPageState extends State<PokemonDetailPage> {
  final PokemonService _pokemonService = PokemonService();
  Pokemon? _pokemon;
  bool _isLoading = true;
  String? _errorMessage;
  late int _pokemonId;

  @override
  void initState() {
    super.initState();
    _pokemonId = widget.initialPokemonId;
    _loadPokemon(_pokemonId);
  }

  Future<void> _loadPokemon(int id) async {
    setState(() {
      _pokemonId = id;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pokemon = await _pokemonService.fetchPokemon(id);
      if (!mounted) return;
      setState(() {
        _pokemon = pokemon;
        _isLoading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _dioErrorMessage(error);
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
        _errorMessage = 'No se pudo cargar el Pokémon. $error';
        _isLoading = false;
      });
    }
  }

  String _dioErrorMessage(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'La conexión tardó demasiado. Comprueba tu internet e inténtalo otra vez.';
    }
    if (error.response?.statusCode == 404) {
      return 'No encontramos el Pokémon #$_pokemonId.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'No hay conexión a internet. Conéctate e inténtalo de nuevo.';
    }
    return 'La Pokédex no pudo responder. ${error.message ?? 'Inténtalo de nuevo.'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _BattleBackdrop(pokemonId: _pokemonId)),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildHeader(),
                          const SizedBox(height: 22),
                          if (_isLoading)
                            const _LoadingView()
                          else if (_errorMessage != null)
                            _ErrorView(
                              message: _errorMessage!,
                              onRetry: () => _loadPokemon(_pokemonId),
                            )
                          else if (_pokemon != null) ...[
                            _PokemonHero(
                              pokemon: _pokemon!,
                              onPrevious: _pokemonId > 1
                                  ? () => _loadPokemon(_pokemonId - 1)
                                  : null,
                              onNext: () => _loadPokemon(_pokemonId + 1),
                            ),
                            const SizedBox(height: 20),
                            _PowerCard(pokemon: _pokemon!),
                            const SizedBox(height: 20),
                            _StatsCard(pokemon: _pokemon!),
                            const SizedBox(height: 20),
                            _DetailsCard(pokemon: _pokemon!),
                            const SizedBox(height: 22),
                            const Center(
                              child: Text(
                                'Datos proporcionados por PokéAPI',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 12,
                                  letterSpacing: 0.2,
                                ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.catching_pokemon_rounded, color: _red),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'POKÉDEX',
              style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.4,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Explora. Aprende. ¡Atrápalos!',
              style: TextStyle(color: _muted, fontSize: 11.5),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, color: Color(0xFF56C596), size: 8),
              SizedBox(width: 6),
              Text(
                'EN VIVO',
                style: TextStyle(
                  color: _ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BattleBackdrop extends StatelessWidget {
  const _BattleBackdrop({required this.pokemonId});

  final int pokemonId;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final imageSize = (width * 0.48).clamp(145.0, 230.0);

    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF1F3FA), Color(0xFFF8F8FC)],
                ),
              ),
            ),
            CustomPaint(painter: _BattleEnergyPainter()),
            Positioned(
              left: -imageSize * 0.38,
              top: 110,
              width: imageSize,
              height: imageSize,
              child: Opacity(
                opacity: 0.28,
                child: Image.network(
                  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokemonId.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
            Positioned(
              right: -imageSize * 0.38,
              top: 210,
              width: imageSize,
              height: imageSize,
              child: Opacity(
                opacity: 0.24,
                child: Transform.flip(
                  flipX: true,
                  child: Image.network(
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/6.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleEnergyPainter extends CustomPainter {
  const _BattleEnergyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.27);
    final radius = size.width * 0.43;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF9098C9).withValues(alpha: 0.09);
    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius * 0.77, ringPaint);

    final energyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final clash = Offset(size.width * 0.5, size.height * 0.25);
    energyPaint
      ..strokeWidth = 4
      ..color = const Color(0xFFEF8B72).withValues(alpha: 0.17);
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.19),
      clash,
      energyPaint,
    );
    energyPaint
      ..strokeWidth = 3
      ..color = const Color(0xFF7785D8).withValues(alpha: 0.18);
    canvas.drawLine(
      Offset(size.width * 0.88, size.height * 0.31),
      clash,
      energyPaint,
    );

    final sparkPaint = Paint()
      ..color = const Color(0xFFE7AD55).withValues(alpha: 0.25)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final offset in const [
      Offset(-12, -12),
      Offset(12, -12),
      Offset(-12, 12),
      Offset(12, 12),
    ]) {
      canvas.drawLine(clash + offset * 0.4, clash + offset * 1.5, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BattleEnergyPainter oldDelegate) => false;
}

class _PokemonHero extends StatelessWidget {
  const _PokemonHero({
    required this.pokemon,
    required this.onPrevious,
    required this.onNext,
  });

  final Pokemon pokemon;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(pokemon.types.first);
    final name = _capitalize(pokemon.name);

    return Container(
      height: 284,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, const Color(0xFF292943), 0.38)!],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -50,
            child: Container(
              width: 245,
              height: 245,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 26,
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -52,
            child: Icon(
              Icons.catching_pokemon_rounded,
              size: 170,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(23, 21, 23, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'FICHA DEL POKÉMON',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '#${pokemon.id.toString().padLeft(3, '0')}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: pokemon.types
                      .map((type) => _TypeChip(type: type))
                      .toList(),
                ),
                const Spacer(),
                Row(
                  children: [
                    _NavigationButton(
                      icon: Icons.chevron_left_rounded,
                      onPressed: onPrevious,
                    ),
                    const SizedBox(width: 7),
                    _NavigationButton(
                      icon: Icons.chevron_right_rounded,
                      onPressed: onNext,
                    ),
                    const Spacer(),
                    Text(
                      'N.º ${pokemon.id} EN LA POKÉDEX',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 7,
            top: 41,
            bottom: 14,
            width: 178,
            child: pokemon.imageUrl == null
                ? const Icon(
                    Icons.catching_pokemon_rounded,
                    color: Colors.white54,
                    size: 120,
                  )
                : Image.network(
                    pokemon.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.catching_pokemon_rounded,
                      color: Colors.white54,
                      size: 120,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 32,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.18),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white30,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.19),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        _typeName(type).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _PowerCard extends StatelessWidget {
  const _PowerCard({required this.pokemon});

  final Pokemon pokemon;

  @override
  Widget build(BuildContext context) {
    final total = pokemon.totalStats;
    final level = _strengthLevel(total);
    final strongest = pokemon.strongestStat;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            eyebrow: 'RESUMEN DE COMBATE',
            title: 'Nivel de fuerza',
            icon: Icons.bolt_rounded,
            iconColor: Color(0xFFF2A93B),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                level,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const Spacer(),
              Text(
                '$total',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 5),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(
                  'PTS',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: (total / 600).clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: const Color(0xFFF0F1F6),
              valueColor: const AlwaysStoppedAnimation<Color>(_red),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              const Icon(Icons.insights_rounded, size: 15, color: _muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Su atributo más fuerte es ${_statName(strongest.name)} (${strongest.value}).',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.pokemon});

  final Pokemon pokemon;

  @override
  Widget build(BuildContext context) {
    final groupedStats = <String, List<PokemonStat>>{
      'VITALIDAD': pokemon.stats.where((stat) => stat.name == 'hp').toList(),
      'ATAQUE': pokemon.stats
          .where(
            (stat) => stat.name == 'attack' || stat.name == 'special-attack',
          )
          .toList(),
      'DEFENSA': pokemon.stats
          .where(
            (stat) => stat.name == 'defense' || stat.name == 'special-defense',
          )
          .toList(),
      'VELOCIDAD': pokemon.stats.where((stat) => stat.name == 'speed').toList(),
    };

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            eyebrow: 'ANÁLISIS DE ATRIBUTOS',
            title: 'Estadísticas base',
            icon: Icons.equalizer_rounded,
            iconColor: Color(0xFF6875E8),
          ),
          const SizedBox(height: 19),
          for (final group in groupedStats.entries)
            if (group.value.isNotEmpty) ...[
              _StatGroupLabel(label: group.key),
              const SizedBox(height: 9),
              for (final stat in group.value) ...[
                _StatRow(stat: stat),
                const SizedBox(height: 11),
              ],
              const SizedBox(height: 4),
            ],
        ],
      ),
    );
  }
}

class _StatGroupLabel extends StatelessWidget {
  const _StatGroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Text(
        label,
        style: const TextStyle(
          color: _muted,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat});

  final PokemonStat stat;

  @override
  Widget build(BuildContext context) {
    final color = _statColor(stat.name);
    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            _statName(stat.name),
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 31,
          child: Text(
            '${stat.value}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (stat.value / 255).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: const Color(0xFFF0F1F6),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.pokemon});

  final Pokemon pokemon;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            eyebrow: 'MÁS INFORMACIÓN',
            title: 'Ficha técnica',
            icon: Icons.menu_book_rounded,
            iconColor: Color(0xFF56A7D8),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MeasureTile(
                  icon: Icons.height_rounded,
                  label: 'ALTURA',
                  value: '${(pokemon.height / 10).toStringAsFixed(1)} m',
                  color: const Color(0xFF6875E8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MeasureTile(
                  icon: Icons.fitness_center_rounded,
                  label: 'PESO',
                  value: '${(pokemon.weight / 10).toStringAsFixed(1)} kg',
                  color: const Color(0xFFEF9B50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          const Text(
            'HABILIDADES',
            style: TextStyle(
              color: _muted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pokemon.abilities.map((ability) {
              final label = ability.name.split('-').map(_capitalize).join(' ');
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (ability.isHidden) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.visibility_off_outlined,
                        size: 12,
                        color: _muted,
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        'oculta',
                        style: TextStyle(color: _muted, fontSize: 9),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MeasureTile extends StatelessWidget {
  const _MeasureTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.045),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  final String eyebrow;
  final String title;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                color: _muted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 360,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _red),
            SizedBox(height: 16),
            Text(
              'Buscando datos en la Pokédex…',
              style: TextStyle(
                color: _muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: _red, size: 42),
          const SizedBox(height: 13),
          const Text(
            'No pudimos cargar los datos',
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Intentar de nuevo'),
            style: FilledButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

String _capitalize(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

String _typeName(String type) =>
    const {
      'bug': 'Bicho',
      'dark': 'Siniestro',
      'dragon': 'Dragón',
      'electric': 'Eléctrico',
      'fairy': 'Hada',
      'fighting': 'Lucha',
      'fire': 'Fuego',
      'flying': 'Volador',
      'ghost': 'Fantasma',
      'grass': 'Planta',
      'ground': 'Tierra',
      'ice': 'Hielo',
      'normal': 'Normal',
      'poison': 'Veneno',
      'psychic': 'Psíquico',
      'rock': 'Roca',
      'steel': 'Acero',
      'water': 'Agua',
    }[type] ??
    _capitalize(type);

Color _typeColor(String type) =>
    const {
      'bug': Color(0xFF86A83F),
      'dark': Color(0xFF65546B),
      'dragon': Color(0xFF6B5AC8),
      'electric': Color(0xFFE6B438),
      'fairy': Color(0xFFE78BA9),
      'fighting': Color(0xFFD66A5E),
      'fire': Color(0xFFEE8057),
      'flying': Color(0xFF7D9DD3),
      'ghost': Color(0xFF76679E),
      'grass': Color(0xFF66AD7C),
      'ground': Color(0xFFB99561),
      'ice': Color(0xFF6BBFC1),
      'normal': Color(0xFF9B9DA7),
      'poison': Color(0xFFAC70B7),
      'psychic': Color(0xFFE17689),
      'rock': Color(0xFFA78B61),
      'steel': Color(0xFF8295A8),
      'water': Color(0xFF5B98D2),
    }[type] ??
    _red;

Color _statColor(String stat) =>
    const {
      'hp': Color(0xFFEF7373),
      'attack': Color(0xFFEF9B50),
      'special-attack': Color(0xFFE5B547),
      'defense': Color(0xFF5CAED1),
      'special-defense': Color(0xFF62B99A),
      'speed': Color(0xFF8D79D4),
    }[stat] ??
    _red;

String _statName(String stat) =>
    const {
      'hp': 'PS',
      'attack': 'Ataque',
      'defense': 'Defensa',
      'special-attack': 'At. especial',
      'special-defense': 'Def. especial',
      'speed': 'Velocidad',
    }[stat] ??
    _capitalize(stat);

String _strengthLevel(int total) {
  if (total < 250) return 'En desarrollo';
  if (total < 350) return 'Equilibrado';
  if (total < 450) return 'Poderoso';
  if (total < 550) return 'Élite';
  return 'Legendario';
}
