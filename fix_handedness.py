import re

def flexible_replace(text, old, new, label):
    tokens = old.split()
    pattern = r'\s+'.join(re.escape(t) for t in tokens)
    matches = list(re.finditer(pattern, text))
    assert len(matches) == 1, f"{label}: found {len(matches)} matches, expected 1"
    m = matches[0]
    return text[:m.start()] + new + text[m.end():]

path = "lib/backend/schema/matches_record.dart"
with open(path, "r", encoding="utf-8") as f:
    text = f.read()

# 1. Read side: populate _opponentHandedness from snapshotData in _initializeFields()
old1 = '''_ownerUid = snapshotData['ownerUid'] as String?;
    _playerName = snapshotData['PlayerName'] as String?;
    _opponentName = snapshotData['OpponentName'] as String?;
    _matchDate = snapshotData['matchDate'] as DateTime?;'''
new1 = '''_ownerUid = snapshotData['ownerUid'] as String?;
    _playerName = snapshotData['PlayerName'] as String?;
    _opponentName = snapshotData['OpponentName'] as String?;
    _opponentHandedness = snapshotData['opponentHandedness'] as String?;
    _matchDate = snapshotData['matchDate'] as DateTime?;'''
text = flexible_replace(text, old1, new1, "Read-side opponentHandedness fix")

# 2. Write side: include opponentHandedness in the firestoreData map
old2 = '''      'ownerUid': ownerUid,
      'PlayerName': playerName,
      'OpponentName': opponentName,
      'matchDate': matchDate,'''
new2 = '''      'ownerUid': ownerUid,
      'PlayerName': playerName,
      'OpponentName': opponentName,
      'opponentHandedness': opponentHandedness,
      'matchDate': matchDate,'''
text = flexible_replace(text, old2, new2, "Write-side opponentHandedness fix")

with open(path, "w", encoding="utf-8") as f:
    f.write(text)

print("Both fixes applied successfully.")
