#!/bin/bash
# Wird von supervisord pro Instanz aufgerufen: Umgebung aufsetzen, hermes starten.
set -e

INSTALL_DIR="${INSTALL_DIR:-/opt/hermes}"

# Handle optionales -p PROFILE Flag (Profil-Instanz)
HERMES_PROFILE=""
if [ "$1" = "-p" ]; then
    HERMES_PROFILE="$2"
    export HERMES_HOME="/opt/data/profiles/$2"
    shift 2
fi
export HERMES_HOME="${HERMES_HOME:-/opt/data}"

# --- Running as hermes from here ---
source "${INSTALL_DIR}/.venv/bin/activate"

# Create essential directory structure.  Cache and platform directories
# (cache/images, cache/audio, platforms/whatsapp, etc.) are created on
# demand by the application — don't pre-create them here so new installs
# get the consolidated layout from get_hermes_dir().
# The "home/" subdirectory is a per-profile HOME for subprocesses (git,
# ssh, gh, npm …).  Without it those tools write to /root which is
# ephemeral and shared across profiles.  See issue #4426.
mkdir -p "$HERMES_HOME"/{cron,sessions,logs,hooks,memories,skills,skins,plans,workspace,home}

# .env
if [ ! -f "$HERMES_HOME/.env" ]; then
    cp "$INSTALL_DIR/.env.example" "$HERMES_HOME/.env"
fi

# config.yaml
if [ ! -f "$HERMES_HOME/config.yaml" ]; then
    cp "$INSTALL_DIR/cli-config.yaml.example" "$HERMES_HOME/config.yaml"
fi

# SOUL.md
if [ ! -f "$HERMES_HOME/SOUL.md" ]; then
    cp "$INSTALL_DIR/docker/SOUL.md" "$HERMES_HOME/SOUL.md"
fi

# Sync bundled skills (manifest-based so user edits are preserved)
if [ -d "$INSTALL_DIR/skills" ]; then
    python3 "$INSTALL_DIR/tools/skills_sync.py"
fi

if [ -n "$HERMES_PROFILE" ]; then
    exec hermes -p "$HERMES_PROFILE" "$@"
else
    exec hermes "$@"
fi
