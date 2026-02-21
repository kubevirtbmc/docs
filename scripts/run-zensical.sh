#!/bin/bash

# Script to install Zensical and run the live server using a virtual environment.
# Zensical reads mkdocs.yml natively; see https://zensical.org/

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
echo "Installing Zensical..."
pip install zensical

echo ""
echo "Starting Zensical server (uses mkdocs.yml in project root)..."
zensical serve
