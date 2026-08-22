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

old1 = '''final gameClauses = <String>["$g1Pct% of first games"];
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
      insights.add({"icon": "🎯", "title": "Game-by-Game Breakdown", "body": primaryLine, "tier": "premium"});'''
new1 = '''final gameClauses = <String>["$g1Pct% of first games"];
      if (g2Pct != null) gameClauses.add("$g2Pct% of second games");
      if (g3Pct != null) gameClauses.add("$g3Pct% of third games");
      // Comparison across stages of a match only makes sense with at least two game positions.
      if (gameClauses.length >= 2) {
        String primaryLine;
        if (gameClauses.length == 2) {
          primaryLine = "Across your matches, you win ${gameClauses[0]} and ${gameClauses[1]}.";
        } else {
          primaryLine = "Across your matches, you win ${gameClauses[0]}, ${gameClauses[1]}, and ${gameClauses[2]}.";
        }
        insights.add({"icon": "🎯", "title": "Game-by-Game Breakdown", "body": primaryLine, "tier": "premium"});
      }'''
text = flexible_replace(text, old1, new1, "Game-by-Game Breakdown require 2+ game positions")

with open(path, "w", encoding="utf-8") as f:
    f.write(text)

print("Edit applied successfully.")
