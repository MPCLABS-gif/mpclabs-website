import re

def flexible_replace(text, old, new, label):
    tokens = old.split()
    pattern = r'\s+'.join(re.escape(t) for t in tokens)
    matches = list(re.finditer(pattern, text))
    assert len(matches) == 1, f"{label}: found {len(matches)} matches, expected 1"
    m = matches[0]
    return text[:m.start()] + new + text[m.end():]

path = "lib/auth/firebase_auth/email_auth.dart"
with open(path, "r", encoding="utf-8") as f:
    text = f.read()

old1 = '''Future<UserCredential?> registerWithEmail({
  required String name,
  required String email,
  required String password,
  String accountType = 'player',
}) async {
  final credential = await FirebaseAuth.instance
      .createUserWithEmailAndPassword(email: email, password: password);
  final user = credential.user;'''
new1 = '''Future<UserCredential?> registerWithEmail({
  required String name,
  required String email,
  required String password,
  String accountType = 'player',
}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  final UserCredential credential;
  if (currentUser != null && currentUser.isAnonymous) {
    // Upgrade the existing anonymous session in place so matches/tournaments
    // already logged under this UID (ownerUid) aren't orphaned.
    final emailCredential = EmailAuthProvider.credential(email: email, password: password);
    credential = await currentUser.linkWithCredential(emailCredential);
  } else {
    credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
  }
  final user = credential.user;'''
text = flexible_replace(text, old1, new1, "registerWithEmail anonymous upgrade")

with open(path, "w", encoding="utf-8") as f:
    f.write(text)

print("Fix applied successfully.")
