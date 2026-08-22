import re

def flexible_replace(text, old, new, label):
    tokens = old.split()
    pattern = r'\s+'.join(re.escape(t) for t in tokens)
    matches = list(re.finditer(pattern, text))
    assert len(matches) == 1, f"{label}: found {len(matches)} matches, expected 1"
    m = matches[0]
    return text[:m.start()] + new + text[m.end():]

path = "lib/ai_coach/ai_coach_widget.dart"
with open(path, "r", encoding="utf-8") as f:
    text = f.read()

# 1. Game-by-Game Breakdown: fix Game 2 denominator (mirror Game 3), build sentence dynamically
old1 = '''// ── Game-by-Game Breakdown (premium) ──
    if (completed.length >= 5) {
      final g1Won = completed.where((m) => m.g1Player > m.g1Opponent).length;
      final g2Won = completed.where((m) => m.g2Player > m.g2Opponent).length;
      final g3PlayedList = completed.where((m) => m.g3Player > 0 || m.g3Opponent > 0).toList();
      final g3WonCount = g3PlayedList.where((m) => m.g3Player > m.g3Opponent).length;
      final g1Pct = (g1Won / completed.length * 100).round();
      final g2Pct = (g2Won / completed.length * 100).round();
      final g3Pct = g3PlayedList.isNotEmpty ? (g3WonCount / g3PlayedList.length * 100).round() : null;
      final g3Str = g3Pct != null ? "$g3Pct%" : "N/A";
      final primaryLine = "Across your matches, you win $g1Pct% of first games, $g2Pct% of second games, and $g3Str of third games (${g3PlayedList.length} played).";
      insights.add({"icon": "🎯", "title": "Game-by-Game Breakdown", "body": primaryLine, "tier": "premium"});
    }'''
new1 = '''// ── Game-by-Game Breakdown (premium) ──
    if (completed.length >= 5) {
      final g1Won = completed.where((m) => m.g1Player > m.g1Opponent).length;
      final g1Pct = (g1Won / completed.length * 100).round();
      final g2PlayedList = completed.where((m) => m.g2Player > 0 || m.g2Opponent > 0).toList();
      final g2WonCount = g2PlayedList.where((m) => m.g2Player > m.g2Opponent).length;
      final g2Pct = g2PlayedList.isNotEmpty ? (g2WonCount / g2PlayedList.length * 100).round() : null;
      final g3PlayedList = completed.where((m) => m.g3Player > 0 || m.g3Opponent > 0).toList();
      final g3WonCount = g3PlayedList.where((m) => m.g3Player > m.g3Opponent).length;
      final g3Pct = g3PlayedList.isNotEmpty ? (g3WonCount / g3PlayedList.length * 100).round() : null;
      final gameClauses = <String>["$g1Pct% of first games"];
      if (g2Pct != null) gameClauses.add("$g2Pct% of second games");
      if (g3Pct != null) gameClauses.add("$g3Pct% of third games");
      String primaryLine;
      if (gameClauses.length == 1) {
        primaryLine = "Across your matches, you win ${gameClauses[0]}.";
      } else if (gameClauses.length == 2) {
        primaryLine = "Across your matches, you win ${gameClauses[0]} and ${gameClauses[1]}.";
      } else {
        primaryLine = "Across your matches, you win ${gameClauses[0]}, ${gameClauses[1]}, and ${gameClauses[2]}.";
      }
      insights.add({"icon": "🎯", "title": "Game-by-Game Breakdown", "body": primaryLine, "tier": "premium"});
    }'''
text = flexible_replace(text, old1, new1, "Game-by-Game Breakdown G2 fix")

