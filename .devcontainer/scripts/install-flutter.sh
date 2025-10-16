#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR="${FLUTTER_DIR:-/workspaces/Alex/flutter}"

if [ ! -d "${FLUTTER_DIR}" ]; then
  mkdir -p "${FLUTTER_DIR}"
fi

if [ ! -x "${FLUTTER_DIR}/bin/flutter" ]; then
  rm -rf "${FLUTTER_DIR}"
  git clone --depth 1 https://github.com/flutter/flutter.git -b stable "${FLUTTER_DIR}"
fi

BASHRC="${HOME}/.bashrc"
touch "${BASHRC}"

if ! grep -q 'export FLUTTER_HOME=' "${BASHRC}"; then
  {
    echo ""
    echo "# Flutter SDK configuration"
    echo "export FLUTTER_HOME=\"${FLUTTER_DIR}\""
    echo 'export PATH="$FLUTTER_HOME/bin:$PATH"'
  } >> "${BASHRC}"
fi

export FLUTTER_HOME="${FLUTTER_DIR}"
export PATH="${FLUTTER_HOME}/bin:${PATH}"