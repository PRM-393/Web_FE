#!/usr/bin/env bash
# Build Flutter Web cho Vercel. API_BASE_URL dat trong Vercel > Settings > Environment Variables (khong bat buoc);
# bo trong thi dung dia chi BE Render mac dinh trong lib/config/env.dart
set -euo pipefail
ARGS=(build web --release)
if [ -n "${API_BASE_URL:-}" ]; then ARGS+=("--dart-define=API_BASE_URL=$API_BASE_URL"); fi
.flutter-sdk/bin/flutter "${ARGS[@]}"
