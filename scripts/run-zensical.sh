#!/bin/bash

# Script to install Zensical/mike and run the multi-version live server using
# a virtual environment. Uses zensical.toml in the project root, and deploys
# the local working tree as the "dev" version so it shows up alongside any
# other versions already committed to the local gh-pages branch.
# See https://zensical.org/ and https://zensical.org/docs/setup/versioning/

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

VENV_DIR=".venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
    echo "✓ Virtual environment created"
else
    echo "✓ Virtual environment already exists"
fi

echo "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

echo "Upgrading pip..."
pip install --upgrade pip

echo ""
echo "Installing Zensical and mike..."
pip install -r requirements.txt

if ! git config user.email > /dev/null 2>&1; then
    git config user.name "Local Docs Preview"
    git config user.email "docs-preview@local"
fi

echo ""
echo "Building local 'dev' preview version with mike..."
mike deploy --update-aliases dev

echo ""
echo "Starting mike server (multi-version preview, uses zensical.toml)..."
mike serve
