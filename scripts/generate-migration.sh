#!/bin/bash
# Helper script to generate migrations without needing a running database

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
MIGRATIONS_DIR="$REPO_DIR/migrations"
DESC="${1:-create_schema}"

# Build the migrate binary if it doesn't exist
if [ ! -f "$REPO_DIR/bin/migrate" ]; then
    echo "Building migrate binary..."
    mkdir -p "$REPO_DIR/bin"
    cd "$REPO_DIR"
    go build -tags migration -o bin/migrate ./cmd/migrate
fi

# Get the schema SQL from our GORM models
echo "Generating schema from GORM models..."
SCHEMA_SQL=$("$REPO_DIR/bin/migrate")

# Create migrations directory if it doesn't exist
mkdir -p "$MIGRATIONS_DIR"

# Generate timestamp for migration filename (use nanoseconds for uniqueness)
TIMESTAMP=$(date +%Y%m%d%H%M%S%N | head -c 14)
DESC_SNAKE=$(echo "$DESC" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | sed 's/[^a-z0-9_-]//g')
FILENAME="${MIGRATIONS_DIR}/${TIMESTAMP}_${DESC_SNAKE}.sql"

# Write the migration file with comment header
cat > "$FILENAME" << EOF
-- Migration: $DESC
-- Generated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')
-- This migration was auto-generated from GORM models

$SCHEMA_SQL
EOF

echo "✓ Migration created: $FILENAME"
echo ""
echo "Migration file content (first 20 lines):"
head -20 "$FILENAME"

# Update atlas.sum if atlas is available
cd "$REPO_DIR"
if command -v atlas &> /dev/null; then
    atlas migrate hash
    echo "✓ atlas.sum updated"
else
    echo "⚠ Atlas CLI not found. Skipping atlas.sum update."
    echo "  Run: curl -sSf https://atlasgo.sh | sh"
fi
