import 'package:firebase_auth/firebase_auth.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/premium_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerProfileWidget extends StatefulWidget {
  const PlayerProfileWidget({super.key});
  static String routeName = 'PlayerProfile';
  static String routePath = '/playerProfile';

  @override
  State<PlayerProfileWidget> createState() => _PlayerProfileWidgetState();
}

class _PlayerProfileWidgetState extends State<PlayerProfileWidget> {
  final _playerNameController = TextEditingController();
  DateTime? _dateOfBirth;

  bool _isUnder13 = false;
  bool _isMinor = false;

  bool _teenConsentGiven = false;

  final _parentNameController = TextEditingController();
  final _parentEmailController = TextEditingController();
  bool _parentConsentGiven = false;

  final _emailController = TextEditingController();
  bool _emailOptIn = false;
  final _clubController = TextEditingController();
  final _levelController = TextEditingController();
  String? _selectedAgeCategory;
  bool _loading = true;
  bool _saving = false;
  String? _currentUid;

  final List<String> _ageCategories = [
    'Under 9',
    'Under 11',
    'Under 13',
    'Under 15',
    'Under 17',
    'Under 19',
    'Senior',
    'Veteran 35+',
    'Veteran 45+',
  ];

  @override
  void initState() {
    super.initState();
    _initWithAuth();
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    _clubController.dispose();
    _levelController.dispose();
    _emailController.dispose();
    _parentNameController.dispose();
    _parentEmailController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) age--;
    return age;
  }

  String _getAgeCategory(DateTime dob) {
    final age = _calculateAge(dob);
    if (age < 9) return 'Under 9';
    if (age < 11) return 'Under 11';
    if (age < 13) return 'Under 13';
    if (age < 15) return 'Under 15';
    if (age < 17) return 'Under 17';
    if (age < 19) return 'Under 19';
    if (age < 35) return 'Senior';
    if (age < 45) return 'Veteran 35+';
    return 'Veteran 45+';
  }

  void _updateAgeFlags(DateTime dob) {
    final age = _calculateAge(dob);
    _isUnder13 = age < 13;
    _isMinor = age >= 13 && age < 18;
  }

  Future<void> _initWithAuth() async {
    // Wait for auth to settle — try all sources
    await Future.delayed(const Duration(milliseconds: 800));
    final uid = currentUserUid.isNotEmpty
        ? currentUserUid
        : FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty && mounted) {
      setState(() => _currentUid = uid);
    }
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    String uid = _currentUid ?? currentUserUid;
    if (uid.isEmpty) uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      _playerNameController.text = data['playerName'] ?? '';
      _clubController.text = data['club'] ?? '';
      _levelController.text = data['level'] ?? '';
      _selectedAgeCategory = data['ageCategory'];
      _emailController.text = data['email'] ?? '';
      _emailOptIn = data['emailOptIn'] ?? false;
      _parentNameController.text = data['parentName'] ?? '';
      _parentEmailController.text = data['parentEmail'] ?? '';
      _parentConsentGiven = data['parentConsentGiven'] ?? false;
      _teenConsentGiven = data['teenConsentGiven'] ?? false;

      final dobTimestamp = data['dateOfBirth'] as dynamic;
      if (dobTimestamp != null) {
        _dateOfBirth = dobTimestamp.toDate();
        _updateAgeFlags(_dateOfBirth!);
      }
    }
    setState(() => _loading = false);
  }

  bool get _canSave {
    if (_isUnder13 && !_parentConsentGiven) return false;
    if (_isMinor && !_teenConsentGiven) return false;
    return true;
  }

  Future<void> _saveProfile() async {
    if (!_canSave) return;
    // Validate required fields
    if (_playerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    if (_levelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your level')),
      );
      return;
    }
    if (_emailOptIn && _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email to receive updates')),
      );
      return;
    }
    // Resolve UID — try every available source
    String? uid = _currentUid;
    print('DEBUG _currentUid: $_currentUid');
    print('DEBUG currentUserUid: $currentUserUid');
    print('DEBUG FirebaseAuth.instance.currentUser?.uid: ${FirebaseAuth.instance.currentUser?.uid}');
    print('DEBUG FirebaseAuth.instance.currentUser?.isAnonymous: ${FirebaseAuth.instance.currentUser?.isAnonymous}');
    if (uid == null || uid.isEmpty) uid = currentUserUid.isNotEmpty ? currentUserUid : null;
    if (uid == null || uid.isEmpty) uid = FirebaseAuth.instance.currentUser?.uid;
    print('DEBUG final uid: $uid');
    if (uid == null || uid.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save — please sign out and sign in again')),
        );
      }
      return;
    }
    setState(() => _saving = true);

    final Map<String, dynamic> profileData = {
      'playerName': _playerNameController.text,
      'club': _clubController.text,
      'level': _levelController.text,
      'ageCategory': _selectedAgeCategory ?? '',
      'dateOfBirth':
          _dateOfBirth != null ? Timestamp.fromDate(_dateOfBirth!) : null,
      'emailOptIn': _emailOptIn,
    };

    if (_isUnder13) {
      profileData['accountManagedBy'] = 'parent';
      profileData['parentName'] = _parentNameController.text;
      profileData['parentEmail'] = _parentEmailController.text;
      profileData['parentConsentGiven'] = _parentConsentGiven;
      if (_parentConsentGiven) {
        profileData['parentConsentTimestamp'] = FieldValue.serverTimestamp();
        profileData['parentConsentVersion'] = '1.0';
      }
      profileData['email'] = _parentEmailController.text;
    } else {
      profileData['accountManagedBy'] = 'self';
      profileData['email'] = _emailController.text;
      if (_isMinor) {
        profileData['teenConsentGiven'] = _teenConsentGiven;
        if (_teenConsentGiven) {
          profileData['teenConsentTimestamp'] = FieldValue.serverTimestamp();
          profileData['teenConsentVersion'] = '1.0';
        }
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(profileData, SetOptions(merge: true));
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully ✅'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = FlutterFlowTheme.of(context).primary;

    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: primary,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () => context.goNamed(HomePageWidget.routeName),
        ),
        title: Text('Player Profile',
            style: GoogleFonts.interTight(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        elevation: 2.0,
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primary)))
          : SafeArea(
              top: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withOpacity(0.1),
                          border: Border.all(
                              color: primary.withOpacity(0.3), width: 2),
                        ),
                        child: Center(
                          child: Text(
                            _playerNameController.text.isNotEmpty
                                ? _playerNameController.text[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _playerNameController.text.isNotEmpty
                          ? _playerNameController.text
                          : 'Your Profile',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text('Player Profile', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 24),

                    _fieldLabel('Player Name'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _playerNameController,
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration(context, 'Your name'),
                    ),
                    const SizedBox(height: 16),

                    _fieldLabel('Club / Academy'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _clubController,
                      decoration: _inputDecoration(
                          context, 'e.g. City Badminton Club'),
                    ),
                    const SizedBox(height: 16),

                    _fieldLabel('Grade / Level'),
                    const SizedBox(height: 6),
                    _dropdownContainer(
                      context,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _levelController.text.isEmpty
                              ? null
                              : _levelController.text,
                          hint: const Text('Select your level'),
                          isExpanded: true,
                          items: [
                            'Beginner',
                            'Intermediate',
                            'Advanced',
                            'Elite',
                            'County',
                            'Regional',
                            'National'
                          ]
                              .map((l) =>
                                  DropdownMenuItem(value: l, child: Text(l)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _levelController.text = val ?? ''),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _fieldLabel('Date of Birth'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateOfBirth ??
                              DateTime.now()
                                  .subtract(const Duration(days: 365 * 12)),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _dateOfBirth = picked;
                            _updateAgeFlags(picked);
                            _selectedAgeCategory = _getAgeCategory(picked);
                            _parentConsentGiven = false;
                            _teenConsentGiven = false;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dateOfBirth != null
                                  ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year} (Age ${_calculateAge(_dateOfBirth!)})'
                                  : 'Select date of birth',
                              style: TextStyle(
                                fontSize: 15,
                                color: _dateOfBirth != null
                                    ? Colors.black
                                    : Colors.grey.shade500,
                              ),
                            ),
                            const Icon(Icons.calendar_today,
                                size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),

                    if (_isUnder13) ...[
                      const SizedBox(height: 12),
                      _parentSetupBlock(context),
                    ],

                    if (_isMinor) ...[
                      const SizedBox(height: 12),
                      _teenConsentBlock(context),
                    ],

                    const SizedBox(height: 16),

                    if (_dateOfBirth != null) ...[
                      _fieldLabel('Age Category (auto-calculated)'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 16, color: Colors.grey.shade400),
                            const SizedBox(width: 8),
                            Text(_selectedAgeCategory ?? '',
                                style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      _fieldLabel('Age Category'),
                      const SizedBox(height: 6),
                      _dropdownContainer(
                        context,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _ageCategories.contains(_selectedAgeCategory)
                                ? _selectedAgeCategory
                                : null,
                            hint: const Text('Select age category'),
                            isExpanded: true,
                            items: _ageCategories
                                .map((cat) => DropdownMenuItem(
                                    value: cat, child: Text(cat)))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedAgeCategory = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (!_isUnder13) ...[
                      _fieldLabel('Email'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration:
                            _inputDecoration(context, 'your@email.com'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _emailOptIn,
                            onChanged: (val) =>
                                setState(() => _emailOptIn = val ?? false),
                            activeColor: primary,
                          ),
                          const Expanded(
                            child: Text(
                              'I\'d like to receive tips and updates by email',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed:
                          (_saving || !_canSave) ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : Text(
                              _canSave
                                  ? 'Save Profile'
                                  : 'Consent required to save',
                              style: GoogleFonts.inter(
                                  color: _canSave
                                      ? Colors.white
                                      : Colors.grey.shade500,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                    ),

                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FlutterFlowTheme.of(context).primary.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🏸 Your journey is in your hands',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: FlutterFlowTheme.of(context).primary)),
                          const SizedBox(height: 4),
                          Text('Every match you play makes you better. Keep tracking, keep improving.',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) context.goNamed(RegisterPage.routeName);
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign Out',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                        foregroundColor: Colors.grey.shade600,
                      ),
                    ),

                    StreamBuilder<List<MatchesRecord>>(
                      stream: queryMatchesRecord(
                        queryBuilder: (q) => q.where('ownerUid',
                            isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? ''),
                      ),
                      builder: (context, snapshot) {
                        final matches = snapshot.data ?? [];
                        int wins = 0;
                        for (final m in matches) {
                          int pg = 0, og = 0;
                          for (final pair in [
                            [m.g1Player, m.g1Opponent],
                            [m.g2Player, m.g2Opponent],
                            [m.g3Player, m.g3Opponent]
                          ]) {
                            if ((pair[0] >= 21 &&
                                    (pair[0] - pair[1]) >= 2) ||
                                pair[0] >= 30) {
                              pg++;
                            } else if ((pair[1] >= 21 &&
                                    (pair[1] - pair[0]) >= 2) ||
                                pair[1] >= 30) {
                              og++;
                            }
                          }
                          if (pg >= 2) wins++;
                        }
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: primary.withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _miniStat(
                                  '${matches.length}', 'Matches', primary),
                              _miniStat('$wins', 'Wins', Colors.green),
                              _miniStat('${matches.length - wins}', 'Losses',
                                  Colors.red),
                              _miniStat(
                                  matches.isEmpty
                                      ? '0%'
                                      : '${((wins / matches.length) * 100).round()}%',
                                  'Win Rate',
                                  Colors.purple),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _parentSetupBlock(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                'Parent / Guardian Setup',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'This player is under 13. A parent or guardian must set up and manage this account.',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _parentNameController,
            decoration: InputDecoration(
              hintText: 'Parent / Guardian full name',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade200),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _parentEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Parent / Guardian email address',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade200),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _parentConsentGiven,
                onChanged: (val) =>
                    setState(() => _parentConsentGiven = val ?? false),
                activeColor: Colors.blue.shade700,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'I am the parent/guardian of this player and consent to creating and managing this account on their behalf.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _teenConsentBlock(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.family_restroom,
                  color: Colors.orange.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                'Parental Awareness',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This account is for a player aged 13–17.',
            style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _teenConsentGiven,
                onChanged: (val) =>
                    setState(() => _teenConsentGiven = val ?? false),
                activeColor: Colors.orange.shade700,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'I confirm I am 13 or over, or have permission from a parent/guardian to use this app.',
                    style:
                        TextStyle(fontSize: 12, color: Colors.orange.shade800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(label,
        style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.grey.shade600));
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
      border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );
  }

  Widget _dropdownContainer(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}
