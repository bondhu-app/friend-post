import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isLoadingInterstitial = false;
  bool _isLoadingRewarded = false;

  /// ------------------------------------------------------------
  /// AdMob App ID / Ad Unit IDs
  /// ------------------------------------------------------------
  ///
  /// এখন TEST ID ব্যবহার করা হচ্ছে।
  /// অ্যাপ publish করার আগে অবশ্যই নিজের AdMob Ad Unit ID বসাতে হবে।
  ///

  static const String _androidInterstitialTestId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String _iosInterstitialTestId =
      'ca-app-pub-3940256099942544/4411468910';

  static const String _androidRewardedTestId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String _iosRewardedTestId =
      'ca-app-pub-3940256099942544/1712485313';

  String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return _androidInterstitialTestId;
    }

    if (Platform.isIOS) {
      return _iosInterstitialTestId;
    }

    return '';
  }

  String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return _androidRewardedTestId;
    }

    if (Platform.isIOS) {
      return _iosRewardedTestId;
    }

    return '';
  }

  /// ------------------------------------------------------------
  /// Initialize Mobile Ads
  /// ------------------------------------------------------------

  Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }

    try {
      await MobileAds.instance.initialize();

      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: const [],
        ),
      );

      loadInterstitialAd();
      loadRewardedAd();
    } catch (e) {
      debugPrint('AdMob initialization error: $e');
    }
  }

  /// ------------------------------------------------------------
  /// Interstitial Ad
  /// ------------------------------------------------------------

  void loadInterstitialAd() {
    if (kIsWeb) {
      return;
    }

    if (_interstitialAd != null) {
      return;
    }

    if (_isLoadingInterstitial) {
      return;
    }

    final adUnitId = _interstitialAdUnitId;

    if (adUnitId.isEmpty) {
      return;
    }

    _isLoadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _isLoadingInterstitial = false;
          _interstitialAd = ad;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (Ad ad) {
              ad.dispose();
              _interstitialAd = null;

              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
              debugPrint(
                'Interstitial show error: ${error.message}',
              );

              ad.dispose();
              _interstitialAd = null;

              loadInterstitialAd();
            },
            onAdShowedFullScreenContent: (Ad ad) {
              debugPrint('Interstitial ad showed');
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoadingInterstitial = false;
          _interstitialAd = null;

          debugPrint(
            'Interstitial load error: ${error.message}',
          );
        },
      ),
    );
  }

  /// Shows an interstitial ad if one is ready.
  ///
  /// Returns true if an ad was shown.
  /// Returns false if no ad was ready.
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
      ad.show();
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
  /// Rewarded Ad
  /// ------------------------------------------------------------

  void loadRewardedAd() {
    if (kIsWeb) {
      return;
    }

    if (_rewardedAd != null) {
      return;
    }

    if (_isLoadingRewarded) {
      return;
    }

    final adUnitId = _rewardedAdUnitId;

    if (adUnitId.isEmpty) {
      return;
    }

    _isLoadingRewarded = true;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _isLoadingRewarded = false;
          _rewardedAd = ad;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (Ad ad) {
              ad.dispose();
              _rewardedAd = null;

              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (
              Ad ad,
              AdError error,
            ) {
              debugPrint(
                'Rewarded show error: ${error.message}',
              );

              ad.dispose();
              _rewardedAd = null;

              loadRewardedAd();
            },
            onAdShowedFullScreenContent: (Ad ad) {
              debugPrint('Rewarded ad showed');
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoadingRewarded = false;
          _rewardedAd = null;

          debugPrint(
            'Rewarded load error: ${error.message}',
          );
        },
      ),
    );
  }

  /// Shows rewarded ad.
  ///
  /// [onRewardEarned] will be called only after the user
  /// successfully earns the reward.
  Future<bool> showRewardedAd({
    required void Function(RewardItem reward) onRewardEarned,
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

    bool rewardEarned = false;

    try {
      ad.show(
        onUserEarnedReward: (
          AdWithoutView ad,
          RewardItem reward,
        ) {
          rewardEarned = true;

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
  /// Preload Ads
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
  /// Dispose
  /// ------------------------------------------------------------

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();

    _interstitialAd = null;
    _rewardedAd = null;

    _isLoadingInterstitial = false;
    _isLoadingRewarded = false;
  }
}
