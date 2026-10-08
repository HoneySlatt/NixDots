{ lib, pkgs, ... }:

{
  services.searx = {
    enable = true;
    package = pkgs.searxng;
    redisCreateLocally = true;

    environmentFile = "/etc/searxng.env";

    settings = {

      general = {
        debug = false;
        instance_name = "searxng-local";
        donation_url = false;
        contact_url = false;
        privacypolicy_url = false;
        enable_metrics = false;
      };

      search = {
        safe_search = 0;
        autocomplete = "";
        default_lang = "en-US";
        ban_time_on_fail = 5;
        max_ban_time_on_fail = 120;
        formats = [ "html" "json" ];
      };

      server = {
        port = 8888;
        bind_address = "127.0.0.1";
        secret_key = "@SEARXNG_SECRET@";
        limiter = false;
        public_instance = false;
        # Result images are fetched by SearXNG instead of the browser
        image_proxy = true;
        method = "GET";
      };

      ui = {
        static_use_hash = true;
        default_locale = "en";
        query_in_title = true;
        infinite_scroll = true;
        center_alignment = false;
        default_theme = "simple";
        theme_args.simple_style = "dark";
        search_on_category_select = true;
        hotkeys = "vim";
      };

      outgoing = {
        request_timeout = 6.0;
        max_request_timeout = 15.0;
        pool_connections = 100;
        pool_maxsize = 20;
        enable_http2 = true;
      };

      engines = lib.mapAttrsToList (name: value: { inherit name; disabled = false; } // value) {
        google.weight = 2;
        bing.weight = 1;
        brave.weight = 1;
        duckduckgo.weight = 1;
        qwant.weight = 1;
        mojeek.weight = 0.5;
        mwmbl = { disabled = true; weight = 0.4; };

        wikidata.weight = 1.5;
        wikipedia.weight = 1.5;
        "ddg definitions".weight = 2;
        wikibooks = { };

        stackoverflow.weight = 1.5;
        github.weight = 1;
        "searchcode code" = { };

        "google news" = { };
        "bing news" = { };
      };

      enabled_plugins = [
        "Basic Calculator"
        "Hash plugin"
        "Open Access DOI rewrite"
        "Tracker URL remover"
        "Unit converter plugin"
      ];
    };
  };
}
