#!/usr/bin/env node
// Usage: compile-userstyle.js <site.user.less> <palette-json> [--desktop]
// Compiles a catppuccin userstyle LESS file with a custom palette injected.

const fs   = require('fs');
const path = require('path');

let less;
try {
  less = require('less');
} catch (_) {
  less = require(process.env.LESS_MODULE_PATH || 'less');
}

const [,, lessFile, paletteJson, mode] = process.argv;
if (!lessFile || !paletteJson || (mode && mode !== '--desktop')) {
  process.stderr.write('Usage: compile-userstyle.js <file.user.less> <palette.json> [--desktop]\n');
  process.exit(1);
}

const palette = JSON.parse(paletteJson);
const src     = fs.readFileSync(lessFile, 'utf8');
const libDir  = path.dirname(lessFile);

// We override the "mocha" flavor in @catppuccin with our theme colors.
// LESS uses lazy variable resolution, so a definition placed *after* the import wins.
// We also set @darkFlavor / @lightFlavor to mocha and lock @accentColor.
const paletteOverride = `
@darkFlavor:  mocha;
@lightFlavor: mocha;
@accentColor: ${palette.accentColor};

// Override mocha flavor with our custom theme colors
@catppuccin: {
  @latte:     { @rosewater: #f5e0dc; @flamingo: #f2cdcd; @pink: #f5c2e7; @mauve: #cba6f7; @red: #f38ba8; @maroon: #eba0ac; @peach: #fab387; @yellow: #f9e2af; @green: #a6e3a1; @teal: #94e2d5; @sky: #89dceb; @sapphire: #74c7ec; @blue: #89b4fa; @lavender: #b4befe; @text: #cdd6f4; @subtext1: #bac2de; @subtext0: #a6adc8; @overlay2: #9399b2; @overlay1: #7f849c; @overlay0: #6c7086; @surface2: #585b70; @surface1: #45475a; @surface0: #313244; @base: #1e1e2e; @mantle: #181825; @crust: #11111b; };
  @frappe:    { @rosewater: #f2d5cf; @flamingo: #eebebe; @pink: #f4b8e4; @mauve: #ca9ee6; @red: #e78284; @maroon: #ea999c; @peach: #ef9f76; @yellow: #e5c890; @green: #a6d189; @teal: #81c8be; @sky: #99d1db; @sapphire: #85c1dc; @blue: #8caaee; @lavender: #babbf1; @text: #c6d0f5; @subtext1: #b5bfe2; @subtext0: #a5adce; @overlay2: #949cbb; @overlay1: #838ba7; @overlay0: #737994; @surface2: #626880; @surface1: #51576d; @surface0: #414559; @base: #303446; @mantle: #292c3c; @crust: #232634; };
  @macchiato: { @rosewater: #f4dbd6; @flamingo: #f0c6c6; @pink: #f5bde6; @mauve: #c6a0f6; @red: #ed8796; @maroon: #ee99a0; @peach: #f5a97f; @yellow: #eed49f; @green: #a6da95; @teal: #8bd5ca; @sky: #91d7e3; @sapphire: #7dc4e4; @blue: #8aadf4; @lavender: #b7bdf8; @text: #cad3f5; @subtext1: #b8c0e0; @subtext0: #a5adcb; @overlay2: #939ab7; @overlay1: #8087a2; @overlay0: #6e738d; @surface2: #5b6078; @surface1: #494d64; @surface0: #363a4f; @base: #24273a; @mantle: #1e2030; @crust: #181926; };
  @mocha: {
    @rosewater: ${palette.rosewater};
    @flamingo:  ${palette.flamingo};
    @pink:      ${palette.pink};
    @mauve:     ${palette.mauve};
    @red:       ${palette.red};
    @maroon:    ${palette.maroon};
    @peach:     ${palette.peach};
    @yellow:    ${palette.yellow};
    @green:     ${palette.green};
    @teal:      ${palette.teal};
    @sky:       ${palette.sky};
    @sapphire:  ${palette.sapphire};
    @blue:      ${palette.blue};
    @lavender:  ${palette.lavender};
    @text:      ${palette.text};
    @subtext1:  ${palette.subtext1};
    @subtext0:  ${palette.subtext0};
    @overlay2:  ${palette.overlay2};
    @overlay1:  ${palette.overlay1};
    @overlay0:  ${palette.overlay0};
    @surface2:  ${palette.surface2};
    @surface1:  ${palette.surface1};
    @surface0:  ${palette.surface0};
    @base:      ${palette.base};
    @mantle:    ${palette.mantle};
    @crust:     ${palette.crust};
  };
};
`;

