import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/club_service.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/users_record.dart';

class CoachDashboardPage extends StatefulWidget {
  const CoachDashboardPage({super.key});
  static String routeName = 'CoachDashboardPage';
  static String routePath = '/coachDashboard';

  @override
  State<CoachDashboardPage> createState() => _CoachDashboardPageState();
}

class _CoachDashboardPageState extends State<CoachDashboardPage> {
  final _clubService = ClubService();
  final _db = FirebaseFirestore.instance;
  final _searchController = TextEditingController();

  Map<String, dynamic>? _club;
  List<Map<String, dynamic>> _players = [];
  List<Map<String, dynamic>> _filteredPlayers = [];
  bool _loading = true;
  bool _dashboardLoaded = false;
  String _filterTab = 'All';
  String _searchQuery = '';

  final List<String> _tabs = ['All', 'Under 15', 'Senior', 'Alerts'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard(String clubId) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final clubDoc = await _db.collection('clubs').doc(clubId).get();
      if (!clubDoc.exists) { if (mounted) setState(() { _loading = false; }); return; }
      final club = {'clubId': clubDoc.id, ...clubDoc.data()!};
      final players = await _clubService.getClubPlayers(club['clubId']);
      final enriched = await Future.wait(players.map((p) => _enrichPlayer(p)));
      enriched.sort((a, b) {
        final aWatch = a['watchListed'] == true ? 0 : 1;
        final bWatch = b['watchListed'] == true ? 0 : 1;
        return aWatch.compareTo(bWatch);
      });
      if (mounted) setState(() { _club = club; _players = enriched; _loading = false; _applyFilters(); });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>> _enrichPlayer(Map<String, dynamic> player) async {
    final uid = player['uid'] as String;
    final matchesQuery = await _db.collection('matches').where('ownerUid', isEqualTo: uid).orderBy('matchDate', descending: true).get();
    final matches = matchesQuery.docs.map((d) => d.data()).toList();
    final total = matches.length;
    int wins = 0;
    DateTime? lastMatchDate;
    final List<bool> last5 = [];
    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      final isWin = _isWin(m);
      if (isWin) wins++;
      if (i < 5) last5.add(isWin);
      final ts = m['matchDate'];
      if (ts != null && i == 0) {
        lastMatchDate = (ts is Timestamp) ? ts.toDate() : null;
      }
    }
    final winRate = total > 0 ? (wins / total * 100).round() : 0;
    final daysSinceLast = lastMatchDate != null ? DateTime.now().difference(lastMatchDate).inDays : 999;
    String trafficLight;
    if (daysSinceLast <= 7) trafficLight = 'green';
    else if (daysSinceLast <= 13) trafficLight = 'amber';
    else trafficLight = 'red';
    return {
      ...player,
      'totalMatches': total,
      'winRate': winRate,
      'last5': last5,
      'lastMatchDate': lastMatchDate,
      'daysSinceLast': daysSinceLast,
      'trafficLight': trafficLight,
    };
  }

