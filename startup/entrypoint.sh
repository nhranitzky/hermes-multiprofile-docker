#!/bin/bash
# Docker ENTRYPOINT: initialise environment, generate supervisor configuration, start supervisord.
set -e

HERMES_DATA="${HERMES_HOME:-/opt/data}"
INSTALL_DIR="${INSTALL_DIR:-/opt/hermes}"
SCRIPTS_DIR="/opt/hermes-start"
SUPERVISOR_CONF_DIR="/etc/supervisor/conf.d"

# --- 1. Initialise environment (UID/GID remapping, chown) ---
# remap-ownership.sh runs the setup part only (no exec gosu).
source "$SCRIPTS_DIR/startup/remap-ownership.sh"

# --- 2. Create supervisor configuration directory ---
mkdir -p "$SUPERVISOR_CONF_DIR"

# --- 3. Generate supervisor config for main instance ---
cat > "$SUPERVISOR_CONF_DIR/hermes-main.conf" << EOF
[program:hermes-main]
command=$SCRIPTS_DIR/startup/start.sh gateway run
directory=$HERMES_DATA
user=hermes
autostart=true
autorestart=true
environment=HERMES_HOME="$HERMES_DATA",INSTALL_DIR="$INSTALL_DIR"
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
EOF

# --- 4. Generate supervisor config for each profile ---
if [ -d "$HERMES_DATA/profiles" ]; then
    for profile_dir in "$HERMES_DATA/profiles"/*/; do
        [ -d "$profile_dir" ] || continue
        NAME=$(basename "$profile_dir")
        cat > "$SUPERVISOR_CONF_DIR/hermes-profile-${NAME}.conf" << EOF
[program:hermes-${NAME}]
command=$SCRIPTS_DIR/startup/start.sh -p $NAME gateway run
directory=${profile_dir%/}
user=hermes
autostart=true
autorestart=true
environment=HERMES_HOME="${profile_dir%/}",INSTALL_DIR="$INSTALL_DIR"
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
EOF
        echo "Profile '$NAME' registered: $profile_dir"
    done
fi

# --- 5. Start supervisord ---
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf