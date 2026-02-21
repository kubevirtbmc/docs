#!/bin/bash

# Script to clean up MkDocs virtual environment and generated files

set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Change to project root directory (one level up from scripts/)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

VENV_DIR=".venv"
SITE_DIR="site"

echo "Cleaning up MkDocs environment..."

# Remove virtual environment
if [ -d "$VENV_DIR" ]; then
    echo "Removing virtual environment..."
    rm -rf "$VENV_DIR"
    echo "✓ Virtual environment removed"
else
    echo "✓ Virtual environment not found (already clean)"
fi

# Remove generated site directory
if [ -d "$SITE_DIR" ]; then
    echo "Removing generated site directory..."
    rm -rf "$SITE_DIR"
    echo "✓ Site directory removed"
else
    echo "✓ Site directory not found (already clean)"
fi

echo ""
echo "Cleanup complete!"

