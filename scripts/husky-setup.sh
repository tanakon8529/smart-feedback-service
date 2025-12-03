#!/bin/bash
set -euo pipefail

if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found. Please install Node.js/npm first."
  exit 1
fi

npm install
npm run prepare

echo "Husky installed. If git doesn't run hooks, set hooksPath:"
echo "  git config core.hooksPath .husky"
