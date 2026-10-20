#!/usr/bin/env bash
# Abhyas: Jules environment setup script
# Paste the contents into Jules > repo > "Initial Setup", then click "Run and Snapshot".
# Keep this lightweight and idempotent. Safe to re-run.
set -euo pipefail

FLUTTER_DIR="$HOME/flutter"
FLUTTER_CHANNEL="stable"

echo "== Node =="
node -v || { echo "Node missing: note in docs/ASSUMPTIONS.md"; }
npm -v || true

echo "== Flutter =="
if [ ! -d "$FLUTTER_DIR" ]; then
  git clone --depth 1 -b "$FLUTTER_CHANNEL" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$FLUTTER_DIR/bin/cache/dart-sdk/bin:$PATH"
flutter --version
flutter config --no-analytics --no-cli-animations || true
flutter config --enable-web || true
flutter precache --web || true

echo "== Project dependencies =="
if [ -f app/pubspec.yaml ]; then
  (cd app && flutter pub get)
fi
if [ -f console/package.json ]; then
  (cd console && npm ci)
fi

echo "== Supabase CLI (optional, for migration linting) =="
if ! command -v supabase >/dev/null 2>&1; then
  npm install -g supabase || echo "Supabase CLI not installed; continue without it."
fi

echo "== Persist PATH for tasks =="
if ! grep -q "flutter/bin" "$HOME/.bashrc" 2>/dev/null; then
  echo "export PATH=\"$FLUTTER_DIR/bin:$FLUTTER_DIR/bin/cache/dart-sdk/bin:\$PATH\"" >> "$HOME/.bashrc"
fi

echo "== Done =="
flutter --version | head -n 1
