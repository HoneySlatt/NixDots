switch_blender() {
  local blender_dir="$HOME/.config/blender/5.0"
  local preset_dir="$blender_dir/scripts/presets/interface_theme"
  local preset="$preset_dir/Quickshell.py"
  local apply_script="$blender_dir/scripts/apply-quickshell-theme.py"

  mkdir -p "$preset_dir"

  h4() { local h="${1#\#}"; awk "BEGIN{printf \"%.6f, %.6f, %.6f, ${2:-1.0}\", 0x${h:0:2}/255, 0x${h:2:2}/255, 0x${h:4:2}/255}"; }
  h3() { local h="${1#\#}"; awk "BEGIN{printf \"%.6f, %.6f, %.6f\", 0x${h:0:2}/255, 0x${h:2:2}/255, 0x${h:4:2}/255}"; }

  local base;     base=$(h4 "${C[base]}")
  local mantle;   mantle=$(h4 "${C[mantle]}")
  local crust;    crust=$(h4 "${C[crust]}")
  local surf0;    surf0=$(h4 "${C[surface0]}")
  local surf1;    surf1=$(h4 "${C[surface1]}")
  local text4;    text4=$(h4 "${C[text]}")
  local text3;    text3=$(h3 "${C[text]}")
  local sub3;     sub3=$(h3 "${C[subtext0]}")
  local ov3;     ov3=$(h3 "${C[overlay0]}")
  local _accent="${C[accent_ui]:-${C[accent]}}"
  local accent4;  accent4=$(h4 "$_accent")
  local accent3;  accent3=$(h3 "$_accent")
  local red4;     red4=$(h4 "${C[red]}")
  local green4;   green4=$(h4 "${C[green]}")
  local yellow4;  yellow4=$(h4 "${C[yellow]}")

  cat > "$preset" << EOF
import bpy

t  = bpy.context.preferences.themes[0]
ui = t.user_interface

def wcol(w, inner, inner_sel, item, text, text_sel, outline=None):
    w.inner     = inner
    w.inner_sel = inner_sel
    w.item      = item
    w.text      = text
    w.text_sel  = text_sel
    if outline is not None:
        w.outline = outline

base    = ($base)
mantle  = ($mantle)
crust   = ($crust)
surf0   = ($surf0)
surf1   = ($surf1)
text4   = ($text4)
text3   = ($text3)
sub3    = ($sub3)
ov3     = ($ov3)
accent4 = ($accent4)
accent3 = ($accent3)
red4    = ($red4)
green4 = ($green4)
yellow4 = ($yellow4)

# Standard widgets
for w in [ui.wcol_regular, ui.wcol_tool, ui.wcol_toolbar_item,
          ui.wcol_radio, ui.wcol_option, ui.wcol_toggle,
          ui.wcol_num, ui.wcol_numslider, ui.wcol_progress, ui.wcol_curve]:
    wcol(w, surf0, accent4, accent4, text3, text3[:3], mantle)

# Text input
wcol(ui.wcol_text, mantle, mantle, accent4, text3, text3, surf0)

# Box / panel background
wcol(ui.wcol_box, base, surf0, accent4, text3, text3, surf0)

# Tabs
wcol(ui.wcol_tab, mantle, surf1, accent4, sub3, text3, mantle)

# Menus
wcol(ui.wcol_menu,      surf0,  accent4, accent4, text3, text3, surf1)
wcol(ui.wcol_pulldown,  surf0,  accent4, accent4, text3, text3, surf1)
wcol(ui.wcol_menu_back, mantle, surf0,   accent4, text3, text3, surf0)
wcol(ui.wcol_menu_item, (0,0,0,0), accent4, accent4, text3, text3)
wcol(ui.wcol_pie_menu,  mantle, accent4, accent4, text3, text3, surf0)

# Tooltip
wcol(ui.wcol_tooltip, surf0, surf1, accent4, text3, text3, surf1)

# Scrollbar
wcol(ui.wcol_scroll,    base,   surf1, surf1, text3, text3, mantle)

# List items
wcol(ui.wcol_list_item, (0,0,0,0), surf0, accent4, text3, text3)

# 3-tuple versions for RGB-only properties
base3   = base[:3]
mantle3 = mantle[:3]
surf0_3 = surf0[:3]
surf1_3 = surf1[:3]

# Panel backgrounds (back/header = RGBA, text/title = RGB)
ui.panel_back     = base
ui.panel_sub_back = mantle
ui.panel_header   = mantle
ui.panel_text     = text3
ui.panel_title    = text3

# Editor borders
ui.editor_border         = surf0_3   # RGB
ui.editor_outline        = surf1     # RGBA
ui.editor_outline_active = accent4   # RGBA

# Apply header/text to all editor spaces
for area in ['view_3d', 'node_editor', 'properties', 'outliner',
             'file_browser', 'sequence_editor', 'text_editor',
             'nla_editor', 'dopesheet', 'graph_editor',
             'image_editor', 'console', 'info', 'preferences']:
    try:
        space = getattr(t, area).space
        space.header         = mantle  # RGBA
        space.header_text    = text3   # RGB
        space.header_text_hi = accent3 # RGB
        space.text           = text3   # RGB
        space.text_hi        = accent3 # RGB
        space.title          = text3   # RGB
    except Exception:
        pass

# 3D viewport background
t.view_3d.space.gradients.background_type = 'SINGLE_COLOR'
t.view_3d.space.gradients.gradient        = base3
t.view_3d.space.gradients.high_gradient   = base3

# 3D viewport overlay
t.view_3d.grid            = surf0     # RGBA
t.view_3d.object_selected = accent3   # RGB
t.view_3d.object_active   = accent3   # RGB
t.view_3d.wire            = surf1_3   # RGB

# Background for all other editor spaces
for area in ['node_editor', 'outliner', 'sequence_editor', 'graph_editor',
             'nla_editor', 'dopesheet', 'file_browser', 'text_editor',
             'image_editor', 'console', 'info', 'preferences', 'properties']:
    try:
        sp = getattr(t, area).space
        if hasattr(sp, 'back'):
            sp.back = base3
    except Exception:
        pass

# Properties panel highlight color (active object match)
try:
    t.properties.match = accent3
except Exception:
    pass
EOF

  cat > "$apply_script" << EOF
import bpy, os
exec(open(os.path.expanduser('$preset')).read())
bpy.ops.wm.save_userpref()
print("Quickshell theme applied.")
EOF

  if ! pgrep -x blender > /dev/null; then
    blender --background --python "$apply_script" &>/dev/null &
  fi
}