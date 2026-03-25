#!/bin/bash
set -e

mkdir -p lambda_package build/deps

# Copy all handlers — no edits needed when adding new Lambdas
find backend -name "*.py" -not -path "*/test/*" | xargs -I{} cp {} lambda_package/

# Only reinstall deps if requirements.txt changed since last build
DEPS_STAMP=build/.deps_installed
if [ ! -f "$DEPS_STAMP" ] || [ requirements.txt -nt "$DEPS_STAMP" ]; then
  echo "Installing dependencies..."
  rm -rf build/deps
  mkdir -p build/deps
  pip install -r requirements.txt --target build/deps/ --quiet
  touch "$DEPS_STAMP"
else
  echo "Dependencies up to date, skipping pip install."
fi

# Always copy cached deps into lambda_package
cp -r build/deps/. lambda_package/

echo "Build complete. Run 'terraform apply' in infra/"
