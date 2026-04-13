import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '/backend/backend.dart';

// ─────────────────────────────────────────────
// Headline Engine — generates emotional copy
// based on match data
// ─────────────────────────────────────────────
class MatchHeadlineEngine {
  static String generate(MatchesRecord match, bool playerWon) {
    final wentTo3 = _wentTo3Games(match);
    final cleanSweep = _isCleanSweep(match, playerWon);
    final isTournament = match.matchType == 'Tournament';
    final mood = match.mood ?? '';
    final cameBack = _cameBackFromGameDown(match, playerWon);

    if (playerWon) {
      if (cameBack) return "Comeback win. Character shown. 🔥";
      if (cleanSweep && isTournament) return "Tournament victory. Clean sweep. That's the one. 🏆";
      if (cleanSweep) return "Didn't drop a game. Dominant. 💥";
      if (isTournament) return "Tournament victory. All that training paid off. 🏆";
      if (mood == 'Tired') return "Tired legs, sharp mind. Won anyway. 💪";
      if (mood == 'Nervous') return "Nerves and all — still got the W. 🎯";
      if (mood == 'Confident') return "Came in confident. Left a winner. 💪";
      if (mood == 'Excited') return "Pure energy. Pure result. 🔥";
      if (wentTo3) return "Three games. One winner. That was a battle. ⚔️";
      return "Another one in the bag. Keep building. 🏸";
    } else {
      if (wentTo3 && isTournament) return "Tournament battle. Went the distance. Learn and return. 🧠";
      if (wentTo3) return "Pushed to 3 games. Getting closer every time. 📈";
      if (cleanSweep && isTournament) return "Tournament experience. File it. Come back stronger. 🧠";
      if (cleanSweep) return "One of those days. Back on court soon. 💪";
      if (mood == 'Focused') return "Gave it everything. The result will come. 🎯";
      if (mood == 'Tired') return "Not every day is your day. Rest up. 😴";
      if (mood == 'Upset') return "Frustrated? Good. Use it. 😤";
      if (isTournament) return "Tournament experience is never wasted. 🧠";
      return "Head up. Every match is data. 📈";
    }
  }

  static bool _wentTo3Games(MatchesRecord match) {
    return (match.g3Player > 0 || match.g3Opponent > 0);
  }

  static bool _isCleanSweep(MatchesRecord match, bool playerWon) {
    if (playerWon) {
      return _gameWon(match.g1Player, match.g1Opponent) &&
          _gameWon(match.g2Player, match.g2Opponent) &&
          match.g3Player == 0 && match.g3Opponent == 0;
    } else {
      return _gameWon(match.g1Opponent, match.g1Player) &&
          _gameWon(match.g2Opponent, match.g2Player) &&
          match.g3Player == 0 && match.g3Opponent == 0;
    }
  }

  static bool _cameBackFromGameDown(MatchesRecord match, bool playerWon) {
    if (!playerWon) return false;
    // Lost game 1, won games 2 and 3
    return _gameWon(match.g1Opponent, match.g1Player) &&
        _gameWon(match.g2Player, match.g2Opponent) &&
        _gameWon(match.g3Player, match.g3Opponent);
  }

  static bool _gameWon(int a, int b) {
    if (a >= 30) return true;
    return a >= 21 && (a - b) >= 2;
  }
}

// ─────────────────────────────────────────────
// Mood display helper
// ─────────────────────────────────────────────
class MoodHelper {
  static String emoji(String? mood) {
    const emojis = {
      'Excited': '🔥',
      'Confident': '💪',
      'Nervous': '😬',
      'Focused': '🎯',
      'Tired': '😴',
      'Anxious': '😰',
      'Sad': '😔',
      'Upset': '😤',
    };
    return emojis[mood] ?? '🏸';
  }
}

// ─────────────────────────────────────────────
// Share Card Widget (the visual card)
// ─────────────────────────────────────────────
class ShareCardWidget extends StatelessWidget {
  final MatchesRecord match;
  final bool playerWon;
  final int playerGames;
  final int opponentGames;

  const ShareCardWidget({
    super.key,
    required this.match,
    required this.playerWon,
    required this.playerGames,
    required this.opponentGames,
  });

