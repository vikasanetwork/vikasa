import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/decimal_utils.dart';

class ClaimPage extends StatefulWidget {
  const ClaimPage({super.key});

  @override
  State<ClaimPage> createState() => _ClaimPageState();
}

class _ClaimPageState extends State<ClaimPage> {
  static const claimIntervalHours = 3; // server-enforced; client display only
  DateTime _now = DateTime.now().toUtc();
  DateTime? _lastClaimAtUtc;
  Timer? _ticker;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _startTicker();
    _initAdsIfMobile();
    _loadLastClaim();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now().toUtc());
    });
  }

  void _initAdsIfMobile() {
    if (!kIsWeb) {
      MobileAds.instance.initialize();
    }
  }

  Future<void> _loadLastClaim() async {
    try {
      final supa = Supabase.maybeGetInstance();
      final user = supa?.client.auth.currentUser;
      if (supa == null || user == null) return;
      final res = await supa.client
          .from('claims')
          .select('claimed_at')
          .eq('user_id', user.id)
          .order('claimed_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (res != null && res['claimed_at'] != null) {
        setState(() => _lastClaimAtUtc = DateTime.parse(res['claimed_at']).toUtc());
      }
    } catch (_) {
      // ignore
    }
  }

  DateTime? get _nextEligibleAtUtc {
    if (_lastClaimAtUtc == null) return null;
    return _lastClaimAtUtc!.add(const Duration(hours: claimIntervalHours));
  }

  Duration? get _timeLeft {
    final next = _nextEligibleAtUtc;
    if (next == null) return null;
    final d = next.difference(_now);
    return d.isNegative ? Duration.zero : d;
  }

  bool get _isEligible {
    final tl = _timeLeft;
    return tl == null || tl == Duration.zero;
  }

  Future<void> _onClaimPressed() async {
    if (kIsWeb) {
      _showSnack('Claims are mobile-only for now.');
      return;
    }
    final supa = Supabase.maybeGetInstance();
    final user = supa?.client.auth.currentUser;
    if (supa == null || user == null) {
      _showSnack('Please log in to claim.');
      return;
    }
    if (!_isEligible) {
      _showSnack('Not eligible yet.');
      return;
    }

    setState(() => _busy = true);
    try {
      final rewarded = await _showRewardedAd();
      if (!rewarded) {
        _showSnack('Ad not completed.');
        return;
      }
      final receipt = 'mvp-${DateTime.now().millisecondsSinceEpoch}';
      final resp = await supa.client.functions.invoke(
        'claim_ad_validate_and_credit',
        body: {
          'user_id': user.id,
          'ad_receipt_id': receipt,
        },
      );

      if (resp.data != null && resp.data['ok'] == true) {
        final unlockAt = DateTime.parse(resp.data['unlock_at']).toUtc();
        final amount = resp.data['amount'] as String? ?? '0.00000000';
        setState(() => _lastClaimAtUtc = DateTime.now().toUtc());
        _showSnack('Claimed ${formatDecimalString(amount, precision: 8)} VIK. Unlocks at ${unlockAt.toIso8601String()}');
      } else if (resp.data != null && resp.data['error'] == 'not_eligible_yet') {
        final nextAt = DateTime.parse(resp.data['next_at']).toUtc();
        setState(() => _lastClaimAtUtc = nextAt.subtract(const Duration(hours: claimIntervalHours)));
        _showSnack('Not eligible yet. Next at ${nextAt.toIso8601String()}');
      } else {
        _showSnack('Claim failed.');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _showRewardedAd() async {
    final completer = Completer<bool>();
    RewardedAd.load(
      adUnitId: _testAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show(onUserEarnedReward: (ad, reward) {
            if (!completer.isCompleted) completer.complete(true);
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future.timeout(const Duration(seconds: 60), onTimeout: () => false);
  }

  String get _testAdUnitId {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return 'ca-app-pub-3940256099942544/5224354917';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tl = _timeLeft;
    final tlStr = _isEligible
        ? 'Ready'
        : '${tl!.inHours.toString().padLeft(2, '0')}:${(tl.inMinutes % 60).toString().padLeft(2, '0')}:${(tl.inSeconds % 60).toString().padLeft(2, '0')}'
            ' (UTC)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('VIKASA'),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                final supa = Supabase.maybeGetInstance();
                await supa?.client.auth.signOut();
              } catch (_) {}
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Date/Time (UTC): ${_now.toIso8601String()}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Next claim in', style: Theme.of(context).textTheme.bodyMedium),
                Text(tlStr, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy ? null : _onClaimPressed,
              child: Text(kIsWeb ? 'Claim (mobile only)' : (_busy ? 'Processing...' : 'Claim')),
            ),
            const SizedBox(height: 16),
            Text('History coming soon', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