// Extract checkbox defaults from the ==UserStyle== header before stripping it
const checkboxDefaults = [];
const headerMatch = src.match(/\/\* ==UserStyle==([\s\S]*?)==\/UserStyle== \*\//m);
if (headerMatch) {
  for (const m of headerMatch[1].matchAll(/@var\s+checkbox\s+(\w+)\s+"[^"]*"\s+(\d)/g)) {
    checkboxDefaults.push(`@${m[1]}: ${m[2]};`);
  }
}

const checkboxVars = checkboxDefaults.join('\n');

// Strip ==UserStyle== header block, replace CDN import with local, strip stray @var lines
const cleaned = src
  .replace(/\/\* ==UserStyle==[\s\S]*?==\/UserStyle== \*\//m, '')
  .replace(/@import\s+"https:\/\/userstyles\.catppuccin\.com\/lib\/(?:lib|std\/v1)\.less";\n?/,
           `@import "${libDir}/lib.less";\n${checkboxVars}\n${paletteOverride}`)
  .replace(/@preprocessor\s+\S+;?/g, '')
  .replace(/@var\s+\S+[^\n]*/g, '');

// ChatGPT Desktop's bundled UI derives its colors from --app-color-* tokens.
function chatgptDesktopCss(p) {
  const accent = p[p.accentColor];
  const fg = pct => `color-mix(in srgb, ${p.text} ${pct}%, transparent)`;
  const vars = {
    'startup-background': p.mantle,
    'app-color-background-surface': p.base,
    'app-color-background-surface-under': p.mantle,
    'app-color-background-application-menu': p.mantle,
    'app-color-foreground-application-menu': p.text,
    'app-color-border-application-menu-separator': p.surface2,
    'app-color-background-control': p.surface0,
    'app-color-background-editor-opaque': p.surface0,
    'app-color-background-elevated-primary': p.surface1,
    'app-color-background-elevated-primary-opaque': p.surface1,
    'app-color-background-elevated-secondary': fg(3.2),
    'app-color-background-elevated-secondary-opaque': p.surface0,
    'app-color-background-button-primary': p.crust,
    'app-color-background-button-primary-hover': fg(5.8),
    'app-color-background-button-primary-active': fg(10),
    'app-color-background-button-primary-inactive': fg(3.2),
    'app-color-background-button-secondary': fg(5.2),
    'app-color-background-button-secondary-hover': fg(7.8),
    'app-color-background-button-secondary-active': fg(12),
    'app-color-background-button-secondary-inactive': fg(3.8),
    'app-color-background-button-tertiary': fg(2.9),
    'app-color-background-button-tertiary-hover': fg(6.8),
    'app-color-background-button-tertiary-active': fg(10),
    'app-color-background-accent': `color-mix(in srgb, ${accent} 30%, ${p.base})`,
    'app-color-background-accent-hover': `color-mix(in srgb, ${accent} 30%, ${p.base})`,
    'app-color-background-accent-active': `color-mix(in srgb, ${accent} 30%, ${p.base})`,
    'app-color-text-foreground': p.text,
    'app-color-text-foreground-secondary': p.subtext1,
    'app-color-text-foreground-tertiary': p.subtext0,
    'app-color-text-accent': accent,
    'app-color-text-on-accent': p.base,
    'app-color-text-button-primary': p.crust,
    'app-color-text-button-secondary': p.overlay0,
    'app-color-text-button-tertiary': fg(51),
    'app-color-icon-primary': fg(90.4),
    'app-color-icon-secondary': fg(71),
    'app-color-icon-tertiary': fg(51),
    'app-color-icon-accent': accent,
    'app-color-accent-blue': accent,
    'app-color-accent-purple': accent,
    'app-color-border': fg(8.4),
    'app-color-border-heavy': fg(15.6),
    'app-color-border-light': fg(4.2),
    'app-color-border-focus': accent,
    'app-color-simple-scrim': fg(10.4),
    'app-color-decoration-added': p.green,
    'app-color-decoration-deleted': p.red,
    'app-color-editor-added': `color-mix(in srgb, ${p.green} 23%, transparent)`,
    'app-color-editor-deleted': `color-mix(in srgb, ${p.red} 23%, transparent)`,
  };
  const body = Object.entries(vars).map(([k, v]) => `  --${k}: ${v} !important;`).join('\n');
  return `\n:root, [data-theme] {\n${body}\n}\n`;
}

less.render(cleaned, { compress: false })
  .then(output => {
    let css = output.css.replace(/(--[\w-]+:[^;!]+)(;)/g, '$1 !important$2');
    if (mode === '--desktop') {
      // Electron selects the Claude views; its local title bar has no data-mode attributes.
      css = css.replace(/@-moz-document[^\{]+\{/g, '@media all {')
        .replace(/:root\[data-color-version="v2"\]\[data-mode="(?:dark|light)"\]/g, ':root');
      const site = path.basename(lessFile, '.user.less');
      if (site === 'claude') {
        css += `\n* { --claude-accent-clay: ${palette[palette.accentColor]} !important; }\n`;
      } else if (site === 'chatgpt') {
        css += chatgptDesktopCss(palette);
      }
    }
    process.stdout.write(css);
  })
  .catch(err   => { process.stderr.write(err.message + '\n'); process.exit(1); });
