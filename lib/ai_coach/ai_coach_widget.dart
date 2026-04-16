import 'dart:ui';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/premium_service.dart';
import '/premium/premium_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_coach_model.dart';
export 'ai_coach_model.dart';

class AiCoachWidget extends StatefulWidget {
  const AiCoachWidget({super.key});
  static String routeName = 'AiCoach';
  static String routePath = '/aiCoach';
  @override
  State<AiCoachWidget> createState() => _AiCoachWidgetState();
}

class _AiCoachWidgetState extends State<AiCoachWidget> {
  late AiCoachModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _premiumService = PremiumService();
  String _tier = 'free';
  bool _loadingStatus = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AiCoachModel());
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await _premiumService.getSubscriptionStatus().timeout(
        const Duration(seconds: 5),
        onTimeout: () => {'tier': 'free'},
      );
      if (mounted) {
        setState(() {
          _tier = status['tier'] as String;
          _loadingStatus = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _tier = 'free';
          _loadingStatus = false;
        });
      }
    }
  }

  String? _matchWinner(MatchesRecord match) {
    final target = match.scoringFormat == '15' ? 15 : 21;
    final cap = target == 15 ? 17 : 30;
    int playerGames = 0;
    int opponentGames = 0;
    for (final pair in [[match.g1Player, match.g1Opponent],[match.g2Player, match.g2Opponent],[match.g3Player, match.g3Opponent]]) {
      final p = pair[0]; final o = pair[1];
      if ((p >= target && (p - o) >= 2) || p >= cap) playerGames++;
      else if ((o >= target && (o - p) >= 2) || o >= cap) opponentGames++;
    }
    if (playerGames >= 2) return "player";
    if (opponentGames >= 2) return "opponent";
    return null;
  }

  Map<String, String> _computeBlurredInsights(List<MatchesRecord> completed) {
    final hasEnoughData = completed.length >= 5;
    String slowStart = completed.length >= 5 ? () { final lostG1 = completed.where((m) => m.g1Player < m.g1Opponent).length; final pct = ((lostG1 / completed.length) * 100).round(); return "You start slow in ${pct}% of matches"; }() : "We are building your performance profile";
    if (completed.isNotEmpty) {
      final lostG1 = completed.where((m) => m.g1Player < m.g1Opponent).length;
      final pct = ((lostG1 / completed.length) * 100).round();
    // handled above
    }
    String tiredStat = "Your win rate drops when tired";
    final tiredMatches = completed.where((m) => m.mood.toLowerCase().contains('tired')).toList();
    if (tiredMatches.length >= 2) {
      final tiredWins = tiredMatches.where((m) => _matchWinner(m) == "player").length;
      final pct = ((tiredWins / tiredMatches.length) * 100).round();
      tiredStat = "Your win rate drops to ${pct}% when tired";
    }
    String ledLost = "You sometimes lose matches after leading";
    final wonG1 = completed.where((m) => m.g1Player > m.g1Opponent).toList();
    if (wonG1.isNotEmpty) {
      final ledThenLost = wonG1.where((m) => _matchWinner(m) == "opponent").length;
      if (ledThenLost > 0) ledLost = "You have lost \$ledThenLost match${ledThenLost == 1 ? '' : 'es'} after winning Game 1";
    }
    return {'slowStart': slowStart, 'tiredStat': tiredStat, 'ledLost': ledLost};
  }

  List<Map<String, dynamic>> _generateInsights(List<MatchesRecord> matches) {
    final completed = matches.where((m) => _matchWinner(m) != null).toList();
    if (completed.isEmpty) return [];
    final insights = <Map<String, dynamic>>[];
    final wins = completed.where((m) => _matchWinner(m) == "player").length;
    final winRate = wins / completed.length;

    // ── Win Rate (free) ──
    if (completed.length < 5) {
      final remaining = 5 - completed.length;
      final remainingLabel = remaining == 1 ? "1 more match" : "$remaining more matches";
      insights.add({"icon": "🏸", "title": "Getting Started", "body": "We are learning your game. Play $remainingLabel to unlock your first coaching report.", "progress": completed.length, "tier": "free"});
    } else if (winRate >= 0.7) {
      insights.add({"icon": "🔥", "title": "Strong Win Rate", "body": "You are winning ${(winRate * 100).round()}% of your ${completed.length} matches — that puts you in the top tier of players tracking their game. The challenge now is not just winning, it is raising your own bar.", "tier": "free"});
    } else if (winRate >= 0.5) {
      insights.add({"icon": "📈", "title": "Positive Win Rate", "body": "You are winning ${(winRate * 100).round()}% of your ${completed.length} matches. You win more than you lose — but the margins are tight. The players who break through at this level learn to close out the games they are already winning.", "tier": "free"});
    } else if (winRate > 0.2) {
      insights.add({"icon": "💪", "title": "Developing Win Rate", "body": "You are winning ${(winRate * 100).round()}% of your ${completed.length} matches. Right now the losses outweigh the wins — but you are here, tracking, analysing, improving. That is what separates players who plateau from players who break through.", "tier": "free"});
    } else {
      insights.add({"icon": "🌱", "title": "Early Stage", "body": "At ${(winRate * 100).round()}%, you are still finding your rhythm. Keep playing, keep tracking, and focus on small improvements each match.", "tier": "free"});
    }

    final moodStats = <String, Map<String, int>>{};
    for (final m in completed) {
      if (m.mood.isEmpty) continue;
      moodStats[m.mood] ??= {"wins": 0, "total": 0};
      moodStats[m.mood]!["total"] = moodStats[m.mood]!["total"]! + 1;
      if (_matchWinner(m) == "player") moodStats[m.mood]!["wins"] = moodStats[m.mood]!["wins"]! + 1;
    }
    // ── Peak Performance Mood (free) ──
    if (moodStats.isNotEmpty) {
      String? bestMood; double bestRate = 0;
      String? worstMoodFree; double worstRateFree = 1;
      moodStats.forEach((mood, stats) {
        if (stats["total"]! >= 2) {
          final rate = stats["wins"]! / stats["total"]!;
          if (rate > bestRate) { bestRate = rate; bestMood = mood; }
          if (rate < worstRateFree) { worstRateFree = rate; worstMoodFree = mood; }
        }
      });
      if (bestMood != null) {
        final pct = (bestRate * 100).round();
        String moodBody;
        if (bestRate >= 0.7) {
          moodBody = "You perform very strongly when feeling $bestMood, winning $pct% of those matches. Try to bring that mindset into every match.";
        } else if (bestRate >= 0.4) {
          moodBody = "You perform best when feeling $bestMood, winning $pct% of those matches. Try to recreate that mindset before your next game.";
        } else {
          moodBody = "You perform slightly better when feeling $bestMood, but results are still building. Focus on consistency across all matches.";
        }
        insights.add({"icon": "🧠", "title": "Peak Performance Mood", "body": moodBody, "tier": "free"});
        if (worstMoodFree != null && worstMoodFree != bestMood && worstRateFree < 0.5) {
          insights.add({"icon": "⚡", "title": "Mood to Watch", "body": "When feeling $worstMoodFree, your results tend to drop. Being aware of this can help you manage your mindset during matches.", "tier": "free"});
        }
      } else {
        insights.add({"icon": "🧠", "title": "Peak Performance Mood", "body": "You have not played enough matches in each mood yet to identify a clear pattern.", "tier": "free"});
      }
    }

    // ── On Fire / Reset Mode (free) ──
    {
      int winStreak = 0;
      int loseStreak = 0;
      for (final m in completed) {
        if (_matchWinner(m) == "player") { winStreak++; loseStreak = 0; }
        else { loseStreak++; winStreak = 0; }
      }
      // completed is ordered descending so first entry = most recent
      // recalculate streaks from most recent
      int wStreak = 0;
      int lStreak = 0;
      for (final m in completed) {
        if (wStreak == 0 && lStreak == 0) {
          if (_matchWinner(m) == "player") wStreak++;
          else lStreak++;
        } else if (wStreak > 0) {
          if (_matchWinner(m) == "player") wStreak++;
          else break;
        } else {
          if (_matchWinner(m) == "opponent") lStreak++;
          else break;
        }
      }
      if (wStreak >= 5) {
        insights.add({"icon": "🔥", "title": "On Fire!", "body": "$wStreak wins in a row. You are in top form right now — this is a great time to push yourself against stronger opponents.", "tier": "free"});
      } else if (wStreak >= 3) {
        insights.add({"icon": "🔥", "title": "On Fire!", "body": "$wStreak match winning streak. Your game is in a good place — keep the momentum going.", "tier": "free"});
      } else if (wStreak == 2) {
        insights.add({"icon": "📈", "title": "Early Momentum", "body": "You have won two matches in a row. Momentum is starting to build — keep it going.", "tier": "free"});
      } else if (lStreak >= 3) {
        insights.add({"icon": "🔄", "title": "Losing Streak", "body": "$lStreak losses in a row. It might be time to adjust your approach — small changes can help turn results around.", "tier": "free"});
      } else if (lStreak >= 1) {
        insights.add({"icon": "🔄", "title": "Bounce Back Time", "body": "Your last match was a loss. One result does not define your form — focus on your next match.", "tier": "free"});
      } else if (wStreak == 1) {
        insights.add({"icon": "✅", "title": "Winning Momentum", "body": "You won your last match. A good result — build on this in your next game.", "tier": "free"});
      }
    }

    // ── Danger Mood Warning (pro) ──
    if (moodStats.isNotEmpty) {
      String? worstMoodPro; double worstRatePro = 1;
      moodStats.forEach((mood, stats) {
        if (stats["total"]! >= 3) {
          final rate = stats["wins"]! / stats["total"]!;
          if (rate < worstRatePro) { worstRatePro = rate; worstMoodPro = mood; }
        }
      });
      final bestMoodForCheck = moodStats.entries.where((e) => e.value["total"]! >= 2).fold<String?>(null, (prev, e) { final r = e.value["wins"]! / e.value["total"]!; return (prev == null || r > (moodStats[prev]!["wins"]! / moodStats[prev]!["total"]!)) ? e.key : prev; });
      if (worstMoodPro != null && worstMoodPro != bestMoodForCheck && worstRatePro < winRate) {
        final pct = (worstRatePro * 100).round();
        String dangerBody;
        if (worstRatePro < 0.2) {
          dangerBody = "When you feel $worstMoodPro, your win rate drops to $pct%. This mood is having a strong impact on your results — working on your pre-match mindset could make a big difference.";
        } else if (worstRatePro < 0.4) {
          dangerBody = "Your win rate is $pct% when feeling $worstMoodPro. This pattern is worth paying attention to — finding ways to manage this mindset before matches could help your performance.";
        } else {
          dangerBody = "You win $pct% when feeling $worstMoodPro, which is lower than your usual level. Being aware of this is the first step to managing it during matches.";
        }
        insights.add({"icon": "⚠️", "title": "Danger Mood Warning", "body": dangerBody, "tier": "pro"});
      }
    }

    final tMatches = completed.where((m) => m.matchType == "Tournament").toList();
    final pMatches = completed.where((m) => m.matchType == "Practice").toList();
    // ── Match Frequency (free) ──
    if (completed.length >= 2) {
      final now = DateTime.now();
      final last30 = completed.where((m) => m.matchDate != null && now.difference(m.matchDate!).inDays <= 30).length;
      final prev15 = completed.where((m) => m.matchDate != null && now.difference(m.matchDate!).inDays > 15 && now.difference(m.matchDate!).inDays <= 30).length;
      final recent15 = completed.where((m) => m.matchDate != null && now.difference(m.matchDate!).inDays <= 15).length;
      String freqBody;
      if (last30 >= 6) {
        freqBody = "You have played $last30 matches in the last 30 days. You are playing regularly — this level of consistency supports steady improvement. Make sure you are recovering well between matches.";
      } else if (last30 >= 4) {
        freqBody = "You have played $last30 matches in the last 30 days. Good consistency — regular play like this helps you build and maintain your level.";
      } else if (last30 >= 2) {
        freqBody = "You have played $last30 matches in the last 30 days. A steady start — try to increase your frequency to keep your game sharp.";
      } else if (last30 == 1) {
        freqBody = "You have played 1 match in the last 30 days. Playing more regularly will help you improve faster — even one extra match per week can make a difference.";
      } else {
        freqBody = "No matches recorded in the last 30 days. Getting back on court is the most important step to improving your game.";
      }
      String trendAdd = "";
      if (recent15 > prev15 && prev15 > 0) trendAdd = " You have been more active recently — keep this rhythm going.";
      else if (prev15 > recent15 && recent15 < prev15) trendAdd = " Your recent activity has dropped — getting back into a routine will help.";
      insights.add({
        "icon": "📅",
        "title": "Match Frequency",
        "body": freqBody + trendAdd,
        "tier": "free"
      });
    }

    // ── Match Balance (free) ──
    if (completed.length >= 3) {
      final tCount = completed.where((m) => m.matchType == "Tournament").length;
      final pCount = completed.where((m) => m.matchType == "Practice").length;
      final tPct = ((tCount / completed.length) * 100).round();
      final pPct = ((pCount / completed.length) * 100).round();
      String balanceBody;
      if (tCount == completed.length) {
        balanceBody = "All your recorded matches are tournaments. Adding practice sessions will help you refine your game between competitions.";
      } else if (pCount == completed.length) {
        balanceBody = "All your recorded matches are practice. Competition is where your game gets tested — consider entering a tournament to challenge yourself.";
      } else if (tPct >= 70) {
        balanceBody = "Your matches are $tPct% tournaments and $pPct% practice. You are getting strong competitive exposure — make sure you balance it with practice to keep improving your game.";
      } else if (pPct >= 70) {
        balanceBody = "Your matches are $pPct% practice and $tPct% tournaments. You are building a solid base — start testing your game more in competition.";
      } else if (completed.length < 5) {
        balanceBody = "You have not logged many matches yet. Keep tracking to get a clearer view of your playing patterns.";
      } else {
        balanceBody = "Your matches are well balanced between practice and tournaments. You are developing your game and testing it — keep this balance going.";
      }
      insights.add({
        "icon": "⚖️",
        "title": "Match Balance",
        "body": balanceBody,
        "tier": "free"
      });
    }

    // ── Close Game Performance (pro) ──
    {
      int closeGamesTotal = 0;
      int closeGamesWon = 0;
      int totalGamesPlayed = 0;
      for (final m in completed) {
        final games = [
          [m.g1Player, m.g1Opponent],
          [m.g2Player, m.g2Opponent],
          [m.g3Player, m.g3Opponent],
        ];
        for (final g in games) {
          final p = g[0]; final o = g[1];
          if (p == 0 && o == 0) continue;
          totalGamesPlayed++;
          final diff = (p - o).abs();
          if (diff <= 3) {
            closeGamesTotal++;
            if (p > o) closeGamesWon++;
          }
        }
      }
      if (closeGamesTotal >= 5) {
        final closeRate = closeGamesWon / closeGamesTotal;
        final closePct = (closeRate * 100).round();
        String closeBody; String closeTitle;
        if (closeRate >= 0.6) {
          closeTitle = "Close Game Specialist";
          closeBody = "In close games decided by 3 points or fewer, you win $closePct% of them. You handle tight situations well — this is a strong competitive edge.";
        } else if (closeRate >= 0.4) {
          closeTitle = "Competitive in Close Games";
          closeBody = "In close games decided by 3 points or fewer, you win $closePct% of them. You are competitive in tight moments — small improvements in key points could push this higher.";
        } else {
          closeTitle = "Close Games Need Work";
          closeBody = "In close games decided by 3 points or fewer, you win $closePct% of them. Tight moments are not going your way often enough — improving focus in key points could help.";
        }
        final addOn = totalGamesPlayed > 0 && (closeGamesTotal / totalGamesPlayed) >= 0.4
            ? " A large portion of your games are decided by small margins — improving performance in these moments could significantly impact your results."
            : "";
        insights.add({"icon": "⚔️", "title": closeTitle, "body": closeBody + addOn, "tier": "pro"});
      }
    }

    // ── Consistency Score (pro) ──
    if (completed.length >= 8) {
      final sample = completed.take(10).toList();
      int switches = 0;
      for (int i = 0; i < sample.length - 1; i++) {
        final curr = _matchWinner(sample[i]) == "player";
        final next = _matchWinner(sample[i + 1]) == "player";
        if (curr != next) switches++;
      }
      final ratio = switches / (sample.length - 1);
      String consBody; String consTitle;
      if (ratio <= 0.3) {
        consTitle = "Consistent Performer";
        consBody = "Your results are consistent across matches. You maintain a steady level — this kind of reliability is a strong foundation for improvement.";
      } else if (ratio <= 0.55) {
        consTitle = "Mixed Consistency";
        consBody = "Your results show some variation between matches. You have the level — improving consistency could help you perform at your best more often.";
      } else {
        consTitle = "Inconsistent Results";
        consBody = "Your results vary significantly between matches. Inconsistency is affecting your performance — focusing on preparation and routine could help stabilise your game.";
      }
      // Add-on: compare recent 5 vs earlier 5 consistency
      String consAddOn = "";
      if (completed.length >= 10) {
        final recent5 = completed.take(5).toList();
        final earlier5 = completed.skip(5).take(5).toList();
        int recentSwitches = 0;
        int earlierSwitches = 0;
        for (int i = 0; i < 4; i++) {
          if (_matchWinner(recent5[i]) != _matchWinner(recent5[i+1])) recentSwitches++;
          if (_matchWinner(earlier5[i]) != _matchWinner(earlier5[i+1])) earlierSwitches++;
        }
        if (recentSwitches < earlierSwitches) consAddOn = " Your recent matches are becoming more consistent — keep building on this.";
      }
      insights.add({"icon": "📊", "title": consTitle, "body": consBody + consAddOn, "tier": "pro"});
    }

    // ── Tournament Performance (pro) ──

    if (tMatches.length >= 3 && pMatches.length >= 3) {
      final tRate = tMatches.where((m) => _matchWinner(m) == "player").length / tMatches.length;
      final pRate = pMatches.where((m) => _matchWinner(m) == "player").length / pMatches.length;
      final tPct = (tRate * 100).round();
      final pPct = (pRate * 100).round();
      final diff = tRate - pRate;
      String tournBody;
      String tournTitle;
      String tournIcon;
      if (diff >= 0.2) {
        tournTitle = "Tournament Advantage"; tournIcon = "🏆";
        tournBody = "You win $tPct% of your tournament matches compared to $pPct% in practice. You perform strongly in competition — keep building on this edge.";
      } else if (diff >= 0.1) {
        tournTitle = "Slight Tournament Edge"; tournIcon = "🏆";
        tournBody = "Your tournament win rate is $tPct% compared to $pPct% in practice. Competition brings out a little extra in your game — keep building on it.";
      } else if (diff <= -0.2) {
        tournTitle = "Tournament Pressure"; tournIcon = "⚡";
        tournBody = "Your win rate drops from $pPct% in practice to $tPct% in tournaments. The added pressure is affecting your results — working on your preparation before matches could help.";
      } else if (diff <= -0.1) {
        tournTitle = "Slight Tournament Pressure"; tournIcon = "⚡";
        tournBody = "You win $tPct% in tournaments compared to $pPct% in practice. There is a small gap — focusing on consistency could help close it.";
      } else {
        tournTitle = ""; tournIcon = ""; tournBody = "";
      }
      if (tournBody.isNotEmpty) insights.add({"icon": tournIcon, "title": tournTitle, "body": tournBody, "tier": "pro"});
    }

    // ── Comeback Performance (pro) ──
    final lostG1 = completed.where((m) => m.g1Player < m.g1Opponent).toList();
    if (lostG1.length >= 3) {
      final comebacks = lostG1.where((m) => _matchWinner(m) == "player").length;
      final rate = comebacks / lostG1.length;
      final pct = (rate * 100).round();
      String comebackBody; String comebackTitle; String comebackIcon;
      if (rate >= 0.7) {
        comebackTitle = "Comeback King"; comebackIcon = "🔄";
        comebackBody = "You win $pct% of matches after losing Game 1. You handle pressure well and find ways to turn matches around — a strong competitive edge.";
      } else if (rate >= 0.5) {
        comebackTitle = "Strong Comeback"; comebackIcon = "💪";
        comebackBody = "You recover to win $pct% of matches after losing Game 1. Your resilience is a strength — keep trusting your game when you fall behind.";
      } else if (rate >= 0.2) {
        comebackTitle = "Developing Comebacks"; comebackIcon = "🎯";
        comebackBody = "When you lose Game 1, you recover $pct% of the time. Improving your reset between games could help turn more matches around.";
      } else {
        comebackTitle = "Start Strong"; comebackIcon = "⚡";
        comebackBody = "When you lose Game 1, it is difficult to recover — your comeback rate is $pct%. Focusing on strong starts and between-game adjustments could make a difference.";
      }
      insights.add({"icon": comebackIcon, "title": comebackTitle, "body": comebackBody, "tier": "pro"});
    }

    // ── Closing Out Matches (pro) ──
    final wonG1 = completed.where((m) => m.g1Player > m.g1Opponent).toList();
    if (wonG1.length >= 3) {
      final ledLost = wonG1.where((m) => _matchWinner(m) == "opponent").length;
      final ledRate = ledLost / wonG1.length;
      final ledPct = (ledRate * 100).round();
      String closeBody; String closeTitle;
      if (ledRate >= 0.5) {
        closeTitle = "Closing Problem";
        closeBody = "You are losing $ledPct% of matches after winning Game 1. Closing out matches is proving difficult — maintaining focus and intensity when ahead could make a big difference.";
      } else if (ledRate >= 0.3) {
        closeTitle = "Closing Needs Work";
        closeBody = "You lose $ledPct% of matches after winning Game 1. This is a pattern worth improving — sustaining pressure when you are ahead could help you win more matches.";
      } else if (ledRate >= 0.15) {
        closeTitle = "Slight Closing Issue";
        closeBody = "You occasionally lose matches after winning Game 1 — $ledPct% of the time. Small lapses when ahead can be costly.";
      } else {
        closeTitle = ""; closeBody = "";
      }
      if (closeBody.isNotEmpty) insights.add({"icon": "😤", "title": closeTitle, "body": closeBody, "tier": "pro"});
    }

    // ── Main Rival (pro) ──
    final opponentCount = <String, int>{};
    for (final m in completed) { if (m.opponentName.isNotEmpty) opponentCount[m.opponentName] = (opponentCount[m.opponentName] ?? 0) + 1; }
    if (opponentCount.isNotEmpty) {
      final rival = opponentCount.entries.reduce((a, b) => a.value >= b.value ? a : b);
      if (rival.value >= 3) {
        final rivalWins = completed.where((m) => m.opponentName == rival.key && _matchWinner(m) == "player").length;
        final rivalRate = rivalWins / rival.value;
        final rivalPct = (rivalRate * 100).round();
        String rivalBody;
        if (rivalRate >= 0.7) {
          rivalBody = "You have played ${rival.key} ${rival.value} times and won $rivalPct% of those matches. You have a strong record in this matchup — keep the consistency.";
        } else if (rivalRate >= 0.4) {
          rivalBody = "${rival.key} is your most frequent opponent — you have played ${rival.value} matches and won $rivalPct%. It is a close rivalry — small adjustments could give you the edge.";
        } else {
          rivalBody = "You have played ${rival.key} ${rival.value} times and won $rivalPct% of those matches. They currently have the upper hand — reviewing your matches could help you turn this around.";
        }
        insights.add({"icon": "🆚", "title": "Main Rival", "body": rivalBody, "tier": "pro"});
      }
    }

    // ── Format Strength (pro) ──
    final doubles = completed.where((m) => m.partnerName.isNotEmpty).toList();
    final singles = completed.where((m) => m.partnerName.isEmpty).toList();
    if (doubles.length >= 3 && singles.length >= 3) {
      final dRate = doubles.where((m) => _matchWinner(m) == "player").length / doubles.length;
      final sRate = singles.where((m) => _matchWinner(m) == "player").length / singles.length;
      final sPct = (sRate * 100).round();
      final dPct = (dRate * 100).round();
      final fDiff = sRate - dRate;
      String formatBody; String formatTitle;
      if (fDiff >= 0.2) {
        formatTitle = "Singles Specialist";
        formatBody = "You win $sPct% of your singles matches compared to $dPct% in doubles. Singles is your stronger format — keep building on this advantage.";
      } else if (fDiff >= 0.1) {
        formatTitle = "Slight Singles Edge";
        formatBody = "Your singles win rate is $sPct% compared to $dPct% in doubles. You perform slightly better in singles — continue developing both formats.";
      } else if (fDiff <= -0.2) {
        formatTitle = "Doubles Specialist";
        formatBody = "You win $dPct% of your doubles matches compared to $sPct% in singles. Doubles is your stronger format — keep building on this advantage.";
      } else if (fDiff <= -0.1) {
        formatTitle = "Slight Doubles Edge";
        formatBody = "Your doubles win rate is $dPct% compared to $sPct% in singles. You perform slightly better in doubles — continue building across both formats.";
      } else {
        formatTitle = ""; formatBody = "";
      }
      if (formatBody.isNotEmpty) insights.add({"icon": "🏸", "title": formatTitle, "body": formatBody, "tier": "pro"});
    }

    // ── Match Dominance Profile (premium) ──
    {
      int gamesWon = 0;
      int gamesLost = 0;
      int totalWinMargin = 0;
      int totalLossMargin = 0;
      for (final m in completed) {
        final games = [
          [m.g1Player, m.g1Opponent],
          [m.g2Player, m.g2Opponent],
          [m.g3Player, m.g3Opponent],
        ];
        for (final g in games) {
          final p = g[0]; final o = g[1];
          if (p == 0 && o == 0) continue;
          if (p > o) { gamesWon++; totalWinMargin += (p - o); }
          else if (o > p) { gamesLost++; totalLossMargin += (o - p); }
        }
      }
      if (gamesWon >= 5) {
        final avgWinMargin = totalWinMargin / gamesWon;
        final avgLossMargin = gamesLost > 0 ? totalLossMargin / gamesLost : 0.0;
        final marginStr = avgWinMargin.toStringAsFixed(1);
        String domBody; String domTitle;
        if (avgWinMargin >= 6) {
          domTitle = "Match Dominator";
          domBody = "When you win games, you win them by an average of $marginStr points. Your victories are comfortable — you tend to control games.";
        } else if (avgWinMargin >= 3) {
          domTitle = "Controlled Winner";
          domBody = "When you win games, you win them by an average of $marginStr points. Your wins are solid — you stay in control without always dominating.";
        } else {
          domTitle = "Narrow Winner";
          domBody = "When you win games, you win them by an average of $marginStr points. Your wins are tight — improving how you close out games could help you take more control.";
        }
        final addOnDom = avgLossMargin >= avgWinMargin
            ? " You are also losing games by similar or larger margins — reducing errors in those moments could improve your results."
            : "";
        insights.add({"icon": "💪", "title": domTitle, "body": domBody + addOnDom, "tier": "premium"});
      }
    }

    // ── Performance Under Pressure (premium) ──
    {
      int pressureTotal = 0;
      int pressureWon = 0;
      for (final m in completed) {
        final g3Played = m.g3Player > 0 || m.g3Opponent > 0;
        if (!g3Played) continue;
        final g3Diff = (m.g3Player - m.g3Opponent).abs();
        if (g3Diff <= 3) {
          pressureTotal++;
          if (_matchWinner(m) == "player") pressureWon++;
        }
      }
      if (pressureTotal >= 3) {
        final pressRate = pressureWon / pressureTotal;
        final pressPct = (pressRate * 100).round();
        String pressBody; String pressTitle;
        if (pressRate >= 0.6) {
          pressTitle = "Clutch Performer";
          pressBody = "In matches decided by tight final games, you win $pressPct% of the time. You perform well in decisive moments — a strong competitive edge.";
        } else if (pressRate >= 0.4) {
          pressTitle = "Competitive Under Pressure";
          pressBody = "In matches decided by tight final games, you win $pressPct% of the time. You compete well under pressure — small improvements in key moments could make a difference.";
        } else {
          pressTitle = "Pressure Needs Work";
          pressBody = "In matches decided by tight final games, you win $pressPct% of the time. Tight matches are not going your way often enough — improving focus in decisive moments could help.";
        }
        insights.add({"icon": "🎯", "title": pressTitle, "body": pressBody, "tier": "premium"});
      }
    }

    // ── Deciding Game Performance (premium) ──

    final threeSetMatches = completed.where((m) => m.g3Player > 0 || m.g3Opponent > 0).toList();
    if (threeSetMatches.length >= 3) {
      final g3Wins = threeSetMatches.where((m) => _matchWinner(m) == "player").length;
      final g3Rate = g3Wins / threeSetMatches.length;
      final g3Pct = (g3Rate * 100).round();
      String g3Body; String g3Title; String g3Icon;
      if (g3Rate >= 0.7) {
        g3Title = "Decider Specialist"; g3Icon = "💥";
        g3Body = "You win $g3Pct% of your deciding games. When matches go the distance, you consistently find a way to come out on top — a strong competitive edge.";
      } else if (g3Rate >= 0.5) {
        g3Title = "Strong in Deciders"; g3Icon = "💪";
        g3Body = "You win $g3Pct% of your deciding games. You handle pressure well — keep building your consistency in close matches.";
      } else if (g3Rate >= 0.3) {
        g3Title = "Decider Needs Work"; g3Icon = "🎯";
        g3Body = "You win $g3Pct% of your deciding games. Close matches are not going your way often enough — improving focus and consistency in the final game could help.";
      } else {
        g3Title = "Struggling in Deciders"; g3Icon = "⚡";
        g3Body = "You win $g3Pct% of your deciding games. When matches reach a final game, results are challenging — focusing on fitness and between-game resets could make a difference.";
      }
      insights.add({"icon": g3Icon, "title": g3Title, "body": g3Body, "tier": "premium"});
    }

    // ── Performance Trend (premium) ──
    final sortedByDate = List<MatchesRecord>.from(completed)..sort((a, b) => a.matchDate!.compareTo(b.matchDate!));
    if (sortedByDate.length >= 6) {
      final recentMatches = sortedByDate.reversed.take(5).toList();
      final earlierMatches = sortedByDate.reversed.skip(5).take(5).toList();
      if (earlierMatches.isNotEmpty) {
        final recentRate = recentMatches.where((m) => _matchWinner(m) == "player").length / recentMatches.length;
        final earlyRate = earlierMatches.where((m) => _matchWinner(m) == "player").length / earlierMatches.length;
        final trendDiff = recentRate - earlyRate;
        final recentPct = (recentRate * 100).round();
        final earlyPct = (earlyRate * 100).round();
        String trendBody; String trendTitle; String trendIcon;
        if (trendDiff >= 0.2) {
          trendTitle = "Strong Improvement"; trendIcon = "📈";
          trendBody = "Your recent win rate is $recentPct%, up from $earlyPct% earlier. You are improving quickly — keep building on what is working.";
        } else if (trendDiff >= 0.1) {
          trendTitle = "Improving Trend"; trendIcon = "📈";
          trendBody = "Your recent win rate is $recentPct%, slightly ahead of $earlyPct% earlier. You are trending in the right direction — consistency will be key.";
        } else if (trendDiff <= -0.2) {
          trendTitle = "Significant Dip"; trendIcon = "📉";
          trendBody = "Your recent win rate is $recentPct%, down from $earlyPct% earlier. Something has changed — reviewing your recent matches could help identify what to adjust.";
        } else if (trendDiff <= -0.1) {
          trendTitle = "Slight Dip in Form"; trendIcon = "📉";
          trendBody = "Your recent win rate is $recentPct%, slightly down from $earlyPct% earlier. A small dip — reflecting on recent matches could help you get back on track.";
        } else {
          trendTitle = ""; trendIcon = ""; trendBody = "";
        }
        if (trendBody.isNotEmpty) insights.add({"icon": trendIcon, "title": trendTitle, "body": trendBody, "tier": "premium"});
      }
    }

    // ── Recent Form (premium) ──
    if (completed.length >= 5) {
      final last5Rate = completed.take(5).where((m) => _matchWinner(m) == "player").length / 5;
      final formDiff = last5Rate - winRate;
      final last5Pct = (last5Rate * 100).round();
      final careerPct = (winRate * 100).round();
      String formBody; String formTitle; String formIcon;
      if (formDiff >= 0.2) {
        formTitle = "Excellent Recent Form"; formIcon = "🔥";
        formBody = "Your last 5 matches show a $last5Pct% win rate — well above your overall average of $careerPct%. You are in strong form right now — keep building on it.";
      } else if (formDiff >= 0.1) {
        formTitle = "Good Recent Form"; formIcon = "📈";
        formBody = "Your last 5 matches show a $last5Pct% win rate — ahead of your overall average of $careerPct%. Your recent form is encouraging — keep the momentum going.";
      } else if (formDiff <= -0.2) {
        formTitle = "Poor Recent Form"; formIcon = "📉";
        formBody = "Your last 5 matches show a $last5Pct% win rate — below your overall average of $careerPct%. Your recent form needs attention — reviewing recent matches could help identify what to adjust.";
      } else if (formDiff <= -0.1) {
        formTitle = "Slight Dip in Form"; formIcon = "📉";
        formBody = "Your last 5 matches show a $last5Pct% win rate — slightly below your overall average of $careerPct%. A small dip — focus on getting back to your usual level.";
      } else {
        formTitle = ""; formIcon = ""; formBody = "";
      }
      if (formBody.isNotEmpty) insights.add({"icon": formIcon, "title": formTitle, "body": formBody, "tier": "premium"});
    }

    // ── Points Profile (premium) ──
    if (completed.length >= 3) {
      int totalScored = 0, totalConceded = 0, gameCount = 0;
      for (final m in completed) {
        if (m.g1Player > 0 || m.g1Opponent > 0) { totalScored += m.g1Player; totalConceded += m.g1Opponent; gameCount++; }
        if (m.g2Player > 0 || m.g2Opponent > 0) { totalScored += m.g2Player; totalConceded += m.g2Opponent; gameCount++; }
        if (m.g3Player > 0 || m.g3Opponent > 0) { totalScored += m.g3Player; totalConceded += m.g3Opponent; gameCount++; }
      }
      if (gameCount >= 5) {
        final avgScored = totalScored / gameCount;
        final avgConceded = totalConceded / gameCount;
        final ptDiff = avgScored - avgConceded;
        final scoredStr = avgScored.toStringAsFixed(1);
        final concededStr = avgConceded.toStringAsFixed(1);
        String ptBody; String ptTitle;
        if (ptDiff >= 5) {
          ptTitle = "Points Dominant";
          ptBody = "You average $scoredStr points scored vs $concededStr conceded per game. You are controlling the points consistently — your game is in a strong place.";
        } else if (ptDiff >= 2) {
          ptTitle = "Competitive Edge";
          ptBody = "You average $scoredStr points scored vs $concededStr conceded per game. You have a small edge — maintaining consistency in key moments can turn this into more wins.";
        } else if (ptDiff >= -1) {
          ptTitle = "Tight Matches";
          ptBody = "You average $scoredStr points scored vs $concededStr conceded per game. Matches are very close — small moments are deciding the outcome.";
        } else if (ptDiff >= -4) {
          ptTitle = "Slightly Behind";
          ptBody = "You average $scoredStr points scored vs $concededStr conceded per game. Opponents have a slight edge — tightening key areas could help close the gap.";
        } else {
          ptTitle = "Points Gap";
          ptBody = "You average $scoredStr points scored vs $concededStr conceded per game. There is a clear gap — focusing on reducing errors and building consistency could help improve results.";
        }
        if (ptDiff.abs() >= 2) insights.add({"icon": "📊", "title": ptTitle, "body": ptBody, "tier": "premium"});
      }
    }

    // ── Playing Style (premium) ──
    if (completed.length >= 3) {
      final g1WonCount = completed.where((m) => m.g1Player > m.g1Opponent).length;
      final g1StyleRate = g1WonCount / completed.length;
      final g1StylePct = (g1StyleRate * 100).round();
      String styleBody; String styleTitle;
      if (g1StyleRate >= 0.6) {
        styleTitle = "Aggressive Starter";
        styleBody = "Based on your match data, you tend to start strongly — winning $g1StylePct% of first games. You set the tone early and apply pressure from the start. Maintaining that level across the match will be key.";
      } else if (g1StyleRate >= 0.4) {
        styleTitle = "Balanced Player";
        styleBody = "Based on your match data, you have a balanced start — winning $g1StylePct% of first games. Matches are often shaped by how you perform in the middle and later stages.";
      } else {
        styleTitle = "Slow Builder";
        styleBody = "Based on your match data, you tend to start slowly — winning $g1StylePct% of first games. Falling behind early can put you under pressure, so improving your opening game could make a difference.";
      }
      insights.add({"icon": "🧬", "title": styleTitle, "body": styleBody, "tier": "premium"});
    }

    // ── Game-by-Game Breakdown (premium) ──
    if (completed.length >= 5) {
      final g1Won = completed.where((m) => m.g1Player > m.g1Opponent).length;
      final g2Won = completed.where((m) => m.g2Player > m.g2Opponent).length;
      final g3PlayedList = completed.where((m) => m.g3Player > 0 || m.g3Opponent > 0).toList();
      final g3WonCount = g3PlayedList.where((m) => m.g3Player > m.g3Opponent).length;
      final g1Pct = (g1Won / completed.length * 100).round();
      final g2Pct = (g2Won / completed.length * 100).round();
      final g3Pct = g3PlayedList.isNotEmpty ? (g3WonCount / g3PlayedList.length * 100).round() : null;
      final g3Str = g3Pct != null ? "$g3Pct%" : "N/A";
      String primaryLine = "Across your matches, you win $g1Pct% of first games, $g2Pct% of second games, and $g3Str of third games (${g3PlayedList.length} played).";
      // Identify weakest and strongest — prioritise weakest
      String contextLine = "";
      final rates = {"G1": g1Pct, "G2": g2Pct};
      if (g3PlayedList.length >= 3 && g3Pct != null) rates["G3"] = g3Pct;
      final weakest = rates.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
      final strongest = rates.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      if (weakest == "G1") contextLine = "Your opening game is your weakest area — improving your start could have a big impact.";
      else if (weakest == "G3") contextLine = "Deciding games are proving the most challenging — focusing on fitness and concentration in the final game could help.";
      else if (strongest == "G1") contextLine = "You start strongly — maintaining that level across the match could improve your results.";
      else if (strongest == "G2") contextLine = "You tend to grow into matches — your second game is your strongest.";
      else if (strongest == "G3") contextLine = "You finish strongly when matches go the distance — a good sign of resilience under pressure.";
      insights.add({"icon": "🎯", "title": "Game-by-Game Breakdown", "body": "$primaryLine $contextLine".trim(), "tier": "premium"});
    }

    return insights;
  }

  Widget _buildInsightCard(Map<String, dynamic> insight, bool isLocked) {
    final tier = insight["tier"] as String;
    final isGettingStarted = insight["title"] == "Getting Started";
    final Color accentColor = tier == "premium" ? const Color(0xFF7B2FBE) : tier == "pro" ? const Color(0xFFD4A017) : FlutterFlowTheme.of(context).primary;
    final progress = insight["progress"] as int? ?? 0;
    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(insight["icon"] as String, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(child: Text(insight["title"] as String, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: accentColor))),
          if (isLocked) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(10)),
            child: Text(tier == "premium" ? "PREMIUM" : "PRO", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(insight["body"] as String, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
        if (isGettingStarted) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / 5,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            )),
            const SizedBox(width: 10),
            Text("$progress / 5", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: accentColor)),
          ]),
          const SizedBox(height: 4),
          Text("Your AI coach unlocks after 5 matches", style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => context.goNamed(PremiumWidget.routeName),
            style: ElevatedButton.styleFrom(backgroundColor: accentColor, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text("Start building my coaching report", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          )),
        ],
        if (isLocked && !isGettingStarted) ...[
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => context.goNamed(PremiumWidget.routeName),
            style: ElevatedButton.styleFrom(backgroundColor: accentColor, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text(tier == "premium" ? "Unlock Premium" : "Unlock Pro", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          )),
        ],
      ]),
    );
    if (!isLocked) return card;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(children: [
        ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: card),
        Positioned.fill(child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)))),
      ]),
    );
  }

  Widget _buildBlurredPreviewBanner(Map<String, String> insights, int matchCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF1a0a2e), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("See exactly why you win and lose", style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              matchCount >= 5
                  ? "Based on your ${matchCount} ${matchCount == 1 ? 'match' : 'matches'}"
                  : "AI-powered coaching based on your real match data",
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
          ]),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
          child: Stack(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                const Icon(Icons.lock, size: 14, color: Color(0xFFD4A017)),
                const SizedBox(width: 8),
                Expanded(child: Text(matchCount >= 5 ? insights["slowStart"]! : "Your first performance insight will appear soon", style: const TextStyle(fontSize: 13, color: Colors.white), maxLines: 1, overflow: TextOverflow.clip)),
              ]),
            ),
            Positioned(right: 0, top: 0, bottom: 0, width: 110,
              child: Container(decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, Color(0xFF1a0a2e)]),
                borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
              )),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              const Icon(Icons.lock, size: 14, color: Color(0xFFD4A017)),
              const SizedBox(width: 8),
              Text(insights["tiredStat"]!, style: const TextStyle(fontSize: 13, color: Colors.white)),
            ]),
          )),
        )),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              const Icon(Icons.lock, size: 14, color: Color(0xFFD4A017)),
              const SizedBox(width: 8),
              Text(insights["ledLost"]!, style: const TextStyle(fontSize: 13, color: Colors.white)),
            ]),
          )),
        )),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text("Most players never realise this about their game", style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11, fontStyle: FontStyle.italic)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            matchCount >= 5
                ? "Your coaching report is ready"
                : "Play ${5 - matchCount} more ${(5 - matchCount) == 1 ? 'match' : 'matches'} to unlock your first coaching report",
            style: TextStyle(
              color: matchCount >= 5 ? const Color(0xFFD4A017) : Colors.white.withOpacity(0.55),
              fontSize: 13,
              fontWeight: matchCount >= 5 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: ElevatedButton(
            onPressed: () => context.goNamed(PremiumWidget.routeName),
            style: ElevatedButton.styleFrom(
              backgroundColor: matchCount >= 5 ? const Color(0xFF7B2FBE) : const Color(0xFF3d1a6e),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              matchCount >= 5 ? "Get my coaching report" : "Unlock your coaching report",
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = FlutterFlowTheme.of(context).primary;
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: primary,
        automaticallyImplyLeading: false,
        leading: IconButton(icon: const Icon(Icons.home, color: Colors.white), onPressed: () => context.goNamed(HomePageWidget.routeName)),
        title: Text("AI Coach", style: GoogleFonts.interTight(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        elevation: 2.0,
      ),
      body: SafeArea(
        top: true,
        child: _loadingStatus
            ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primary)))
            : StreamBuilder<List<MatchesRecord>>(
                stream: queryMatchesRecord(queryBuilder: (q) => q.where("ownerUid", isEqualTo: currentUserUid).orderBy("matchDate", descending: true)),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primary)));
                  final matches = snapshot.data!;
                  final completed = matches.where((m) => _matchWinner(m) != null).toList();
                  final insights = _generateInsights(matches);
                  final blurredInsights = _computeBlurredInsights(completed);
                  if (completed.isEmpty) {
                    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.psychology, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("No insights yet", style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text("Complete some matches to get AI coaching insights", style: TextStyle(fontSize: 14, color: Colors.grey.shade400), textAlign: TextAlign.center),
                    ]));
                  }
                  final freeInsights = insights.where((i) => i["tier"] == "free").toList();
                  final proInsights = insights.where((i) => i["tier"] == "pro").toList();
                  final premiumInsights = insights.where((i) => i["tier"] == "premium").toList();
                  final isFree = _tier == "free";
                  final isPremium = _tier == "premium";
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [primary, primary.withOpacity(0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(children: [
                          const Text("🤖", style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("Your Personal Coach", style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text("Based on ${completed.length} ${completed.length == 1 ? 'match' : 'matches'} analysed", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                            child: Text(isPremium ? "✨ Premium" : _tier == "pro" ? "⭐ Pro" : "Starter", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      if (isFree) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: primary.withOpacity(0.2)),
                          ),
                          child: Row(children: [
                            Icon(Icons.info_outline, color: primary, size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                                  children: [
                                    const TextSpan(text: 'You have access to '),
                                    TextSpan(text: '5 free insights', style: TextStyle(fontWeight: FontWeight.w700, color: primary)),
                                    const TextSpan(text: '. Upgrade to Pro to unlock 13 personalised insights.'),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ],
                      ...freeInsights.map((i) => _buildInsightCard(i, false)),
                      if (proInsights.isNotEmpty) ...[const SizedBox(height: 4), ...proInsights.map((i) => _buildInsightCard(i, isFree))],
                      if (premiumInsights.isNotEmpty) ...[const SizedBox(height: 4), ...premiumInsights.map((i) => _buildInsightCard(i, !isPremium))],
                      if (isFree) ...[const SizedBox(height: 8), _buildBlurredPreviewBanner(blurredInsights, completed.length)],
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
