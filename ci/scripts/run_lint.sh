#!/usr/bin/env bash
set -euo pipefail
mkdir -p "artifacts/logs/lint"
python -V || true
node -v || true || echo "Node not installed (this is fine if you don't use JS)."
echo "==> Python linters"
if command -v ruff >/dev/null 2>&1; then ruff check . | tee artifacts/logs/lint/ruff.out; fi
if command -v black >/dev/null 2>&1; then black --check . | tee artifacts/logs/lint/black.out; fi
if command -v flake8 >/dev/null 2>&1; then flake8 . | tee artifacts/logs/lint/flake8.out; fi
if command -v mypy >/dev/null 2>&1; then mypy . | tee artifacts/logs/lint/mypy.out; fi
echo "==> Node linters"
if [ -f "package.json" ]; then
  if npx --yes eslint -v >/dev/null 2>&1; then npx --yes eslint . --max-warnings=0 | tee artifacts/logs/lint/eslint.out; fi
  if npx --yes prettier -v >/dev/null 2>&1; then npx --yes prettier -c "**/*.{js,jsx,ts,tsx,css,md,json,yml,yaml}" | tee artifacts/logs/lint/prettier.out; fi
fi
echo "Lint complete."
