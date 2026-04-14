import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/services/premium_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page_model.dart';
export 'home_page_model.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});
  static String routeName = 'HomePage';
  static String routePath = '/homePage';
  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  late HomePageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentUser != null) PremiumService().trackDailyOpen();
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String? _matchWinner(MatchesRecord match) {
    int playerGames = 0;
    int opponentGames = 0;
    for (final pair in [
      [match.g1Player, match.g1Opponent],
      [match.g2Player, match.g2Opponent],
      [match.g3Player, match.g3Opponent],
    ]) {
      final p = pair[0];
      final o = pair[1];
      if ((p >= 21 && (p - o) >= 2) || p >= 30) {
        playerGames++;
      } else if ((o >= 21 && (o - p) >= 2) || o >= 30) {
        opponentGames++;
      }
    }
    if (playerGames >= 2) return 'player';
    if (opponentGames >= 2) return 'opponent';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final primary = FlutterFlowTheme.of(context).primary;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: StreamBuilder<List<TournamentsRecord>>(
        stream: currentUser == null
            ? const Stream.empty()
            : queryTournamentsRecord(
                queryBuilder: (q) => q.where('ownerUid', isEqualTo: currentUserUid),
              ),
        builder: (context, tournamentSnapshot) {
          final tournamentCount = tournamentSnapshot.data?.length ?? 0;
          return StreamBuilder<List<MatchesRecord>>(
            stream: currentUser == null
                ? const Stream.empty()
                : queryMatchesRecord(
                    queryBuilder: (q) => q
                        .where('ownerUid', isEqualTo: currentUserUid)
                        .orderBy('matchDate', descending: true),
                  ),
            builder: (context, snapshot) {
          // Show skeleton while matches load
          if (!snapshot.hasData) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: primary,
                  automaticallyImplyLeading: false,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset('assets/images/badminton_hero.jpg', fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: primary)),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [primary.withOpacity(0.6), primary.withOpacity(0.92)],
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(children: [
                                  const Text('🏸', style: TextStyle(fontSize: 22)),
                                  const SizedBox(width: 8),
                                  Text('MatchPoint Coach',
                                      style: GoogleFonts.interTight(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                ]),
                                const SizedBox(height: 6),
                                Text('Ready for your next match?',
                                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Skeleton insight card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(height: 12, width: 140, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
                                    const SizedBox(height: 8),
                                    Container(height: 10, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primary))),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          final matches = snapshot.data ?? [];
          final last5 = matches.take(5).toList();
          final recentMatches = matches.take(3).toList();
          int totalMatches = matches.length;
          int wins = matches.where((m) => _matchWinner(m) == 'player').length;
          int losses = matches.where((m) => _matchWinner(m) == 'opponent').length;
          int tournamentMatches = matches.where((m) => m.matchType == 'Tournament').length;
          int practiceMatches = matches.where((m) => m.matchType == 'Practice').length;
          final last5Results = last5.map((m) => _matchWinner(m)).toList();
          final winRate = totalMatches > 0 ? ((wins / totalMatches) * 100).round() : 0;

          return CustomScrollView(
            slivers: [
              // ── Hero Header with badminton image ──
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: primary,
                automaticallyImplyLeading: false,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => context.pushNamed(PlayerProfileWidget.routeName),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Badminton hero image
                      Image.asset(
                        'assets/images/badminton_hero.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: primary),
                      ),
                      // Dark gradient overlay so text is readable
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              primary.withOpacity(0.6),
                              primary.withOpacity(0.92),
                            ],
                          ),
                        ),
                      ),
                      // Content
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  const Text('🏸', style: TextStyle(fontSize: 22)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'MatchPoint Coach',
                                    style: GoogleFonts.interTight(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              StreamBuilder<UsersRecord>(
                                stream: currentUserReference != null ? UsersRecord.getDocument(currentUserReference!) : const Stream.empty(),
                                builder: (context, snap) {
                                  final name = snap.data?.playerName ?? '';
                                  return Text(
                                    currentUser != null
                                        ? name.isNotEmpty
                                            ? 'Ready for your next match, $name?'
                                            : 'Ready for your next match?'
                                        : 'Track your badminton journey 🏸',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14),
                                  );
                                },
                              ),
                              if (totalMatches > 0) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _heroBadge('$totalMatches', 'Matches'),
                                    const SizedBox(width: 10),
                                    _heroBadge('$wins', 'Wins'),
                                    const SizedBox(width: 10),
                                    _heroBadge('$winRate%', 'Win Rate'),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Insight Card ──
                      if (totalMatches >= 3) ...[
                        GestureDetector(
                          onTap: () => context.pushNamed(AiCoachWidget.routeName),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.trending_up_rounded,
                                      color: Colors.green.shade700, size: 26),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        winRate >= 60
                                            ? 'Strong form right now'
                                            : winRate >= 40
                                                ? 'Building momentum'
                                                : 'Room to improve',
                                        style: GoogleFonts.inter(
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'You are winning $winRate% of your matches. Open AI Coach to see what is driving your performance.',
                                        style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: 14,
                                            height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right_rounded,
                                    color: Colors.green.shade400, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Navigation Grid ──
                      _sectionHeader('Quick Actions'),
                      const SizedBox(height: 10),

                      // Row 1: New Match full width purple
                      _navCardWide(
                        context,
                        icon: Icons.add_circle_outline,
                        label: 'New Match',
                        subtitle: 'Start tracking your next match',
                        color: primary,
                        textColor: Colors.white,
                        iconColor: Colors.white,
                        iconBg: Colors.white.withOpacity(0.2),
                        onTap: () async {
                          if (currentUser == null) {
                            GoRouter.of(context).prepareAuthEvent();
                            final user = await authManager.signInAnonymously(context);
                            if (user == null) return;
                          }
                          context.pushNamed(AddMatchWidget.routeName);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Row 2: AI Coach full width dark
                      _navCardWide(
                        context,
                        icon: Icons.psychology_rounded,
                        label: 'AI Coach',
                        subtitle: 'Your coaching report is ready',
                        color: const Color(0xFF1A1A2E),
                        textColor: Colors.white,
                        iconColor: Colors.white,
                        iconBg: primary,
                        onTap: () => context.pushNamed(AiCoachWidget.routeName),
                      ),
                      const SizedBox(height: 12),

                      // Row 3: All Matches + Tournaments side by side
                      Row(
                        children: [
                          _navCard(
                            context,
                            icon: Icons.list_alt_rounded,
                            label: 'All Matches',
                            subtitle: '$totalMatches matches recorded',
                            color: FlutterFlowTheme.of(context).secondaryBackground,
                            textColor: primary,
                            iconColor: primary,
                            border: Border.all(color: Colors.grey.shade200),
                            onTap: () async {
                              if (currentUser == null) {
                                GoRouter.of(context).prepareAuthEvent();
                                final user = await authManager.signInAnonymously(context);
                                if (user == null) return;
                              }
                              context.pushNamed(MatchesListWidget.routeName);
                            },
                          ),
                          const SizedBox(width: 12),
                          _navCard(
                            context,
                            icon: Icons.emoji_events_rounded,
                            label: 'Tournaments',
                            subtitle: '$tournamentCount planned',
                            color: Colors.orange.shade50,
                            textColor: Colors.orange.shade800,
                            iconColor: Colors.orange.shade700,
                            border: Border.all(color: Colors.orange.shade200),
                            onTap: () async {
                              if (currentUser == null) {
                                GoRouter.of(context).prepareAuthEvent();
                                final user = await authManager.signInAnonymously(context);
                                if (user == null) return;
                              }
                              context.pushNamed(TournamentCalendarWidget.routeName);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 4: Analytics half width left
                      Row(
                        children: [
                          Expanded(
                            child: _navCard(
                              context,
                              icon: Icons.bar_chart_rounded,
                              label: 'Analytics',
                              subtitle: 'Your insights',
                              color: Colors.purple.shade50,
                              textColor: Colors.purple.shade800,
                              iconColor: Colors.purple.shade700,
                              border: Border.all(color: Colors.purple.shade200),
                              onTap: () async {
                                if (currentUser == null) {
                                  GoRouter.of(context).prepareAuthEvent();
                                  final user = await authManager.signInAnonymously(context);
                                  if (user == null) return;
                                }
                                context.pushNamed(AnalyticsWidget.routeName);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: SizedBox()),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Stats Row ──
                      if (totalMatches > 0) ...[
                        _sectionHeader('Stats'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _statCard(context, '$totalMatches', 'Total', Icons.sports_tennis, Colors.blue),
                            const SizedBox(width: 10),
                            _statCard(context, '$wins', 'Wins', Icons.emoji_events, Colors.green),
                            const SizedBox(width: 10),
                            _statCard(context, '$losses', 'Losses', Icons.close, Colors.red),
                            const SizedBox(width: 10),
                            _statCard(context, '$winRate%', 'Win Rate', Icons.trending_up, Colors.purple),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _statCard(context, '$tournamentMatches', 'Tournament', Icons.military_tech, Colors.orange),
                            const SizedBox(width: 10),
                            _statCard(context, '$practiceMatches', 'Practice', Icons.fitness_center, Colors.teal),
                            const SizedBox(width: 10),
                            const Expanded(child: SizedBox()),
                            const SizedBox(width: 10),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Last 5 Results ──
                      if (last5.isNotEmpty) ...[
                        _sectionHeader('Last 5 Results'),
                        const SizedBox(height: 10),
                        Row(
                          children: List.generate(5, (i) {
                            if (i >= last5Results.length) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade100,
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Center(
                                    child: Text('–',
                                        style: TextStyle(
                                            color: Colors.grey.shade300,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                  ),
                                ),
                              );
                            }
                            final result = last5Results[i];
                            final isWin = result == 'player';
                            final isLoss = result == 'opponent';
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isWin
                                      ? Colors.green.shade500
                                      : isLoss
                                          ? Colors.red.shade400
                                          : Colors.grey.shade300,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isWin
                                              ? Colors.green
                                              : isLoss
                                                  ? Colors.red
                                                  : Colors.grey)
                                          .withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    isWin ? 'W' : isLoss ? 'L' : '–',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Recent Matches ──

                      if (recentMatches.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _sectionHeader('Recent Matches'),
                            GestureDetector(
                              onTap: () => context.pushNamed(MatchesListWidget.routeName),
                              child: Text('See all',
                                  style: TextStyle(
                                      color: primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...recentMatches.map((match) {
                          final winner = _matchWinner(match);
                          final isWin = winner == 'player';
                          final isLoss = winner == 'opponent';
                          return GestureDetector(
                            onTap: () => context.pushNamed(
                              MatchDetailsWidget.routeName,
                              queryParameters: {
                                'matchRef': serializeParam(
                                    match.reference, ParamType.DocumentReference)
                              },
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Row(
                                children: [
                                  // W/L badge
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isWin
                                          ? Colors.green.shade500
                                          : isLoss
                                              ? Colors.red.shade400
                                              : Colors.grey.shade300,
                                    ),
                                    child: Center(
                                      child: Text(
                                        isWin ? 'W' : isLoss ? 'L' : '–',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${match.playerName} vs ${match.opponentName}',
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${match.g1Player}-${match.g1Opponent}  ${match.g2Player}-${match.g2Opponent}${match.g3Player > 0 || match.g3Opponent > 0 ? '  ${match.g3Player}-${match.g3Opponent}' : ''}',
                                          style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: match.matchType == 'Tournament'
                                          ? Colors.orange.shade100
                                          : Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      match.matchType,
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: match.matchType == 'Tournament'
                                              ? Colors.orange.shade800
                                              : Colors.blue.shade800),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ] else ...[
                        // ── Empty State ──
                        const SizedBox(height: 32),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primary.withOpacity(0.08),
                                ),
                                child: Icon(Icons.sports_tennis,
                                    size: 52, color: primary.withOpacity(0.4)),
                              ),
                              const SizedBox(height: 20),
                              Text('No matches yet',
                                  style: GoogleFonts.interTight(
                                      fontSize: 20,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text('Tap "New Match" to start tracking\nyour badminton journey',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade400,
                                      height: 1.5),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => context.pushNamed(AddMatchWidget.routeName),
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: Text('Add First Match',
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
          );
        },
      ),
    );
  }

  // ── Hero stat badge ──
  Widget _heroBadge(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75), fontSize: 11)),
        ],
      ),
    );
  }

  // ── Section header ──
  Widget _sectionHeader(String title) {
    return Text(title,
        style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.grey.shade800));
  }

  // ── Stat card ──
  Widget _statCard(BuildContext context, String value, String label,
      IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Nav card (half width) ──
  Widget _navCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color textColor,
    Color? iconColor,
    BoxBorder? border,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: border,
            boxShadow: [
              BoxShadow(
                  color: color == FlutterFlowTheme.of(context).primary
                      ? color.withOpacity(0.3)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor ?? textColor, size: 26),
              const SizedBox(height: 10),
              Text(label,
                  style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      color: textColor.withOpacity(0.6), fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Nav card (full width) ──
  Widget _navCardWide(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color textColor,
    Color? iconColor,
    Color? iconBg,
    BoxBorder? border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: border,
        ),
        child: Row(
          children: [
            iconBg != null
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor ?? textColor, size: 26),
                  )
                : Icon(icon, color: iconColor ?? textColor, size: 28),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text(subtitle,
                    style: TextStyle(
                        color: textColor.withOpacity(0.6), fontSize: 12)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                color: textColor.withOpacity(0.4), size: 16),
          ],
        ),
      ),
    );
  }
}