# 2. Suppress standalone First Game Results when Performance Focus/Positive Pattern selects the first-game candidate
old2 = '''Map<String, dynamic>? focusCandidate;
      if (focusCandidate == null && closeRateF != null && closeRateF < 0.35) {
        final pct = (closeRateF * 100).round();
        focusCandidate = {"icon": "🎯", "title": "Performance Focus", "body": "You have won $pct% of your close games (decided by 3 points or fewer), based on $closeGamesTotalF such games. That's a pattern worth exploring — what could help you feel clearer and more decisive in those tight moments?", "tier": "free"};
      }
      if (focusCandidate == null && comebackRateF != null && comebackRateF < 0.3) {
        final pct = (comebackRateF * 100).round();
        focusCandidate = {"icon": "🎯", "title": "Performance Focus", "body": "After losing Game 1, you have won $pct% of those matches (${lostG1F.length} qualifying). That's worth exploring — what helps you reset and start Game 2 with a clear plan?", "tier": "free"};
      }
      if (focusCandidate == null && firstGameRateF != null && firstGameRateF < 0.4) {
        final pct = (firstGameRateF * 100).round();
        focusCandidate = {"icon": "🎯", "title": "Performance Focus", "body": "You have won $pct% of your first games across ${completed.length} matches. That's a pattern worth exploring — what could help you feel sharper from the very first point?", "tier": "free"};
      }
      Map<String, dynamic>? positiveCandidate;
      if (positiveCandidate == null && closeRateF != null && closeRateF >= 0.6) {
        final pct = (closeRateF * 100).round();
        positiveCandidate = {"icon": "⭐", "title": "Positive Pattern", "body": "You have won $pct% of your close games (decided by 3 points or fewer), based on $closeGamesTotalF such games. That's a positive pattern — you're finding ways to come through when matches get tight.", "tier": "free"};
      }
      if (positiveCandidate == null && comebackRateF != null && comebackRateF >= 0.5) {
        final pct = (comebackRateF * 100).round();
        positiveCandidate = {"icon": "⭐", "title": "Positive Pattern", "body": "After losing Game 1, you have recovered to win $pct% of those matches (${lostG1F.length} qualifying). That's a positive pattern — worth noticing what helps you reset and respond.", "tier": "free"};
      }
      if (positiveCandidate == null && firstGameRateF != null && firstGameRateF >= 0.6) {
        final pct = (firstGameRateF * 100).round();
        positiveCandidate = {"icon": "⭐", "title": "Positive Pattern", "body": "You have won $pct% of your first games across ${completed.length} matches. That's a positive pattern — worth noticing what helps you start matches well.", "tier": "free"};
      }
      final frontInsights = <Map<String, dynamic>>[];
      if (focusCandidate != null) frontInsights.add(focusCandidate);
      if (positiveCandidate != null) frontInsights.add(positiveCandidate);
      for (int i = frontInsights.length - 1; i >= 0; i--) {
        insights.insert(0, frontInsights[i]);
      }'''
new2 = '''Map<String, dynamic>? focusCandidate;
      bool focusIsFirstGame = false;
      if (focusCandidate == null && closeRateF != null && closeRateF < 0.35) {
        final pct = (closeRateF * 100).round();
        focusCandidate = {"icon": "🎯", "title": "Performance Focus", "body": "You have won $pct% of your close games (decided by 3 points or fewer), based on $closeGamesTotalF such games. That's a pattern worth exploring — what could help you feel clearer and more decisive in those tight moments?", "tier": "free"};
      }
      if (focusCandidate == null && comebackRateF != null && comebackRateF < 0.3) {
        final pct = (comebackRateF * 100).round();
        focusCandidate = {"icon": "🎯", "title": "Performance Focus", "body": "After losing Game 1, you have won $pct% of those matches (${lostG1F.length} qualifying). That's worth exploring — what helps you reset and start Game 2 with a clear plan?", "tier": "free"};
      }
      if (focusCandidate == null && firstGameRateF != null && firstGameRateF < 0.4) {
        final pct = (firstGameRateF * 100).round();
        focusCandidate = {"icon": "🎯", "title": "Performance Focus", "body": "You have won $pct% of your first games across ${completed.length} matches. That's a pattern worth exploring — what could help you feel sharper from the very first point?", "tier": "free"};
        focusIsFirstGame = true;
      }
      Map<String, dynamic>? positiveCandidate;
      bool positiveIsFirstGame = false;
      if (positiveCandidate == null && closeRateF != null && closeRateF >= 0.6) {
        final pct = (closeRateF * 100).round();
        positiveCandidate = {"icon": "⭐", "title": "Positive Pattern", "body": "You have won $pct% of your close games (decided by 3 points or fewer), based on $closeGamesTotalF such games. That's a positive pattern — you're finding ways to come through when matches get tight.", "tier": "free"};
      }
      if (positiveCandidate == null && comebackRateF != null && comebackRateF >= 0.5) {
        final pct = (comebackRateF * 100).round();
        positiveCandidate = {"icon": "⭐", "title": "Positive Pattern", "body": "After losing Game 1, you have recovered to win $pct% of those matches (${lostG1F.length} qualifying). That's a positive pattern — worth noticing what helps you reset and respond.", "tier": "free"};
      }
      if (positiveCandidate == null && firstGameRateF != null && firstGameRateF >= 0.6) {
        final pct = (firstGameRateF * 100).round();
        positiveCandidate = {"icon": "⭐", "title": "Positive Pattern", "body": "You have won $pct% of your first games across ${completed.length} matches. That's a positive pattern — worth noticing what helps you start matches well.", "tier": "free"};
        positiveIsFirstGame = true;
      }
      if (focusIsFirstGame || positiveIsFirstGame) {
        insights.removeWhere((i) => i["title"] == "First Game Results");
      }
      final frontInsights = <Map<String, dynamic>>[];
      if (focusCandidate != null) frontInsights.add(focusCandidate);
      if (positiveCandidate != null) frontInsights.add(positiveCandidate);
      for (int i = frontInsights.length - 1; i >= 0; i--) {
        insights.insert(0, frontInsights[i]);
      }'''
text = flexible_replace(text, old2, new2, "Suppress First Game Results duplicate")

with open(path, "w", encoding="utf-8") as f:
    f.write(text)

print("Both edits applied successfully.")
