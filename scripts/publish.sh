#!/usr/bin/env bash

set -Eeuo pipefail

cd /opt/o2/o2-infrastructure

echo "📄 Genererer dokumentasjon..."
./scripts/generate-docs.sh

echo "📦 Legger til endringer..."
git add .

if git diff --cached --quiet; then
    echo "✅ Ingen endringer å publisere."
    exit 0
fi

echo "💾 Lager commit..."
git commit -m "Update infrastructure documentation"

echo "🚀 Pusher til GitHub..."
git push origin main

echo "🎉 Ferdig!"
