#!/usr/bin/env bash
# Vercel khong co san Flutter: tai Flutter dung phien ban nhom dang dung (khop CI) vao thu muc .flutter-sdk
set -euo pipefail
FLUTTER_VERSION="3.47.3"
command -v unzip >/dev/null 2>&1 || (dnf install -y unzip xz >/dev/null 2>&1 || yum install -y unzip xz >/dev/null 2>&1 || true)
if [ ! -x .flutter-sdk/bin/flutter ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git .flutter-sdk
fi
.flutter-sdk/bin/flutter config --no-analytics --enable-web >/dev/null
.flutter-sdk/bin/flutter --version
.flutter-sdk/bin/flutter pub get
