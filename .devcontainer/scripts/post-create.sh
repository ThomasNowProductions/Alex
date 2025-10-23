#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Ensure Flutter is installed and environment variables are configured.
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/install-flutter.sh"

export FLUTTER_HOME="${FLUTTER_HOME:-/usr/local/flutter}"
export PATH="${FLUTTER_HOME}/bin:${PATH}"

# Enable Flutter web support and download required artifacts.
flutter config --enable-web
flutter precache --web --linux-desktop

# Accept Android SDK licenses if the sdkmanager is available.
if command -v sdkmanager >/dev/null 2>&1; then
  yes | sdkmanager --licenses >/tmp/android-sdk-licenses.log
fi

# Fetch project dependencies.
(cd "${REPO_ROOT}" && flutter pub get)

# Provide a quick health check to surface potential issues early.
flutter doctor -v
