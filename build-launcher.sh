#!/bin/bash
# Automate the build process of a launcher wrapper for the top-level script.

set -e

APP_NAME="Discord Status Logger"

PROJECT_DIR="$(realpath "$(dirname "$0")")"

SRC_SCRIPT="${PROJECT_DIR}/src/status.applescript"
LAUNCHER_SCRIPT="${PROJECT_DIR}/build/launcher.applescript"
APP_OUT="${PROJECT_DIR}/${APP_NAME}.app"

mkdir -p "$(dirname "${LAUNCHER_SCRIPT}")"

echo "$0: generating launcher AppleScript..."

cat > "${LAUNCHER_SCRIPT}" << EOF
-- Automatically generated launcher script.
set projectDir to "$(dirname "${SRC_SCRIPT}")"
set scriptPath to projectDir & "/status.applescript"
do shell script "cd " & quoted form of projectDir & " && " & quoted form of scriptPath
EOF

if [ -d "${APP_OUT}" ]; then
    echo "$0: removing previous app..."
    rm -rf "${APP_OUT}"
fi

echo "$0: compiling .app launcher..."
osacompile -o "${APP_OUT}" "${LAUNCHER_SCRIPT}"

echo "$0: app created at: ${APP_OUT}"
