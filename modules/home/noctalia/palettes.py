"""Build Noctalia palettes from the existing application palette source."""
import json
from pathlib import Path
import subprocess
import sys


def foreground(color):
    rgb = [int(color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in rgb]
    luminance = sum(v * w for v, w in zip(linear, (0.2126, 0.7152, 0.0722)))
    return "#000000" if luminance > 0.179 else "#ffffff"


def palette(source, name):
    script = '''declare -A C; source "$1"; load_palette "$2" || exit
for key in "${!C[@]}"; do printf '%s=%s\\n' "$key" "${C[$key]}"; done'''
    values = subprocess.check_output(["bash", "-c", script, "palette", str(source), name], text=True)
    c = dict(line.split("=", 1) for line in values.splitlines())
    primary = "#3a3a3a" if name == "carbonfox" else c["accent"]
    roles = {
        "primary": primary, "secondary": c["teal"], "tertiary": c["mauve"],
        "error": c["red"], "surface": c["base"], "on_surface": c["text"],
        "surface_container": c["surface0"], "on_surface_variant": c["subtext0"],
        "outline_variant": c["surface1"], "shadow": c["crust"],
        "hover": c["surface1"], "on_hover": c["text"],
    }
    for key in ("primary", "secondary", "tertiary", "error"):
        roles["on_" + key] = foreground(roles[key])
    # Noctalia rejects a palette file whose mode has no terminal section.
    ansi = {"red": c["red"], "green": c["green"], "yellow": c["yellow"], "blue": c["blue"],
            "magenta": c["mauve"], "cyan": c["teal"]}
    roles["terminal"] = {
        "background": c["base"], "foreground": c["text"], "cursor": c["text"], "cursor_text": c["base"],
        "selection_bg": c["surface2"], "selection_fg": c["text"],
        "normal": {"black": c["surface1"], "white": c["subtext0"], **ansi},
        "bright": {"black": c["surface2"], "white": c["text"], **ansi},
    }
    return {"version": 2, "dark": roles, "light": roles}


if __name__ == "__main__":
    source, metadata, target = map(Path, sys.argv[1:])
    target.mkdir(parents=True, exist_ok=True)
    for name in json.loads(metadata.read_text()):
        (target / (name + ".json")).write_text(json.dumps(palette(source, name), indent=2) + "\n")
