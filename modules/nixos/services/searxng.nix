{ lib, pkgs, ... }:

let
  resultGroup = pkgs.writeText "result_group.html" ''
    {#- Brave-style grouping: the next results from the same site are listed inside the first one -#}
    {%- from 'simple/macros.html' import result_link with context -%}
    {%- set host = result.parsed_url.netloc if result.parsed_url else none -%}
    {#- Some engines (bing, wikibooks) ignore site:, drop their off-site results -#}
    {%- set site_filter = q.split('site:', 1)[1].split(' ')[0] | replace('www.', ''', 1) if 'site:' in q else none -%}
    {%- set off_site = site_filter and host and not (host == site_filter or host.endswith('.' ~ site_filter)) -%}
    {%- if result.url not in group_ns.hidden and not off_site -%}
      {%- set siblings = [] -%}
      {%- if host and result['template'] | default('default.html', true) == 'default.html' and 'site:' not in q -%}
        {%- set siblings = results | selectattr('parsed_url') | selectattr('parsed_url.netloc', 'equalto', host) | rejectattr('url', 'equalto', result.url) | list -%}
      {%- endif -%}
      {%- if siblings -%}
        {#- One group per site like Brave: the rest stays behind the "More results" link -#}
        {%- set group_ns.hidden = group_ns.hidden + siblings | map(attribute='url') | list -%}
        {%- set site = host[4:] if host.startswith('www.') else host -%}
        {%- set article -%}{% include get_result_template('simple', result['template']) %}{%- endset -%}
        {#- Inside the article, the infinite scroll only copies articles from the next pages -#}
        {%- set group -%}
        <div class="result_group">
          <ul>
          {%- for sibling in siblings[:5] %}
            <li>{{ result_link(sibling.url, sibling.title|safe) }}{% if sibling.publishedDate %}<time>{{ sibling.publishedDate }}</time>{% endif %}</li>
          {%- endfor %}
          </ul>
          <a class="result_group_more" href="{{ url_for('search') }}?q={{ ('site:' ~ site ~ ' ' ~ q)|urlencode }}">More results from {{ site }}</a>
        </div>
        {%- endset -%}
        {{ article | replace('</article>'|safe, group ~ ('</article>'|safe)) }}
      {%- else -%}
        {% include get_result_template('simple', result['template']) %}
      {%- endif -%}
    {%- endif -%}
  '';

  # Stock templates with the result loop routed through the site grouping template
  templates = pkgs.runCommand "searxng-templates" { } ''
    cp -r ${pkgs.searxng}/${pkgs.searxng.pythonModule.sitePackages}/searx/templates $out
    chmod -R u+w $out
    cp ${resultGroup} $out/simple/result_group.html
    substituteInPlace $out/simple/results.html \
      --replace-fail '<div id="urls" role="main">' '<div id="urls" role="main">{%- set group_ns = namespace(hidden=[]) -%}' \
      --replace-fail "{% include get_result_template('simple', result['template']) %}" "{% include 'simple/result_group.html' %}"
    # Show the site as "reddit.com" instead of "https://www.reddit.com"
    substituteInPlace $out/simple/macros.html \
      --replace-fail "{{- part -}}" "{{- part.split('://', 1)[-1] | replace('www.', ''', 1) if loop.first else part -}}"
  '';
in
{
  services.searx = {
    enable = true;
    package = pkgs.searxng;

    environmentFile = "/etc/searxng.env";

    faviconsSettings.favicons = {
      cfg_schema = 1;
      # Default lives in the private /tmp and is lost on every restart
      cache.db_url = "/var/cache/searx/faviconcache.db";
      # Default 20 KB skips caching about one icon in six
      cache.BLOB_MAX_BYTES = 102400;
    };

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
        # Fetched and cached server-side, the browser never contacts the resolver
        favicon_resolver = "duckduckgo";
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
        center_alignment = false;
        default_theme = "simple";
        theme_args.simple_style = "dark";
        search_on_category_select = true;
        hotkeys = "vim";
        templates_path = "${templates}";
      };

      outgoing = {
        request_timeout = 3.0;
        max_request_timeout = 10.0;
        pool_connections = 100;
        pool_maxsize = 20;
        enable_http2 = true;
      };

      engines = lib.mapAttrsToList (name: value: { inherit name; disabled = false; } // value) {
        google.weight = 2;
        "google cse".weight = 2;
        bing.weight = 1;
        brave.weight = 1;
        duckduckgo.weight = 1;
        qwant.weight = 1;
        yahoo.weight = 1;
        mwmbl = { disabled = true; weight = 0.4; };

        # Slowest engine by far (1-2.5 s per query), still reachable with !wd
        wikidata = { disabled = true; weight = 1.5; timeout = 6.0; };
        wikipedia.weight = 1.5;
        "ddg definitions".weight = 2;
        wikibooks = { };

        stackoverflow.weight = 1.5;
        github.weight = 1;

        "google news" = { };
        "bing news" = { };

        # Need a Tor proxy, skip loading them
        ahmia.inactive = true;
        torch.inactive = true;
      };

      # Replaces the default plugin list entirely, so every wanted plugin is listed
      plugins = lib.listToAttrs (map (name: lib.nameValuePair "searx.plugins.${name}.SXNGPlugin" { active = true; }) [
        "calculator"
        "hash_plugin"
        "self_info"
        "unit_converter"
        "hostnames"
        "time_zone"
        "tracker_url_remover"
        "oa_doi_rewrite"
        "infinite_scroll"
      ]);
    };
  };

  # Wait for DNS so ClearURLs rules and engine init succeed at boot
  systemd.services.searx = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };
}
