#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"
# Respect an explicit XDG configuration; otherwise keep tool writes in /workspace.
if [[ "$repo_dir" == /workspace/* ]]; then
  export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/workspace/.cache/godot/config}"
  export XDG_DATA_HOME="${XDG_DATA_HOME:-/workspace/.cache/godot/data}"
  export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/workspace/.cache/godot/cache}"
  mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"
fi
mkdir -p web/play
if [[ "$(godot --version)" != 4.6.3.stable.* ]]; then
  echo 'Use Godot 4.6.3 stable and its matching Web export templates.' >&2
  exit 1
fi
template_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
if [[ ! -f "$template_data_dir/godot/export_templates/4.6.3.stable/web_nothreads_release.zip" ]]; then
  python3 tools/install_web_templates.py
fi
godot --headless --path godot --editor --import --quit
timeout 30 godot --headless --path godot -- --smoke-test
godot --headless --path godot --export-release Web
python3 tools/verify_web.py --write
