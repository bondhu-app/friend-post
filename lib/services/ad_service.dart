import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;

  // Google official TEST Ad Unit IDs.
  // অ্যাপ publish করার আগে নিজের AdMob ID বসাতে হবে।

  static const String _androidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String _iosInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';

  static const String _androidRewardedId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String _iosRewardedId =
      'ca-app-pub-3940256099942544/1712485313';

  String get _interstitialId {
    if (Platform.isAndroid) {
      return _androidInterstitialId;
    }

    if (Platform.isIOS) {
      return _iosInterstitialId;
    }

    return '';
  }

  String get _rewardedId {
    if (Platform.isAndroid) {
      return _androidRewardedId;
    }

    if (Platform.isIOS) {
      return _iosRewardedId;
    }

    return '';
  }

  /// Initialize Google Mobile Ads.
  Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }

    try {
      await MobileAds.instance.initialize();

      loadInterstitialAd();
      loadRewardedAd();
    } catch (e) {
      debugPrint('AdMob initialize error: $e');
    }
  }

  /// ------------------------------------------------------------
  /// INTERSTITIAL AD
  /// ------------------------------------------------------------

  void loadInterstitialAd() {
    if (kIsWeb) {
      return;
    }

    if (_interstitialAd != null) {
      return;
    }

    if (_loadingInterstitial) {
      return;
    }

    final adUnitId = _interstitialId;

    if (adUnitId.isEmpty) {
      return;
    }

    _loadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _loadingInterstitial = false;
          _interstitialAd = ad;

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdShowedFullScreenContent: (Ad ad) {
              debugPrint('Interstitial ad showed.');
            },
            onAdDismissedFullScreenContent: (Ad ad) {
              debugPrint('Interstitial ad dismissed.');

              ad.dispose();
              _interstitialAd = null;

              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (
              Ad ad,
              AdError error,
            ) {
              debugPrint(
                'Interstitial show failed: ${error.message}',
              );

              ad.dispose();
              _interstitialAd = null;

              loadInterstitialAd();
            },
          );

          debugPrint('Interstitial ad loaded.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _loadingInterstitial = false;
          _interstitialAd = null;

          debugPrint(
            'Interstitial load failed: ${error.message}',
          );
        },
      ),
    );
  }

  Future<bool> showInterstitialAd() async {
    if (kIsWeb) {
      return false;
    }

    final ad = _interstitialAd;

    if (ad == null) {
      loadInterstitialAd();
      return false;
    }

    _interstitialAd = null;

    try {
      await ad.show();
      return true;
    } catch (e) {
      debugPrint(
        'Interstitial show exception: $e',
      );

      ad.dispose();
      loadInterstitialAd();

      return false;
    }
  }

  bool get isInterstitialReady {
    return _interstitialAd != null;
  }

  /// ------------------------------------------------------------
  /// REWARDED AD
  /// ------------------------------------------------------------

  void loadRewardedAd() {
    if (kIsWeb) {
      return;
    }

    if (_rewardedAd != null) {
      return;
    }

    if (_loadingRewarded) {
      return;
    }

    final adUnitId = _rewardedId;

    if (adUnitId.isEmpty) {
      return;
    }

    _loadingRewarded = true;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _loadingRewarded = false;
          _rewardedAd = ad;

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdShowedFullScreenContent: (Ad ad) {
              debugPrint('Rewarded ad showed.');
            },
            onAdDismissedFullScreenContent: (Ad ad) {
              debugPrint('Rewarded ad dismissed.');

              ad.dispose();
              _rewardedAd = null;

              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (
              Ad ad,
              AdError error,
            ) {
              debugPrint(
                'Rewarded show failed: ${error.message}',
              );

              ad.dispose();
              _rewardedAd = null;

              loadRewardedAd();
            },
          );

          debugPrint('Rewarded ad loaded.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _loadingRewarded = false;
          _rewardedAd = null;

          debugPrint(
            'Rewarded load failed: ${error.message}',
          );
        },
      ),
    );
  }

  Future<bool> showRewardedAd({
    required void Function(
      RewardItem reward,
    ) onRewardEarned,
  }) async {
    if (kIsWeb) {
      return false;
    }

    final ad = _rewardedAd;

    if (ad == null) {
      loadRewardedAd();
      return false;
    }

    _rewardedAd = null;

    try {
      ad.show(
        onUserEarnedReward: (
          AdWithoutView adWithoutView,
          RewardItem reward,
        ) {
          debugPrint(
            'Reward earned: '
            '${reward.amount} ${reward.type}',
          );

          onRewardEarned(reward);
        },
      );

      return true;
    } catch (e) {
      debugPrint(
        'Rewarded show exception: $e',
      );

      ad.dispose();
      loadRewardedAd();

      return false;
    }
  }

  bool get isRewardedReady {
    return _rewardedAd != null;
  }

  /// ------------------------------------------------------------
  /// PRELOAD
  /// ------------------------------------------------------------

  void preloadAds() {
    if (kIsWeb) {
      return;
    }

    if (_interstitialAd == null) {
      loadInterstitialAd();
    }

    if (_rewardedAd == null) {
      loadRewardedAd();
    }
  }

  /// ------------------------------------------------------------
  /// DISPOSE
  /// ------------------------------------------------------------

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();

    _interstitialAd = null;
    _rewardedAd = null;

    _loadingInterstitial = false;
    _loadingRewarded = false;
  }
}
