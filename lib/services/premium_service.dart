import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';

class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();


  // Product ID constants
  static const String proMonthlyId = 'pro_monthly';
  static const String proYearlyId = 'pro_yearly';
  static const String premiumMonthlyId = 'premium_monthly';
  static const String premiumYearlyId = 'premium_yearly';

  // Alias for getSubscriptionStatus
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    return await getPremiumStatus();
  }

  // Generate a unique referral code
  String generateReferralCode(String uid) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final suffix = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return 'MPC$suffix';
  }

  // Track daily app open
  Future<void> trackDailyOpen() async {
    if (currentUserUid.isEmpty) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(currentUserUid);
    final doc = await ref.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final lastOpen = data['lastOpenDate'] as Timestamp?;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastStr = lastOpen != null
        ? '${lastOpen.toDate().year}-${lastOpen.toDate().month}-${lastOpen.toDate().day}'
        : '';

    if (todayStr == lastStr) return; // Already tracked today

    int daysActive = (data['daysActive'] as int? ?? 0) + 1;
    bool trialUnlocked = data['trialUnlocked'] as bool? ?? false;
    String referralCode = data['referralCode'] as String? ?? '';

    // Generate referral code if not exists
    if (referralCode.isEmpty) {
      referralCode = generateReferralCode(currentUserUid);
    }

    // Unlock trial after 5 days
    if (daysActive >= 5 && !trialUnlocked) {
      trialUnlocked = true;
      await ref.update({
        'daysActive': daysActive,
        'lastOpenDate': Timestamp.now(),
        'trialUnlocked': true,
        'trialStartDate': Timestamp.now(),
        'referralCode': referralCode,
      });
      return;
    }

    await ref.update({
      'daysActive': daysActive,
      'lastOpenDate': Timestamp.now(),
      'referralCode': referralCode,
    });
  }

  // Check if user has active premium/trial
  Future<Map<String, dynamic>> getPremiumStatus() async {
    if (currentUserUid.isEmpty) return {'isPremium': false, 'daysLeft': 0, 'status': 'free'};

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .get();

    if (!doc.exists) return {'isPremium': false, 'daysLeft': 0, 'status': 'free'};

    final data = doc.data()!;
    final isPremium = data['isPremium'] as bool? ?? false;
    final trialUnlocked = data['trialUnlocked'] as bool? ?? false;
    final trialStartDate = data['trialStartDate'] as Timestamp?;
    final premiumDaysEarned = data['premiumDaysEarned'] as int? ?? 0;
    final daysActive = data['daysActive'] as int? ?? 0;

    // Paid premium
    if (isPremium) {
      final expiry = data['premiumExpiry'] as Timestamp?;
      if (expiry != null && expiry.toDate().isAfter(DateTime.now())) {
        final daysLeft = expiry.toDate().difference(DateTime.now()).inDays;
        return {'isPremium': true, 'daysLeft': daysLeft, 'status': 'premium'};
      }
    }

    // Trial active
    if (trialUnlocked && trialStartDate != null) {
      final totalDays = 7 + premiumDaysEarned;
      final daysUsed = DateTime.now().difference(trialStartDate.toDate()).inDays;
      final daysLeft = totalDays - daysUsed;
      if (daysLeft > 0) {
        return {'isPremium': true, 'daysLeft': daysLeft, 'status': 'trial', 'totalDays': totalDays};
      }
    }

    // Not yet unlocked
    if (!trialUnlocked) {
      final daysNeeded = 5 - daysActive;
      return {'isPremium': false, 'daysLeft': 0, 'status': 'locked', 'daysNeeded': daysNeeded > 0 ? daysNeeded : 0};
    }

    return {'isPremium': false, 'daysLeft': 0, 'status': 'expired'};
  }

  // Create ambassador/discount code (admin only - call from Firebase console)
  // Example codes to create in Firebase 'discount_codes' collection:
  // { code: 'FAMILY25', type: 'discount', discountPercent: 25, maxUses: 1, active: true }
  // { code: 'EARLYBIRD', type: 'discount', discountPercent: 50, maxUses: 100, active: true }
  // { code: 'MARCUS365', type: 'ambassador', days: 365, maxUses: 1, active: true }
  // { code: 'CLUB2026', type: 'club', days: 30, maxUses: 999, active: true }

  // Apply any code (ambassador, discount, referral)
  Future<Map<String, dynamic>> applyAnyCode(String code) async {
    if (currentUserUid.isEmpty) return {'success': false, 'message': 'Not logged in'};
    if (code.isEmpty) return {'success': false, 'message': 'Please enter a code'};

    final upperCode = code.toUpperCase();

    // Check ambassador codes first
    final ambassadorQuery = await FirebaseFirestore.instance
        .collection('ambassador_codes')
        .where('code', isEqualTo: upperCode)
        .where('active', isEqualTo: true)
        .get();

    if (ambassadorQuery.docs.isNotEmpty) {
      final result = await applyAmbassadorCode(upperCode);
      if (result.startsWith('success')) {
        final days = int.parse(result.split(':')[1]);
        return {'success': true, 'type': 'ambassador', 'days': days, 'message': 'You unlocked $days days of Premium!'};
      }
      return {'success': false, 'message': result};
    }

    // Check discount codes
    final discountQuery = await FirebaseFirestore.instance
        .collection('discount_codes')
        .where('code', isEqualTo: upperCode)
        .where('active', isEqualTo: true)
        .get();

    if (discountQuery.docs.isNotEmpty) {
      final codeDoc = discountQuery.docs.first;
      final codeData = codeDoc.data();
      final maxUses = codeData['maxUses'] as int? ?? 1;
      final usedCount = codeData['usedCount'] as int? ?? 0;
      final type = codeData['type'] as String? ?? 'discount';
      final discountPercent = codeData['discountPercent'] as int? ?? 25;
      final days = codeData['days'] as int? ?? 30;

      if (usedCount >= maxUses) {
        return {'success': false, 'message': 'This code has expired or reached maximum uses'};
      }

      // Check if user already used this code
      final myDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .get();

      final usedCodes = List<String>.from(myDoc.data()?['usedCodes'] ?? []);
      if (usedCodes.contains(upperCode)) {
        return {'success': false, 'message': 'You have already used this code'};
      }

      if (type == 'free_days' || type == 'ambassador' || type == 'club') {
        // Grant free premium days
        final expiry = DateTime.now().add(Duration(days: days));
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .update({
          'isPremium': true,
          'premiumExpiry': Timestamp.fromDate(expiry),
          'trialUnlocked': true,
          'usedCodes': FieldValue.arrayUnion([upperCode]),
        });
        await codeDoc.reference.update({
          'usedCount': usedCount + 1,
          'usedBy': FieldValue.arrayUnion([currentUserUid]),
        });
        return {'success': true, 'type': type, 'days': days, 'message': 'You unlocked $days days of Premium!'};
      } else {
        // Discount code — save for use at checkout
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .update({
          'pendingDiscountCode': upperCode,
          'pendingDiscountPercent': discountPercent,
          'usedCodes': FieldValue.arrayUnion([upperCode]),
        });
        await codeDoc.reference.update({
          'usedCount': usedCount + 1,
          'usedBy': FieldValue.arrayUnion([currentUserUid]),
        });
        return {'success': true, 'type': 'discount', 'discount': discountPercent, 'message': '$discountPercent% discount applied! Valid for your next subscription.'};
      }
    }

    // Check referral codes
    final referralResult = await applyReferralCode(upperCode);
    if (referralResult == 'success') {
      return {'success': true, 'type': 'referral', 'message': 'Referral code applied! You unlocked 10 bonus Premium days!'};
    }

    return {'success': false, 'message': 'Invalid code. Please check and try again.'};
  }

  // Apply ambassador code (gives 365 days)
  Future<String> applyAmbassadorCode(String code) async {
    if (currentUserUid.isEmpty) return 'Not logged in';
    if (code.isEmpty) return 'Please enter a code';

    // Check ambassador codes collection
    final query = await FirebaseFirestore.instance
        .collection('ambassador_codes')
        .where('code', isEqualTo: code.toUpperCase())
        .where('active', isEqualTo: true)
        .get();

    if (query.docs.isEmpty) return 'invalid';

    final codeDoc = query.docs.first;
    final codeData = codeDoc.data();
    final daysGranted = codeData['days'] as int? ?? 365;
    final maxUses = codeData['maxUses'] as int? ?? 1;
    final usedCount = codeData['usedCount'] as int? ?? 0;

    if (usedCount >= maxUses) return 'This code has reached its maximum uses';

    // Check if user already used an ambassador code
    final myDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .get();

    if (myDoc.data()?['ambassadorCode'] != null &&
        myDoc.data()!['ambassadorCode'].toString().isNotEmpty) {
      return 'You have already used an ambassador code';
    }

    // Grant premium access
    final expiry = DateTime.now().add(Duration(days: daysGranted));
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .update({
      'isPremium': true,
      'premiumExpiry': Timestamp.fromDate(expiry),
      'ambassadorCode': code.toUpperCase(),
      'trialUnlocked': true,
    });

    // Update code usage count
    await codeDoc.reference.update({
      'usedCount': usedCount + 1,
      'usedBy': FieldValue.arrayUnion([currentUserUid]),
    });

    return 'success:$daysGranted';
  }

  // Apply referral code
  Future<String> applyReferralCode(String code) async {
    if (currentUserUid.isEmpty) return 'Not logged in';
    if (code.isEmpty) return 'Please enter a code';

    // Find user with this referral code
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('referralCode', isEqualTo: code.toUpperCase())
        .get();

    if (query.docs.isEmpty) return 'Invalid referral code';

    final referrerDoc = query.docs.first;
    if (referrerDoc.id == currentUserUid) return 'You cannot use your own code';

    // Check if already used a referral code
    final myDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .get();

    if (myDoc.data()?['referredBy'] != null && myDoc.data()!['referredBy'].toString().isNotEmpty) {
      return 'You have already used a referral code';
    }

    // Give referrer +10 days
    final referrerDaysEarned = (referrerDoc.data()['premiumDaysEarned'] as int? ?? 0) + 10;
    final referrerCount = (referrerDoc.data()['referralCount'] as int? ?? 0) + 1;
    await referrerDoc.reference.update({
      'premiumDaysEarned': referrerDaysEarned,
      'referralCount': referrerCount,
    });

    // Give new user referral bonus (start trial immediately)
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .update({
      'referredBy': code.toUpperCase(),
      'trialUnlocked': true,
      'trialStartDate': Timestamp.now(),
      'premiumDaysEarned': 10,
    });

    return 'success';
  }
}