  bool _isWin(Map<String, dynamic> m) {
    int playerGames = 0, opponentGames = 0;
    void checkGame(String p, String o) {
      final pScore = (m[p] as num?)?.toInt() ?? 0;
      final oScore = (m[o] as num?)?.toInt() ?? 0;
      if (pScore > 0 || oScore > 0) { if (pScore > oScore) playerGames++; else opponentGames++; }
    }
    checkGame('g1Player', 'g1Opponent');
    checkGame('g2Player', 'g2Opponent');
    checkGame('g3Player', 'g3Opponent');
    return playerGames > opponentGames;
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(_players);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) {
        final name = (p['display_name'] ?? p['displayName'] ?? '').toString().toLowerCase();
        return name.contains(q);
      }).toList();
    }
    if (_filterTab == 'Under 15') {
      result = result.where((p) => (p['ageGroup'] ?? '').toString().toLowerCase().contains('under') || (p['ageGroup'] ?? '').toString().contains('15')).toList();
    } else if (_filterTab == 'Senior') {
      result = result.where((p) => (p['ageGroup'] ?? '').toString().toLowerCase().contains('senior')).toList();
    } else if (_filterTab == 'Alerts') {
      result = result.where((p) => p['trafficLight'] == 'red').toList();
    }
    setState(() => _filteredPlayers = result);
  }

  int get _alertCount => _players.where((p) => p['trafficLight'] == 'red').length;
  int get _needAttentionCount => _alertCount;

  Color _trafficColor(String light) {
    if (light == 'green') return const Color(0xFF22C55E);
    if (light == 'amber') return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _lastActiveText(int days) {
    if (days == 999) return 'No matches yet';
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '$days days ago';
  }

  String _initials(Map<String, dynamic> p) {
    final name = (p['display_name'] ?? p['displayName'] ?? '?').toString().trim();
    final parts = name.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  Future<void> _toggleWatchlist(Map<String, dynamic> player) async {
    final uid = player['uid'] as String;
    final current = player['watchListed'] == true;
    await _db.collection('users').doc(uid).update({'watchListed': !current});
    final clubId = _club?['clubId'] as String?;
    if (clubId != null) await _loadDashboard(clubId);
  }

  @override
  Widget build(BuildContext context) {
    final primary = FlutterFlowTheme.of(context).primary;
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(_club?['clubName'] ?? 'Coach Dashboard',
            style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
      ),
      body: StreamBuilder<UsersRecord?>(
        stream: authenticatedUserStream,
        builder: (context, snapshot) {
          final userRecord = snapshot.data;
          final clubId = userRecord?.clubId ?? '';
          if (clubId.isNotEmpty && !_dashboardLoaded) {
            _dashboardLoaded = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard(clubId));
          }
          if (_loading) return const Center(child: CircularProgressIndicator());
          if (_club == null) return Center(child: Text('No players yet. Share your club code to get started.', style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center));
          return RefreshIndicator(
            onRefresh: () => _loadDashboard(_club!['clubId']),
            child: Column(
              children: [
                _buildSummaryBar(primary),
                _buildSearchBar(),
                _buildFilterTabs(primary),
                Expanded(child: _buildPlayerList(primary)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryBar(Color primary) {
    final active = _players.where((p) => p['trafficLight'] == 'green').length;
    final atRisk = _players.where((p) => p['trafficLight'] == 'amber').length;
    return Container(
      color: primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _summaryChip('${_players.length}', 'Players', Colors.white.withOpacity(0.2), Colors.white),
          const SizedBox(width: 8),
          _summaryChip('$active', 'Active', Colors.green.withOpacity(0.3), const Color(0xFF86EFAC)),
          const SizedBox(width: 8),
          _summaryChip('$atRisk', 'At risk', Colors.orange.withOpacity(0.3), const Color(0xFFFDE68A)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () { setState(() { _filterTab = 'Alerts'; _applyFilters(); }); },
            child: _summaryChip('$_needAttentionCount', 'Need attention', Colors.red.withOpacity(0.3), const Color(0xFFFCA5A5)),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String count, String label, Color bg, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(count, style: GoogleFonts.interTight(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            Text(label, style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.85)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (v) { setState(() => _searchQuery = v); _applyFilters(); },
        decoration: InputDecoration(
          hintText: 'Search players...',
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary, width: 2)),
          filled: true,
          fillColor: FlutterFlowTheme.of(context).secondaryBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = _filterTab == tab;
          final isAlert = tab == 'Alerts';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () { setState(() { _filterTab = tab; _applyFilters(); }); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? primary : FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? primary : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Text(tab, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.grey.shade600)),
                    if (isAlert && _alertCount > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.red, borderRadius: BorderRadius.circular(10)),
                        child: Text('$_alertCount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.red : Colors.white)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlayerList(Color primary) {
    if (_filteredPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(_players.isEmpty ? 'No players have joined yet.' : 'No players match this filter.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
            if (_players.isEmpty) ...[
              const SizedBox(height: 8),
              Text('Share your player code to get started.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            ],
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _filteredPlayers.length,
      itemBuilder: (context, i) => _buildPlayerCard(_filteredPlayers[i], primary),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player, Color primary) {
    final name = (player['display_name'] ?? player['displayName'] ?? 'Unknown').toString();
    final ageGroup = (player['ageGroup'] ?? '').toString();
    final totalMatches = player['totalMatches'] as int;
    final winRate = player['winRate'] as int;
    final last5 = player['last5'] as List<bool>;
    final trafficLight = player['trafficLight'] as String;
    final daysSinceLast = player['daysSinceLast'] as int;
    final isWatched = player['watchListed'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isWatched ? primary.withOpacity(0.3) : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: primary.withOpacity(0.12), shape: BoxShape.circle),
                  child: Center(child: Text(_initials(player), style: GoogleFonts.interTight(fontSize: 16, fontWeight: FontWeight.bold, color: primary))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(name, style: GoogleFonts.interTight(fontSize: 15, fontWeight: FontWeight.bold, color: FlutterFlowTheme.of(context).primaryText))),
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(color: _trafficColor(trafficLight), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _toggleWatchlist(player),
                            child: Icon(isWatched ? Icons.star : Icons.star_border, color: isWatched ? Colors.amber : Colors.grey.shade400, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (ageGroup.isNotEmpty) Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(ageGroup, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primary)),
                          ),
                          if (ageGroup.isNotEmpty) const SizedBox(width: 8),
                          Text('$totalMatches matches', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Form. ', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ...last5.map((win) => Container(
                  width: 14, height: 14,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: win ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                )),
                if (last5.isEmpty) Text('No matches yet', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                const Spacer(),
                Text('Win rate. ', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                Text('$winRate%', style: GoogleFonts.interTight(fontSize: 14, fontWeight: FontWeight.bold, color: winRate >= 50 ? const Color(0xFF22C55E) : const Color(0xFFEF4444))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('Last active. ${_lastActiveText(daysSinceLast)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
