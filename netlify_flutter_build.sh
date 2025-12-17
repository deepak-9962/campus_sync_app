#!/usr/bin/env bash
set -euo pipefail

# Ensure Flutter is available (Netlify build image may need manual install)
if ! command -v flutter >/dev/null 2>&1; then
  echo "Installing Flutter..." >&2
  git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
  export PATH="$HOME/flutter/bin:$PATH"
fi

flutter --version
flutter pub get

# Expect SUPABASE_URL and SUPABASE_ANON_KEY in Netlify env variables
: "${SUPABASE_URL:?SUPABASE_URL not set in Netlify environment}" || exit 1
: "${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY not set in Netlify environment}" || exit 1

echo "Building Flutter web (canvaskit renderer)"
flutter build web --release --web-renderer canvaskit \
  --dart-define=SUPABASE_URL=${SUPABASE_URL} \
  --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}

echo "Build complete. Output in build/web"
