{ config, lib, ... }:

let
  amo = slug: "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
  locked = value: { Value = value; Status = "locked"; };
in
{
  # Policies are built into the wrapped package; no profile is declared so that
  # user.js and chrome/*.css stay with themes/apps/firefox.sh
  programs.firefox = {
    enable = true;
    # Where the existing profile already lives
    configPath = "${config.xdg.configHome}/mozilla/firefox";
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFeedbackCommands = true;
      DisableFirefoxAccounts = true;
      DisableFormHistory = true;
      CaptivePortal = false;
      NetworkPrediction = false;
      SearchSuggestEnabled = false;

      # Passwords live in Bitwarden
      PasswordManagerEnabled = false;
      OfferToSaveLogins = false;
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;

      # Strict mode also covers Total Cookie Protection and URL query stripping
      EnableTrackingProtection = {
        Category = "strict";
        Locked = true;
      };
      HttpsOnlyMode = "force_enabled";
      SSLVersionMin = "tls1.2";
      PostQuantumKeyAgreementEnabled = true;

      # DNS stays on the system resolver, i.e. inside the Nym tunnel
      DNSOverHTTPS = {
        Enabled = false;
        Locked = true;
      };

      Permissions = lib.genAttrs [ "Location" "Notifications" ] (_: {
        BlockNewRequests = true;
        Locked = true;
      });

      FirefoxHome = {
        SponsoredTopSites = false;
        SponsoredStories = false;
        SponsoredPocket = false;
        Pocket = false;
        Stories = false;
        Locked = true;
      };
      FirefoxSuggest = {
        WebSuggestions = false;
        SponsoredSuggestions = false;
        ImproveSuggest = false;
        OnlineEnabled = false;
        Locked = true;
      };
      UserMessaging = {
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        UrlbarInterventions = false;
        MoreFromMozilla = false;
        FirefoxLabs = false;
        SkipOnboarding = true;
        Locked = true;
      };

      # Only prefixes accepted by the Preferences policy (no security.*)
      Preferences = lib.mapAttrs (_: locked) {
        "privacy.fingerprintingProtection" = true;
        "privacy.globalprivacycontrol.enabled" = true;
        "network.http.referer.XOriginTrimmingPolicy" = 2;
        "network.http.speculative-parallel-limit" = 0;
        "network.IDN_show_punycode" = true;
        "media.peerconnection.ice.default_address_only" = true;
        "browser.urlbar.speculativeConnect.enabled" = false;
        "browser.places.speculativeConnect.enabled" = false;
        "browser.send_pings" = false;
        "browser.uitour.enabled" = false;
        "browser.safebrowsing.downloads.remote.enabled" = false;
        "pdfjs.enableScripting" = false;
      };

      ExtensionSettings = builtins.mapAttrs (_: slug: {
        install_url = amo slug;
        installation_mode = "force_installed";
      }) {
        "uBlock0@raymondhill.net" = "ublock-origin";
        "addon@darkreader.org" = "darkreader";
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = "bitwarden-password-manager";
      };

      SearchEngines = {
        Add = [
          {
            Name = "Brave";
            URLTemplate = "https://search.brave.com/search?q={searchTerms}";
            SuggestURLTemplate = "https://search.brave.com/api/suggest?q={searchTerms}";
            IconURL = "https://search.brave.com/favicon.ico";
            Alias = "@brave";
          }
        ];
        Default = "Brave";
      };
    };
  };
}
