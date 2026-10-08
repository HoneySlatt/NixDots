const { app } = require('electron');
const fs = require('fs');
const os = require('os');
const path = require('path');

const configHome = process.env.XDG_CONFIG_HOME || path.join(os.homedir(), '.config');
const cssFile = path.join(configHome, 'chatgpt-desktop', 'quickshell.css');
const views = new Map();
let css = '';

function isChatGPT(contents) {
  try {
    const url = new URL(contents.getURL());
    return url.protocol === 'app:' && url.hostname === '-';
  } catch {
    return false;
  }
}

function apply(contents, state) {
  state.pending = state.pending.then(async () => {
    if (!css || !state.ready || contents.isDestroyed() || !isChatGPT(contents)) return;
    const generation = state.generation;
    const previous = state.key;
    const key = await contents.insertCSS(css, { cssOrigin: 'user' });
    if (contents.isDestroyed()) return;
    if (generation !== state.generation) {
      await contents.removeInsertedCSS(key);
      return;
    }
    state.key = key;
    if (previous) await contents.removeInsertedCSS(previous);
  }).catch(error => {
    if (!contents.isDestroyed()) console.warn('[Quickshell theme]', error.message);
  });
}

function refresh() {
  try {
    const next = fs.readFileSync(cssFile, 'utf8');
    if (!next.trim() || next === css) return;
    css = next;
    for (const [contents, state] of views) apply(contents, state);
  } catch (error) {
    if (error.code !== 'ENOENT') console.warn('[Quickshell theme]', error.message);
  }
}

app.on('web-contents-created', (_event, contents) => {
  const state = { key: null, generation: 0, ready: false, pending: Promise.resolve() };
  views.set(contents, state);
  contents.on('did-navigate', () => {
    state.generation++;
    state.key = null;
    state.ready = false;
  });
  contents.on('dom-ready', () => {
    state.ready = true;
    apply(contents, state);
  });
  contents.once('destroyed', () => views.delete(contents));
});

refresh();
fs.watchFile(cssFile, { interval: 1000, persistent: false }, refresh);
app.once('will-quit', () => fs.unwatchFile(cssFile, refresh));
