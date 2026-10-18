#!/bin/bash
set -e

echo "Starting Flutter Release Build Test..."
cd app
flutter clean
flutter pub get
flutter build apk --release

echo "Release build verified successfully!"
