#!/bin/bash

# calico_archive.sh
# Usage: ./calico_archive.sh <version> <dockerhub_user>
# Example: ./calico_archive.sh 3.26 spurin
# Requirements: crane, curl, sed, grep, docker login

set -e

# === TOOL CHECK ===
REQUIRED_TOOLS=("crane" "curl" "sed" "grep")
for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v "$tool" &> /dev/null; then
    echo "❌ Error: Required tool '$tool' is not installed or not in PATH."
    exit 1
  fi
done

# === INPUT VALIDATION ===
VERSION="$1"
DOCKERHUB_USER="$2"

if [ -z "$VERSION" ] || [ -z "$DOCKERHUB_USER" ]; then
  echo "❌ Usage: $0 <version> <dockerhub_user>"
  echo "Example:"
  echo "  ./calico_archive.sh 3.26 spurin"
  exit 1
fi

# === CONFIGURATION ===
CALICO_TAG="v${VERSION}.0"
GITHUB_BRANCH="release-v${VERSION}"
YAML_URL="https://raw.githubusercontent.com/projectcalico/calico/${GITHUB_BRANCH}/manifests/calico.yaml"
ORIGINAL_YAML="calico-${VERSION}-original.yaml"
ARCHIVED_YAML="calico-${VERSION}-archived.yaml"
ARCHIVE_REPO="docker.io/${DOCKERHUB_USER}/calico"

# === CROSS-PLATFORM sed IN-PLACE FLAG ===
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE=("sed" "-i" "")
else
  SED_INPLACE=("sed" "-i")
fi

# === DOWNLOAD MANIFEST ===
echo "📥 Downloading Calico manifest from GitHub: $YAML_URL"
curl -s -L "$YAML_URL" -o "$ORIGINAL_YAML"
cp "$ORIGINAL_YAML" "$ARCHIVED_YAML"

# === EXTRACT IMAGES ===
echo "🔍 Extracting image references..."
IMAGES=$(grep 'image: docker.io/calico' "$ORIGINAL_YAML" | awk '{print $2}' | sort -u)

# === COPY IMAGES USING CRANE ===
echo "📦 Copying images to Docker Hub repo: $ARCHIVE_REPO"
for IMAGE in $IMAGES; do
  COMPONENT=$(echo "$IMAGE" | cut -d'/' -f3 | cut -d':' -f1)
  TAG=$(echo "$IMAGE" | cut -d':' -f2)
  NEW_IMAGE="${ARCHIVE_REPO}:${COMPONENT}-${TAG}"

  echo "➡️  $IMAGE → $NEW_IMAGE"
  crane copy "$IMAGE" "$NEW_IMAGE"
done

# === UPDATE MANIFEST ===
echo "✍️  Updating archived manifest with new image paths..."
for IMAGE in $IMAGES; do
  COMPONENT=$(echo "$IMAGE" | cut -d'/' -f3 | cut -d':' -f1)
  TAG=$(echo "$IMAGE" | cut -d':' -f2)
  NEW_IMAGE="${ARCHIVE_REPO}:${COMPONENT}-${TAG}"
  "${SED_INPLACE[@]}" "s|$IMAGE|$NEW_IMAGE|g" "$ARCHIVED_YAML"
done

# === DONE ===
echo ""
echo "✅ Archival complete!"
echo "  Original manifest: $ORIGINAL_YAML"
echo "  Archived manifest: $ARCHIVED_YAML"