  @override
  Widget build(BuildContext context) {
    final headline = MatchHeadlineEngine.generate(match, playerWon);
    final scores = _buildScores();

    return Container(
      width: 360,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: playerWon
              ? [const Color(0xFF1A0A4A), const Color(0xFF3D1F8A), const Color(0xFF2A0A5A)]
              : [const Color(0xFF1A1A2E), const Color(0xFF2D2D44), const Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🏸', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text('MatchPoint Coach',
                      style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: match.matchType == 'Tournament'
                      ? Colors.orange.withOpacity(0.25)
                      : Colors.blue.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: match.matchType == 'Tournament'
                        ? Colors.orange.withOpacity(0.5)
                        : Colors.blue.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  match.matchType,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: match.matchType == 'Tournament'
                          ? Colors.orange.shade300
                          : Colors.blue.shade300),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Result Badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: playerWon
                  ? Colors.amber.withOpacity(0.2)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: playerWon
                    ? Colors.amber.withOpacity(0.5)
                    : Colors.white.withOpacity(0.15),
              ),
            ),
            child: Text(
              playerWon ? '✅  VICTORY' : '📈  LEARNING DAY',
              style: GoogleFonts.inter(
                  color: playerWon ? Colors.amber.shade300 : Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5),
            ),
          ),

          const SizedBox(height: 16),

          // ── Player Name ──
          Text(
            match.playerName.toUpperCase(),
            style: GoogleFonts.interTight(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5),
          ),

          // ── vs Opponent ──
          Text(
            'vs ${match.opponentName}',
            style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
                fontWeight: FontWeight.w400),
          ),

          const SizedBox(height: 20),

          // ── Games Won ──
          Row(
            children: [
              _gamesWonDot(playerGames, playerWon),
              const SizedBox(width: 12),
              Text(
                '$playerGames – $opponentGames',
                style: GoogleFonts.interTight(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 12),
              _gamesWonDot(opponentGames, !playerWon),
            ],
          ),
          Text('games won',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 12)),

          const SizedBox(height: 16),

          // ── Score by Game ──
          ...scores.map((s) => _scoreRow(s[0], s[1], s[2])),

          const SizedBox(height: 20),

          // ── Headline ──
          Text(
            headline,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.4),
          ),

          const SizedBox(height: 16),

          // ── Mood ──
          if (match.mood != null && match.mood!.isNotEmpty)
            Row(
              children: [
                Text(MoodHelper.emoji(match.mood),
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  'Feeling ${match.mood}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // ── Footer ──
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('matchpointcoach.app',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 11,
                      letterSpacing: 0.5)),
              Text('Download on App Store',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 11,
                      letterSpacing: 0.3)),
            ],
          ),
        ],
      ),
    );
  }

  List<List<dynamic>> _buildScores() {
    final result = <List<dynamic>>[];
    void addGame(String label, int p, int o) {
      if (p > 0 || o > 0) result.add([label, p, o]);
    }
    addGame('G1', match.g1Player, match.g1Opponent);
    addGame('G2', match.g2Player, match.g2Opponent);
    addGame('G3', match.g3Player, match.g3Opponent);
    return result;
  }

  Widget _scoreRow(String label, int p, int o) {
    final pWon = (p >= 21 && (p - o) >= 2) || p >= 30;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ),
          Text(
            '$p',
            style: GoogleFonts.inter(
                color: pWon ? Colors.amber.shade300 : Colors.white70,
                fontSize: 15,
                fontWeight: pWon ? FontWeight.bold : FontWeight.normal),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('–',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3), fontSize: 13)),
          ),
          Text(
            '$o',
            style: GoogleFonts.inter(
                color: !pWon ? Colors.white70 : Colors.white38,
                fontSize: 15,
                fontWeight: !pWon ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _gamesWonDot(int count, bool highlight) {
    return Row(
      children: List.generate(
        count,
        (_) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlight
                ? Colors.amber.shade400
                : Colors.white.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Share Bottom Sheet — shown to the user
// ─────────────────────────────────────────────
class ShareResultSheet extends StatefulWidget {
  final MatchesRecord match;
  final bool playerWon;
  final int playerGames;
  final int opponentGames;

  const ShareResultSheet({
    super.key,
    required this.match,
    required this.playerWon,
    required this.playerGames,
    required this.opponentGames,
  });

  @override
  State<ShareResultSheet> createState() => _ShareResultSheetState();
}

class _ShareResultSheetState extends State<ShareResultSheet> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final Uint8List? image = await _screenshotController.capture(
        pixelRatio: 3.0, // high res for Instagram/Stories
      );
      if (image == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/matchpoint_result.png');
      await file.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '${widget.playerWon ? "🏆 Victory!" : "📈 Learning day."} Playing badminton with MatchPoint Coach — track your game at matchpointcoach.app',
      );
    } finally {
      setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Share Your Result',
              style: GoogleFonts.interTight(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Card preview with screenshot wrapper
          Screenshot(
            controller: _screenshotController,
            child: ShareCardWidget(
              match: widget.match,
              playerWon: widget.playerWon,
              playerGames: widget.playerGames,
              opponentGames: widget.opponentGames,
            ),
          ),

          const SizedBox(height: 24),

          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sharing ? null : _share,
              icon: _sharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.share_rounded, color: Colors.white),
              label: Text(
                _sharing ? 'Preparing...' : 'Share',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B39EF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Opens your device share sheet — WhatsApp, Instagram, X and more',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35), fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helper to show the sheet from anywhere
// ─────────────────────────────────────────────
void showShareSheet(BuildContext context, MatchesRecord match,
    bool playerWon, int playerGames, int opponentGames) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ShareResultSheet(
      match: match,
      playerWon: playerWon,
      playerGames: playerGames,
      opponentGames: opponentGames,
    ),
  );
}
