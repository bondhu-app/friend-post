import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  // ---------------------------------------------------------------------------
  // Google Mobile Ads Test IDs
  // ---------------------------------------------------------------------------
  //
  // এগুলো Google-এর official test ad unit ID।
  // Build/analyze ঠিক করার জন্য এগুলো ব্যবহার করা হয়েছে।
  //
  // পরে নিজের AdMob ID ব্যবহার করতে চাইলে এই ID-গুলো পরিবর্তন করা যাবে।
  // ---------------------------------------------------------------------------

  static const String androidBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  static const String androidInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String androidRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String iosBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';

  static const String iosInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  static const String iosRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  BannerAd? _bannerAd;

  InterstitialAd? _interstitialAd;

  RewardedAd? _rewardedAd;

  bool _isRewardedLoading = false;

  bool _isInterstitialLoading = false;

  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      await MobileAds.instance.initialize();

      _initialized = true;

      await preloadAds();
    } catch (e) {
      debugPrint(
        'AdService initialization error: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Platform Ad Unit IDs
  // ---------------------------------------------------------------------------

  String get bannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return iosBannerAdUnitId;
    }

    return androidBannerAdUnitId;
  }

  String get interstitialAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return iosInterstitialAdUnitId;
    }

    return androidInterstitialAdUnitId;
  }

  String get rewardedAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return iosRewardedAdUnitId;
    }

    return androidRewardedAdUnitId;
  }

  // ---------------------------------------------------------------------------
  // Preload all ads
  // ---------------------------------------------------------------------------

  Future<void> preloadAds() async {
    await loadInterstitialAd();
    await loadRewardedAd();
  }

  // ---------------------------------------------------------------------------
  // Banner Ad
  // ---------------------------------------------------------------------------

  BannerAd? get bannerAd => _bannerAd;

  Future<BannerAd?> loadBannerAd() async {
    final banner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint(
            'Banner ad loaded successfully.',
          );
        },
        onAdFailedToLoad: (
          Ad ad,
          LoadAdError error,
        ) {
          debugPrint(
            'Banner ad failed to load: $error',
          );

          ad.dispose();

          if (identical(_bannerAd, ad)) {
            _bannerAd = null;
          }
        },
        onAdOpened: (Ad ad) {
          debugPrint(
            'Banner ad opened.',
          );
        },
        onAdClosed: (Ad ad) {
          debugPrint(
            'Banner ad closed.',
          );
        },
        onAdImpression: (Ad ad) {
          debugPrint(
            'Banner ad impression recorded.',
          );
        },
      ),
    );

    _bannerAd = banner;

    try {
      await banner.load();
      return _bannerAd;
    } catch (e) {
      debugPrint(
        'Banner load error: $e',
      );

      banner.dispose();
      _bannerAd = null;

      return null;
    }
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  // ---------------------------------------------------------------------------
  // Interstitial Ad
  // ---------------------------------------------------------------------------

  Future<void> loadInterstitialAd() async {
    if (_isInterstitialLoading) {
      return;
    }

    if (_interstitialAd != null) {
      return;
    }

    _isInterstitialLoading = true;

    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;

            _isInterstitialLoading = false;

            debugPrint(
              'Interstitial ad loaded successfully.',
            );

            ad.fullScreenContentCallback =
                FullScreenContentCallback<InterstitialAd>(
              onAdShowedFullScreenContent: (
                InterstitialAd ad,
              ) {
                debugPrint(
                  'Interstitial ad showed.',
                );
              },
              onAdDismissedFullScreenContent: (
                InterstitialAd ad,
              ) {
                debugPrint(
                  'Interstitial ad dismissed.',
                );

                ad.dispose();

                if (identical(
                  _interstitialAd,
                  ad,
                )) {
                  _interstitialAd = null;
                }

                loadInterstitialAd();
              },
              onAdFailedToShowFullScreenContent: (
                InterstitialAd ad,
                AdError error,
              ) {
                debugPrint(
                  'Interstitial ad failed to show: $error',
                );

                ad.dispose();

                if (identical(
                  _interstitialAd,
                  ad,
                )) {
                  _interstitialAd = null;
                }

                loadInterstitialAd();
              },
              onAdImpression: (
                InterstitialAd ad,
              ) {
                debugPrint(
                  'Interstitial ad impression recorded.',
                );
              },
            );
          },
          onAdFailedToLoad: (
            LoadAdError error,
          ) {
            _isInterstitialLoading = false;
            _interstitialAd = null;

            debugPrint(
              'Interstitial ad failed to load: $error',
            );
          },
        ),
      );
    } catch (e) {
      _isInterstitialLoading = false;
      _interstitialAd = null;

      debugPrint(
        'Interstitial load error: $e',
      );
    }
  }

  bool get isInterstitialReady =>
      _interstitialAd != null;

  Future<void> showInterstitialAd() async {
    final ad = _interstitialAd;

    if (ad == null) {
      await loadInterstitialAd();
      return;
    }

    _interstitialAd = null;

    try {
      await ad.show();
    } catch (e) {
      debugPrint(
        'Interstitial show error: $e',
      );

      ad.dispose();

      await loadInterstitialAd();
    }
  }

  // ---------------------------------------------------------------------------
  // Rewarded Ad
  // ---------------------------------------------------------------------------

  Future<void> loadRewardedAd() async {
    if (_isRewardedLoading) {
      return;
    }

    if (_rewardedAd != null) {
      return;
    }

    _isRewardedLoading = true;

    try {
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAd = ad;

            _isRewardedLoading = false;

            debugPrint(
              'Rewarded ad loaded successfully.',
            );

            ad.fullScreenContentCallback =
                FullScreenContentCallback<RewardedAd>(
              onAdShowedFullScreenContent: (
                RewardedAd ad,
              ) {
                debugPrint(
                  'Rewarded ad showed.',
                );
              },
              onAdDismissedFullScreenContent: (
                RewardedAd ad,
              ) {
                debugPrint(
                  'Rewarded ad dismissed.',
                );

                ad.dispose();

                if (identical(
                  _rewardedAd,
                  ad,
                )) {
                  _rewardedAd = null;
                }

                loadRewardedAd();
              },
              onAdFailedToShowFullScreenContent: (
                RewardedAd ad,
                AdError error,
              ) {
                debugPrint(
                  'Rewarded ad failed to show: $error',
                );

                ad.dispose();

                if (identical(
                  _rewardedAd,
                  ad,
                )) {
                  _rewardedAd = null;
                }

                loadRewardedAd();
              },
              onAdImpression: (
                RewardedAd ad,
              ) {
                debugPrint(
                  'Rewarded ad impression recorded.',
                );
              },
            );
          },
          onAdFailedToLoad: (
            LoadAdError error,
          ) {
            _isRewardedLoading = false;
            _rewardedAd = null;

            debugPrint(
              'Rewarded ad failed to load: $error',
            );
          },
        ),
      );
    } catch (e) {
      _isRewardedLoading = false;
      _rewardedAd = null;

      debugPrint(
        'Rewarded load error: $e',
      );
    }
  }

  bool get isRewardedReady =>
      _rewardedAd != null;

  // ---------------------------------------------------------------------------
  // Show Rewarded Ad
  // ---------------------------------------------------------------------------
  //
  // Return value:
  // true  = user earned the reward
  // false = ad দেখানো হয়নি অথবা reward পাওয়া যায়নি
  // ---------------------------------------------------------------------------

  Future<bool> showRewardedAd() async {
    final ad = _rewardedAd;

    if (ad == null) {
      await loadRewardedAd();
      return false;
    }

    _rewardedAd = null;

    bool rewardEarned = false;

    try {
      ad.show(
        onUserEarnedReward: (
          adWithoutView,
          reward,
        ) {
          rewardEarned = true;

          debugPrint(
            'Reward earned: '
            '${reward.amount} ${reward.type}',
          );
        },
      );

      return await _waitForRewardResult(
        () => rewardEarned,
      );
    } catch (e) {
      debugPrint(
        'Rewarded ad show error: $e',
      );

      ad.dispose();

      await loadRewardedAd();

      return false;
    }
  }

  Future<bool> _waitForRewardResult(
    bool Function() rewardChecker,
  ) async {
    const maxWaitMilliseconds = 120000;

    const intervalMilliseconds = 100;

    var elapsed = 0;

    while (elapsed < maxWaitMilliseconds) {
      if (rewardChecker()) {
        return true;
      }

      await Future<void>.delayed(
        const Duration(
          milliseconds: intervalMilliseconds,
        ),
      );

      elapsed += intervalMilliseconds;
    }

    return rewardChecker();
  }

  // ---------------------------------------------------------------------------
  // Rewarded Ad with callback
  // ---------------------------------------------------------------------------

  Future<bool> showRewardedAdWithCallback({
    required Future<void> Function(
      double amount,
      String type,
    ) onRewardEarned,
  }) async {
    final ad = _rewardedAd;

    if (ad == null) {
      await loadRewardedAd();
      return false;
    }

    _rewardedAd = null;

    bool rewardEarned = false;

    try {
      ad.show(
        onUserEarnedReward: (
          adWithoutView,
          reward,
        ) async {
          rewardEarned = true;

          try {
            await onRewardEarned(
              reward.amount.toDouble(),
              reward.type,
            );
          } catch (e) {
            debugPrint(
              'Reward callback error: $e',
            );
          }
        },
      );

      await Future<void>.delayed(
        const Duration(
          milliseconds: 500,
        ),
      );

      return rewardEarned;
    } catch (e) {
      debugPrint(
        'Rewarded callback ad error: $e',
      );

      ad.dispose();

      await loadRewardedAd();

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Compatibility methods
  // ---------------------------------------------------------------------------

  Future<void> showRewarded() async {
    await showRewardedAd();
  }

  Future<void> showInterstitial() async {
    await showInterstitialAd();
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;

    _interstitialAd?.dispose();
    _interstitialAd = null;

    _rewardedAd?.dispose();
    _rewardedAd = null;

    _isRewardedLoading = false;
    _isInterstitialLoading = false;
  }
}
