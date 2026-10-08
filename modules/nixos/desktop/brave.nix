# Brave Origin reads Chromium policies from /etc/brave/policies
let
  block = 2;
in
{
  programs.chromium = {
    enable = true;

    # Force-installed from the Chrome Web Store
    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      "jcokkipkhhgiakinbnnplhkdbjbgcgpe" # uBlock Origin
      "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      "clngdbkpkpeebahjckkjfobafhncgmne" # Stylus
      "cbghhgpcnddeihccjmnadmkaejncjndb" # Vencord Web
    ];

    # All enforced. Rewards, Wallet, VPN, Leo, News and Talk are not built into Origin.
    extraOpts = {
      DefaultSearchProviderEnabled = true;
      DefaultSearchProviderName = "Brave";
      DefaultSearchProviderSearchURL = "https://search.brave.com/search?q={searchTerms}";
      DefaultSearchProviderSuggestURL = "https://search.brave.com/api/suggest?q={searchTerms}";
      SearchSuggestEnabled = false;

      # Brave privacy features, locked to their protective defaults
      BraveGlobalPrivacyControlEnabled = true;
      BraveDeAmpEnabled = true;
      BraveDebouncingEnabled = true;
      BraveTrackingQueryParametersFilteringEnabled = true;
      BraveReduceLanguageEnabled = true;
      BlockThirdPartyCookies = true;

      # Telemetry and data collection
      BraveP3AEnabled = false;
      BraveStatsPingEnabled = false;
      MetricsReportingEnabled = false;
      UrlKeyedAnonymizedDataCollectionEnabled = false;
      FeedbackSurveysEnabled = false;
      UserFeedbackAllowed = false;
      WebRtcEventLogCollectionAllowed = false;
      WebRtcTextLogCollectionAllowed = false;
      PrivacySandboxPromptEnabled = false;
      PrivacySandboxAdTopicsEnabled = false;
      PrivacySandboxSiteEnabledAdsEnabled = false;
      PrivacySandboxAdMeasurementEnabled = false;

      # Network: HTTPS only, DNS through the system resolver (Nym tunnel), no prefetching
      HttpsOnlyMode = "force_enabled";
      HttpsUpgradesEnabled = true;
      DnsOverHttpsMode = "off";
      NetworkPredictionOptions = 2;
      WebRtcIPHandling = "default_public_interface_only";
      AlternateErrorPagesEnabled = false;
      SpellCheckServiceEnabled = false;
      BrowserNetworkTimeQueriesEnabled = false;
      SafeBrowsingProtectionLevel = 1;
      # Cast discovery scans the LAN
      EnableMediaRouter = false;

      # Passwords live in Bitwarden, no account sync
      PasswordManagerEnabled = false;
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;
      PaymentMethodQueryEnabled = false;
      SyncDisabled = true;
      BrowserSignin = 0;

      # Site permissions blocked by default (same as Firefox, which has no such APIs)
      DefaultGeolocationSetting = block;
      DefaultNotificationsSetting = block;
      DefaultSensorsSetting = block;
      DefaultLocalFontsSetting = block;
      DefaultSerialGuardSetting = block;
      DefaultWebBluetoothGuardSetting = block;
      DefaultWebUsbGuardSetting = block;
      DefaultWebHidGuardSetting = block;

      BackgroundModeEnabled = false;
      BlockExternalExtensions = true;
    };
  };
}
