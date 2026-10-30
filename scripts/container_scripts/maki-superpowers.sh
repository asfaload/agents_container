# Install or update Superpowers for Maki.
#
# Mirrors opencode-superpowers.sh:
#   - checkout obra/superpowers for the skills
#   - checkout rbauduin/maki-superpowers for the plugin
#   - load the plugin from the Maki config directory
#   - prime the skill links so Maki's `skill` tool sees them at startup
#
# Runs at container start, before Maki. Idempotent: safe on every boot.

MAKI_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/maki"
if [ -d "$HOME/.maki" ]; then
  MAKI_CONFIG="$HOME/.maki"
fi

SUPERPOWERS_DIR="$MAKI_CONFIG/superpowers"
PLUGIN_SRC="$MAKI_CONFIG/source/maki-superpowers"
PLUGIN_REPO="https://github.com/rbauduin/maki-superpowers.git"
SUPERPOWERS_REPO="https://github.com/obra/superpowers.git"

mkdir -p "$MAKI_CONFIG" "$MAKI_CONFIG/source" "$MAKI_CONFIG/lua" "$MAKI_CONFIG/skills"

# 1. Superpowers skills checkout.
if [ -d "$SUPERPOWERS_DIR/.git" ]; then
  git -C "$SUPERPOWERS_DIR" pull --ff-only
else
  rm -rf "$SUPERPOWERS_DIR"
  git clone "$SUPERPOWERS_REPO" "$SUPERPOWERS_DIR"
fi

# 2. Maki plugin checkout.
if [ -d "$PLUGIN_SRC/.git" ]; then
  git -C "$PLUGIN_SRC" pull --ff-only
else
  rm -rf "$PLUGIN_SRC"
  git clone "$PLUGIN_REPO" "$PLUGIN_SRC"
fi

# 3. Load the plugin from init.lua.
if [ -f "$PLUGIN_SRC/lua/superpowers.lua" ]; then
  ln -sfn "$PLUGIN_SRC/lua/superpowers.lua" "$MAKI_CONFIG/lua/superpowers.lua"

  if [ ! -f "$MAKI_CONFIG/init.lua" ]; then
    printf 'require("superpowers")\n' > "$MAKI_CONFIG/init.lua"
  elif ! grep -Eq '^[[:space:]]*require\(["'\'']superpowers["'\'']\)' "$MAKI_CONFIG/init.lua"; then
    printf '\nrequire("superpowers")\n' >> "$MAKI_CONFIG/init.lua"
  fi

  # A user-written plugin.toml grants every key it does not revoke, so only
  # seed one when there is none.
  if [ ! -f "$MAKI_CONFIG/plugin.toml" ]; then
    cp "$PLUGIN_SRC/plugin.toml" "$MAKI_CONFIG/plugin.toml"
  fi
else
  echo "maki-superpowers: plugin checkout unavailable; leaving the config unchanged." >&2
fi

# 4. Prime the skill links so the native skill tool lists them on startup.
if [ -d "$SUPERPOWERS_DIR/skills" ]; then
  rm -f "$MAKI_CONFIG/skills"/superpowers-*
  for skill in "$SUPERPOWERS_DIR"/skills/*/; do
    [ -f "$skill/SKILL.md" ] || continue
    skill="${skill%/}"
    ln -sfn "$skill" "$MAKI_CONFIG/skills/superpowers-$(basename "$skill")"
  done
fi

echo "Maki Superpowers installed. Start Maki and run /superpowers to verify."
