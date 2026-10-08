import { app } from 'electron';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const configHome = process.env.XDG_CONFIG_HOME || path.join(os.homedir(), '.config');
const themeFile = path.join(configHome, 'opencode', 'amane-desktop.json');
const views = new Set();
let theme;
let previous = '';

function apply(contents) {
  if (!theme || contents.isDestroyed() || !contents.getURL().startsWith('oc://renderer/')) return;
  // Keep the latest value for ThemeProviders mounted after the document loads.
  contents.executeJavaScript(`
    window.__amaneTheme = ${JSON.stringify(theme)};
    window.dispatchEvent(new Event('amane-theme'));
  `).catch(error => {
    if (!contents.isDestroyed()) console.warn('[Amane theme]', error.message);
  });
}

function refresh() {
  try {
    const next = fs.readFileSync(themeFile, 'utf8');
    if (next === previous) return;
    const value = JSON.parse(next);
    if (!['light', 'dark'].includes(value.mode) || !value.variant?.palette) return;
    theme = value;
    previous = next;
    for (const contents of views) apply(contents);
  } catch (error) {
    if (error.code !== 'ENOENT') console.warn('[Amane theme]', error.message);
  }
}

app.on('web-contents-created', (_event, contents) => {
  views.add(contents);
  contents.on('did-finish-load', () => apply(contents));
  contents.once('destroyed', () => views.delete(contents));
});

refresh();
fs.watchFile(themeFile, { interval: 1000, persistent: false }, refresh);
app.once('will-quit', () => fs.unwatchFile(themeFile, refresh));
