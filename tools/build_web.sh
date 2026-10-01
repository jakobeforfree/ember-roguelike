#!/usr/bin/env bash
# Builds the Web version into build/web. Used by Vercel (see vercel.json) and locally.
set -euo pipefail
GODOT_VERSION="${GODOT_VERSION:-4.3-stable}"
CACHE="${GODOT_CACHE:-$HOME/.cache/godot-$GODOT_VERSION}"
GODOT="$CACHE/Godot_v${GODOT_VERSION}_linux.x86_64"
mkdir -p "$CACHE"
if [ ! -x "$GODOT" ]; then
  echo "Downloading Godot $GODOT_VERSION..."
  curl -sSL -o "$CACHE/godot.zip" "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
  python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$CACHE/godot.zip" "$CACHE"
  chmod +x "$GODOT"
  rm -f "$CACHE/godot.zip"
fi
TPL="$HOME/.local/share/godot/export_templates/${GODOT_VERSION/-/.}/web_nothreads_release.zip"
if [ ! -f "$TPL" ]; then
  echo "Fetching web export templates..."
  python3 tools/fetch_web_templates.py "$GODOT_VERSION"
fi
rm -rf build/web && mkdir -p build/web
"$GODOT" --headless --import >/dev/null 2>&1 || true
"$GODOT" --headless --export-release "Web" build/web/index.html
test -s build/web/index.wasm && test -s build/web/index.pck
cp tools/web_extra/* build/web/
echo "Web build ready: build/web"
