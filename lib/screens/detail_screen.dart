import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/evolution_stage.dart';
import '../models/move.dart';
import '../models/pokemon_detail.dart';
import '../models/pokemon_stat.dart';
import '../models/type_relations.dart';
import '../services/pokeapi_service.dart';
import '../widgets/error_view.dart';
import '../widgets/type_chip.dart';

class DetailScreen extends StatefulWidget {
  final String id;
  final PokeApiService service;

  const DetailScreen({super.key, required this.id, required this.service});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<PokemonDetail> _detailFuture;
  PokemonDetail? _lastDetail;
  List<EvolutionStage>? _chain;
  PageController? _pageController;
  final _currentPage = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _detailFuture = widget.service.fetchPokemonDetail(widget.id);
    _loadChain();
  }

  void _loadChain() {
    widget.service.fetchEvolutionChain(widget.id).then((chain) {
      if (!mounted) return;
      if (chain.length <= 1) {
        setState(() => _chain = chain);
        return;
      }
      final idx = chain.indexWhere((s) => s.id == widget.id);
      final safeIdx = idx < 0 ? 0 : idx;
      final controller = PageController(viewportFraction: 0.72, initialPage: safeIdx);
      setState(() {
        _chain = chain;
        _currentPage.value = safeIdx;
        _pageController = controller;
      });
    }).catchError((_) {});
  }

  void _retry() {
    setState(() {
      _lastDetail = null;
      _detailFuture = widget.service.fetchPokemonDetail(widget.id);
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PokemonDetail>(
      future: _detailFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) _lastDetail = snapshot.data;

        if (_lastDetail == null) {
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(),
              body: ErrorView(error: snapshot.error, onRetry: _retry),
            );
          }
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final detail = _lastDetail!;
        final baseColor = TypeChip.colorOf(detail.types.first);
        final darkColor = Color.lerp(baseColor, Colors.black, 0.45)!;
        final isRefreshing = snapshot.connectionState == ConnectionState.waiting;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(
                detail: detail,
                baseColor: baseColor,
                darkColor: darkColor,
                chain: _chain,
                pageController: _pageController,
                currentPage: _currentPage,
                onPageChanged: _chain == null
                    ? null
                    : (int page) {
                        _currentPage.value = page;
                        setState(() {
                          _detailFuture = widget.service
                              .fetchPokemonDetail(_chain![page].id);
                        });
                      },
              ),
              if (isRefreshing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _InfoRow(detail: detail),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Estadísticas base',
                        child: Column(
                          children: [
                            for (final stat in detail.stats) _StatRow(stat: stat),
                          ],
                        ),
                      ),
                      _SectionCard(
                        title: 'Efectividad de tipos',
                        child: _EffectivenessSection(
                          key: ValueKey('eff-${detail.id}'),
                          types: detail.types,
                          service: widget.service,
                        ),
                      ),
                      _SectionCard(
                        title: 'Movimientos destacados',
                        child: _MovesSection(
                          key: ValueKey('moves-${detail.id}'),
                          moves: detail.moves.take(4).toList(),
                          service: widget.service,
                        ),
                      ),
                      _SectionCard(
                        title: 'Habilidades',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final ability in detail.abilities)
                              _AbilityPill(name: ability, color: baseColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final PokemonDetail detail;
  final Color baseColor;
  final Color darkColor;
  final List<EvolutionStage>? chain;
  final PageController? pageController;
  final ValueNotifier<int> currentPage;
  final void Function(int)? onPageChanged;

  const _Header({
    required this.detail,
    required this.baseColor,
    required this.darkColor,
    required this.chain,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  bool get _hasChain =>
      chain != null && chain!.length > 1 && pageController != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor, darkColor],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: topPadding + 260,
            child: Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: _hasChain ? _buildCarousel(context) : _buildSingleImage(),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                _buildNameSection(theme),
                if (_hasChain) ...[
                  const SizedBox(height: 14),
                  _buildDots(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel(BuildContext context) {
    final chainList = chain!;
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.catching_pokemon,
          size: 240,
          color: Colors.white.withValues(alpha: 0.15),
        ),
        PageView.builder(
          key: const PageStorageKey('evo-carousel'),
          controller: pageController,
          clipBehavior: Clip.none,
          onPageChanged: onPageChanged,
          itemCount: chainList.length,
          itemBuilder: (context, index) {
            final stage = chainList[index];
            return GestureDetector(
              onTap: stage.id == detail.id
                  ? null
                  : () => context.push('/pokemon/${stage.id}'),
              child: AnimatedBuilder(
                animation: pageController!,
                builder: (context, child) {
                  final page = pageController!.hasClients
                      ? (pageController!.page ?? currentPage.value.toDouble())
                      : currentPage.value.toDouble();
                  final diff = (page - index).abs().clamp(0.0, 1.0);
                  return Transform.scale(
                    scale: 1.0 - diff * 0.28,
                    child: Opacity(opacity: 1.0 - diff * 0.55, child: child),
                  );
                },
                child: Image.network(
                  stage.imageUrl,
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      Image.asset('assets/images/error.png', height: 200),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSingleImage() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.catching_pokemon,
          size: 240,
          color: Colors.white.withValues(alpha: 0.15),
        ),
        Image.network(
          detail.imageUrl,
          height: 220,
          errorBuilder: (_, _, _) =>
              Image.asset('assets/images/error.png', height: 200),
        ),
      ],
    );
  }

  Widget _buildNameSection(ThemeData theme) {
    if (!_hasChain) {
      return _buildNameContent(
        theme,
        name: detail.name,
        id: detail.id,
        types: detail.types,
      );
    }
    return ValueListenableBuilder<int>(
      valueListenable: currentPage,
      builder: (context, page, _) {
        final stage = chain![page];
        return _buildNameContent(
          theme,
          name: stage.name,
          id: stage.id,
          types: stage.id == detail.id ? detail.types : null,
        );
      },
    );
  }

  Widget _buildNameContent(
    ThemeData theme, {
    required String name,
    required String id,
    List<String>? types,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              name,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: const [Shadow(blurRadius: 8, color: Colors.black45)],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '#${id.padLeft(3, '0')}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (types != null) ...[
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [for (final t in types) TypeChip(type: t)],
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            'Cargando...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDots() {
    final chainList = chain!;
    return ValueListenableBuilder<int>(
      valueListenable: currentPage,
      builder: (context, current, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < chainList.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: current == i ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: current == i ? 1.0 : 0.4,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final PokemonDetail detail;

  const _InfoRow({required this.detail});

  @override
  Widget build(BuildContext context) {
    final total = detail.stats.fold(0, (sum, stat) => sum + stat.value);
    return Row(
      children: [
        _InfoTile(
          value: '${(detail.height / 10).toStringAsFixed(1)} m',
          label: 'Altura',
        ),
        const SizedBox(width: 12),
        _InfoTile(
          value: '${(detail.weight / 10).toStringAsFixed(1)} kg',
          label: 'Peso',
        ),
        const SizedBox(width: 12),
        _InfoTile(value: '$total', label: 'Total base'),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String value;
  final String label;

  const _InfoTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final PokemonStat stat;

  const _StatRow({required this.stat});

  static const _labels = {
    'hp': 'PS',
    'attack': 'Ataque',
    'defense': 'Defensa',
    'special-attack': 'At. Especial',
    'special-defense': 'Def. Especial',
    'speed': 'Velocidad',
  };

  Color get _color => stat.value < 50
      ? Colors.redAccent
      : stat.value < 90
      ? Colors.amber
      : Colors.green;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(_labels[stat.name] ?? stat.name)),
          SizedBox(
            width: 36,
            child: Text(
              '${stat.value}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: stat.value / 255),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  color: _color,
                  backgroundColor: _color.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EffectivenessSection extends StatefulWidget {
  final List<String> types;
  final PokeApiService service;

  const _EffectivenessSection({
    super.key,
    required this.types,
    required this.service,
  });

  @override
  State<_EffectivenessSection> createState() => _EffectivenessSectionState();
}

class _EffectivenessSectionState extends State<_EffectivenessSection> {
  late Future<List<TypeRelations>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.wait(widget.types.map(widget.service.fetchTypeRelations));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TypeRelations>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Text('No pudimos cargar la efectividad de tipos');
        }

        final relations = snapshot.data!;
        final strong = <String>{
          for (final relation in relations) ...relation.doubleDamageTo,
        }..removeAll(widget.types);

        final defense = <String, double>{};
        for (final relation in relations) {
          for (final type in relation.doubleDamageFrom) {
            defense[type] = (defense[type] ?? 1) * 2;
          }
          for (final type in relation.halfDamageFrom) {
            defense[type] = (defense[type] ?? 1) * 0.5;
          }
          for (final type in relation.noDamageFrom) {
            defense[type] = 0;
          }
        }
        final weak = defense.entries
            .where((entry) => entry.value > 1)
            .map((entry) => entry.key)
            .toList();
        final resist = defense.entries
            .where((entry) => entry.value < 1)
            .map((entry) => entry.key)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeList(label: 'Fuerte contra', types: strong.toList()),
            _TypeList(label: 'Débil contra', types: weak),
            _TypeList(label: 'Resiste', types: resist),
          ],
        );
      },
    );
  }
}

class _TypeList extends StatelessWidget {
  final String label;
  final List<String> types;

  const _TypeList({required this.label, required this.types});

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final type in types) TypeChip(type: type)],
          ),
        ],
      ),
    );
  }
}

class _MovesSection extends StatefulWidget {
  final List<({String name, String url})> moves;
  final PokeApiService service;

  const _MovesSection({
    super.key,
    required this.moves,
    required this.service,
  });

  @override
  State<_MovesSection> createState() => _MovesSectionState();
}

class _MovesSectionState extends State<_MovesSection> {
  late Future<List<Move>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.wait(
      widget.moves.map((move) => widget.service.fetchMove(move.url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Move>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Text('No pudimos cargar los movimientos');
        }

        return Column(
          children: [
            for (final move in snapshot.data!) _MoveTile(move: move),
          ],
        );
      },
    );
  }
}

class _MoveTile extends StatelessWidget {
  final Move move;

  const _MoveTile({required this.move});

  static const _damageIcons = {
    'physical': Icons.sports_mma,
    'special': Icons.auto_awesome,
    'status': Icons.shield_outlined,
  };

  static const _damageLabels = {
    'physical': 'Físico',
    'special': 'Especial',
    'status': 'Estado',
  };

  String get _displayName => move.name
      .split('-')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = TypeChip.colorOf(move.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(_damageIcons[move.damageClass] ?? Icons.bolt, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_damageLabels[move.damageClass] ?? move.damageClass}'
                  ' · PP ${move.pp}'
                  '${move.accuracy != null ? ' · Precisión ${move.accuracy}%' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: (move.power ?? 0) / 150),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                move.power != null ? '${move.power}' : '—',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text('Poder', style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _AbilityPill extends StatelessWidget {
  final String name;
  final Color color;

  const _AbilityPill({required this.name, required this.color});

  String get _displayName => name
      .split('-')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        _displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
