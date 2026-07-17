import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/club_service.dart';
import '/services/message_service.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/index.dart';

class MyClubPage extends StatefulWidget {
  const MyClubPage({super.key});
  static String routeName = 'MyClubPage';
  static String routePath = '/myClub';

  @override
  State<MyClubPage> createState() => _MyClubPageState();
}

class _MyClubPageState extends State<MyClubPage> {
  Map<String, dynamic>? _club;
  List<Map<String, dynamic>> _coaches = [];
  int _playerCount = 0;
  Map<String, dynamic>? _latestMessage;
  int _unreadCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClub();
  }

  Future<void> _loadClub() async {
    final club = await ClubService().getMyClub();
    if (club != null) {
      final coaches = await ClubService().getClubCoaches(club['clubId']);
      final players = await ClubService().getClubPlayers(club['clubId']);
      final latestMessage = await MessageService().getLatestMessage(club['clubId']);
      final unreadCount = await MessageService().getUnreadCount(club['clubId']);
      setState(() {
        _club = club;
        _coaches = coaches;
        _playerCount = players.length;
        _latestMessage = latestMessage;
        _unreadCount = unreadCount;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
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
        title: Text('My Club',
            style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _club == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined, color: Colors.grey.shade400, size: 40),
                          const SizedBox(height: 16),
                          Text('No club found.',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => context.pushNamed(JoinClubPage.routeName),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Join a Club'),
                          ),
                        ],
                      ),
                    )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: primary.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(Icons.shield_outlined, color: primary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_club!['clubName'] ?? '',
                                      style: GoogleFonts.interTight(fontSize: 20, fontWeight: FontWeight.bold,
                                          color: FlutterFlowTheme.of(context).primaryText)),
                                  if ((_club!['location'] ?? '').isNotEmpty)
                                    Text(_club!['location'],
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _infoRow(Icons.people_outline, '$_playerCount players'),
                        const SizedBox(height: 8),
                        _infoRow(Icons.sports_outlined, _coaches.isNotEmpty
                            ? 'Coach: ${_coaches.map((c) => (c['display_name'] as String?)?.isNotEmpty == true ? c['display_name'] : 'Coach').join(', ')}'
                            : 'No coach assigned'),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () {
                            context.pushNamed(
                              ClubMessagesPage.routeName,
                              queryParameters: {'clubId': _club!['clubId']},
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).secondaryBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.campaign_outlined, size: 20, color: primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Club Messages',
                                          style: GoogleFonts.interTight(fontSize: 14, fontWeight: FontWeight.bold,
                                              color: FlutterFlowTheme.of(context).primaryText)),
                                      if (_latestMessage != null)
                                        Text(_latestMessage!['text'] ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
                                      else
                                        Text('No messages yet',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                                if (_unreadCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade500,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('$_unreadCount',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        ),
      ],
    );
  }
}
