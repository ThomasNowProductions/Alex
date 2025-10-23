#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

DEFAULT_FLUTTER_DIR="/usr/local/flutter"
WORKSPACE_FLUTTER_DIR="${WORKSPACE_FLUTTER_DIR:-${REPO_ROOT}/.flutter-sdk}"

if [ -n "${FLUTTER_DIR:-}" ]; then
  TARGET_DIR="${FLUTTER_DIR}"
elif [ -x "${DEFAULT_FLUTTER_DIR}/bin/flutter" ]; then
  TARGET_DIR="${DEFAULT_FLUTTER_DIR}"
else
  TARGET_DIR="${WORKSPACE_FLUTTER_DIR}"
fi

FLUTTER_DIR="${TARGET_DIR}"

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
