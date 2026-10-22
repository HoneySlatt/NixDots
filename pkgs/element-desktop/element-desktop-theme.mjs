import { app } from "electron";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const configHome = process.env.XDG_CONFIG_HOME || path.join(os.homedir(), ".config");
const cssFile = path.join(configHome, "element-desktop", "amane.css");
const views = new Map();
let css = "";

function isElement(contents) {
  try {
    const url = new URL(contents.getURL());
    return url.protocol === "vector:" && url.hostname === "vector";
  } catch {
    return false;
  }
}

function apply(contents, state) {
  state.pending = state.pending.then(async () => {
    if (!css || !state.ready || contents.isDestroyed() || !isElement(contents)) return;
    const generation = state.generation;
    const previous = state.key;
    const key = await contents.insertCSS(css, { cssOrigin: "user" });
    if (contents.isDestroyed()) return;
    if (generation !== state.generation) {
      await contents.removeInsertedCSS(key);
      return;
    }
    state.key = key;
    if (previous) await contents.removeInsertedCSS(previous);
    await pinTheme(contents, state);
  }).catch(error => {
    if (!contents.isDestroyed()) console.warn("[Amane theme]", error.message);
  });
}

// Element stores the chosen theme in localStorage, ahead of config.json.
// The saved "match system theme" would ignore the Amane theme until it is cleared.
async function pinTheme(contents, state) {
  if (state.pinned || contents.isDestroyed()) return;
  const changed = await contents.executeJavaScript(`(() => {
    if (!window.electron || typeof window.electron.initialise !== "function") return false;
    return window.electron.initialise().then(info => {
      const themes = info?.config?.setting_defaults?.custom_themes || [];
      if (!themes.some(theme => theme && theme.name === "Amane")) return false;
      const key = "mx_local_settings";
      let settings = {};
      try { settings = JSON.parse(localStorage.getItem(key) || "{}"); } catch { return false; }
      if (settings.theme === "custom-Amane" && settings.use_system_theme === false) return false;
      settings.theme = "custom-Amane";
      settings.use_system_theme = false;
      localStorage.setItem(key, JSON.stringify(settings));
      return true;
    });
  })()`);
  if (!changed || contents.isDestroyed()) return;
  state.pinned = true;
  contents.reload();
}

function refresh() {
  try {
    const next = fs.readFileSync(cssFile, "utf8");
    if (!next.trim() || next === css) return;
    css = next;
    for (const [contents, state] of views) apply(contents, state);
  } catch (error) {
    if (error.code !== "ENOENT") console.warn("[Amane theme]", error.message);
  }
}

app.on("web-contents-created", (_event, contents) => {
  const state = { key: null, generation: 0, ready: false, pending: Promise.resolve(), pinned: false };
  views.set(contents, state);
  contents.on("did-navigate", () => {
    state.generation++;
    state.key = null;
    state.ready = false;
  });
  contents.on("dom-ready", () => {
    state.ready = true;
    apply(contents, state);
  });
  contents.once("destroyed", () => views.delete(contents));
});

refresh();
fs.watchFile(cssFile, { interval: 1000, persistent: false }, refresh);
app.once("will-quit", () => fs.unwatchFile(cssFile, refresh));
