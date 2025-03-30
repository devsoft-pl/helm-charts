#!/usr/bin/env bash

set -euo pipefail

# Arguments
REPO_URL="$1"                # Git repository URL (e.g. https://github.com/org/repo.git)
TAG="$2"                     # Git tag to check out (e.g. v1.2.3)
SUBDIR="$3"                  # Path to Helm chart in repo (e.g. charts/mychart)
OUTPUT_DIR="$4"              # Output directory for built chart and index.yaml (e.g. ./gh-pages)
CHART_NAME_OVERRIDE="${5:-}"  # Optional: override chart name from Chart.yaml

# Prepare temporary working directory
TMP_DIR=$(mktemp -d)
REPO_DIR="$TMP_DIR/repo"

cleanup() {
  echo "[*] Cleaning up temporary files"
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "[*] Cloning repository: $REPO_URL (tag: $TAG)"
git clone --depth 1 --branch "$TAG" "$REPO_URL" "$REPO_DIR"

CHART_SRC_PATH="$REPO_DIR/$SUBDIR"

# Extract metadata from Chart.yaml
CHART_NAME=$(grep '^name:' "$CHART_SRC_PATH/Chart.yaml" | awk '{print $2}')
CHART_VERSION=$(grep '^version:' "$CHART_SRC_PATH/Chart.yaml" | awk '{print $2}')
[ -n "$CHART_NAME_OVERRIDE" ] && CHART_NAME="$CHART_NAME_OVERRIDE"

CHART_DEST_DIR="$OUTPUT_DIR/charts/$CHART_NAME"
mkdir -p "$CHART_DEST_DIR"

# Clean old versions of this chart
echo "[*] Removing existing archives for $CHART_NAME-$CHART_VERSION"
rm -f "$CHART_DEST_DIR/$CHART_NAME-"*.tgz

# Package chart
echo "[*] Packaging chart: $CHART_NAME-$CHART_VERSION"
helm package "$CHART_SRC_PATH" --destination "$CHART_DEST_DIR"

# Generate or update index.yaml in OUTPUT_DIR
echo "[*] Generating Helm index.yaml"
helm repo index .  --merge index.yaml

echo "[✓] Chart and index.yaml created successfully"
