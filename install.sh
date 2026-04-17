#!/usr/bin/env bash
# install.sh — install skillfetch into a Claude Code project
#
# Usage:
#   ./install.sh                    # installs into current directory
#   ./install.sh /path/to/project   # installs into specified project
#
# What it does:
#   - Symlinks all instruction files from this plugin into
#     <project>/.claude/skills/skillfetch/
#   - Creates a fresh registry.json from the template (if one doesn't exist)
#   - Creates the synced/ directory
#
# Updating to the latest plugin version:
#   cd /path/to/skillfetch && git pull
#   ./install.sh /path/to/project   # re-runs symlinks (safe to re-run)

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-$(pwd)}"
INSTALL_DIR="$PROJECT_DIR/.claude/skills/skillfetch"

echo "Installing skillfetch plugin..."
echo "  Plugin source : $PLUGIN_DIR"
echo "  Project target: $INSTALL_DIR"
echo ""

# Create install layout
mkdir -p "$INSTALL_DIR/references"
mkdir -p "$INSTALL_DIR/evals"
mkdir -p "$INSTALL_DIR/synced"

# Symlink instruction files — managed by plugin, not project
ln -sf "$PLUGIN_DIR/skills/skillfetch/SKILL.md"                        "$INSTALL_DIR/SKILL.md"
ln -sf "$PLUGIN_DIR/skills/skillfetch/security.md"                     "$INSTALL_DIR/security.md"
ln -sf "$PLUGIN_DIR/skills/skillfetch/references/sync.md"              "$INSTALL_DIR/references/sync.md"
ln -sf "$PLUGIN_DIR/skills/skillfetch/references/manage.md"            "$INSTALL_DIR/references/manage.md"
ln -sf "$PLUGIN_DIR/skills/skillfetch/references/directories.md"       "$INSTALL_DIR/references/directories.md"
ln -sf "$PLUGIN_DIR/skills/skillfetch/evals/README.md"                 "$INSTALL_DIR/evals/README.md"

# Create project-local registry from template (only if one doesn't exist yet)
if [[ ! -f "$INSTALL_DIR/registry.json" ]]; then
  TODAY="$(date +%Y-%m-%d)"
  sed "s/\"last_updated\": \"\"/\"last_updated\": \"$TODAY\"/" \
    "$PLUGIN_DIR/registry.template.json" > "$INSTALL_DIR/registry.json"
  echo "  Created registry.json"
else
  echo "  registry.json already exists — skipped"
fi

echo ""
echo "Done. skillfetch is installed at:"
echo "  $INSTALL_DIR"
echo ""
echo "Next steps:"
echo "  1. Reference the skill in your CLAUDE.md (if not already):"
echo "     The skill auto-loads from .claude/skills/skillfetch/SKILL.md"
echo ""
echo "  2. Start adding repos (examples):"
echo "     /skillfetch add-repo https://github.com/android/skills"
echo "     /skillfetch add-repo https://github.com/affaan-m/everything-claude-code"
echo ""
echo "  3. Commit registry.json and synced/ to your project (optional but recommended)."
echo "     Symlinks pointing to $PLUGIN_DIR are machine-local — do not commit them."
echo "     Add to your project .gitignore:"
echo "       .claude/skills/skillfetch/SKILL.md"
echo "       .claude/skills/skillfetch/security.md"
echo "       .claude/skills/skillfetch/references/"
echo "       .claude/skills/skillfetch/evals/"
