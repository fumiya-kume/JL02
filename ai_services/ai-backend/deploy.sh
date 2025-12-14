#!/bin/bash

# さくらのクラウド AppRun デプロイスクリプト

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# プロジェクトルートに移動
cd "${PROJECT_ROOT}" || exit 1

echo "Project root: ${PROJECT_ROOT}"
echo "Backend directory: ${SCRIPT_DIR}"
echo ""

# 環境変数チェック
if [ -z "$REGISTRY_HOST" ]; then
    echo "❌ Error: REGISTRY_HOST environment variable is not set"
    echo "Please set REGISTRY_HOST to your container registry host"
    exit 1
fi

if [ -z "$AIBE_IMAGE_NAME" ]; then
    echo "❌ Error: AIBE_IMAGE_NAME environment variable is not set"
    echo "Please set AIBE_IMAGE_NAME to your image name"
    exit 1
fi

# 必要なファイルの確認
echo "=== Checking required files ==="
if [ ! -f "${PROJECT_ROOT}/GinzaDB/ginzaDB.json" ]; then
    echo "❌ Error: GinzaDB/ginzaDB.json not found"
    exit 1
fi
echo "✅ GinzaDB/ginzaDB.json found"

if [ ! -d "${SCRIPT_DIR}/src" ]; then
    echo "❌ Error: src directory not found at ${SCRIPT_DIR}/src"
    exit 1
fi
echo "✅ src directory found"

# コンテナレジストリ情報
TAG="${1:-latest}"

# フルイメージ名
FULL_IMAGE_NAME="${REGISTRY_HOST}/${AIBE_IMAGE_NAME}:${TAG}"

echo "=== Generating requirements.txt from uv dependencies ==="
# uvの依存関係からrequirements.txtを生成
cd "${SCRIPT_DIR}" || exit 1
uv export --format requirements.txt --output-file requirements.txt --no-dev

if [ $? -ne 0 ]; then
    echo "❌ Failed to generate requirements.txt from uv dependencies"
    exit 1
fi

# requirements.txtが生成されたことを確認
if [ ! -f "requirements.txt" ]; then
    echo "❌ requirements.txt was not generated"
    exit 1
fi

echo "✅ requirements.txt generated successfully"
echo ""

echo "=== Building Docker image for AppRun (linux/amd64) ==="
echo "Building from: ${PROJECT_ROOT}"
echo "Using Dockerfile: ${SCRIPT_DIR}/Dockerfile"
echo ""

# プロジェクトルートからビルド（COPYコマンドが正しく機能するため）
docker build --platform linux/amd64 \
    -f "${SCRIPT_DIR}/Dockerfile" \
    -t ${AIBE_IMAGE_NAME} \
    "${PROJECT_ROOT}"

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo ""
echo "=== Tagging image ==="
docker tag ${AIBE_IMAGE_NAME} ${FULL_IMAGE_NAME}

echo ""
echo "=== Logging in to registry ==="
docker login ${REGISTRY_HOST}

if [ $? -ne 0 ]; then
    echo "❌ Login failed"
    exit 1
fi

echo ""
echo "=== Pushing image to registry ==="
docker push ${FULL_IMAGE_NAME}

if [ $? -ne 0 ]; then
    echo "❌ Push failed"
    exit 1
fi

echo ""
echo "✅ Successfully deployed ${FULL_IMAGE_NAME}"
echo ""
echo "Next steps:"
echo "1. Go to さくらのクラウド AppRun console"
echo "2. Create/Update application with image: ${FULL_IMAGE_NAME}"
echo "3. Set port to: 8080"
echo "4. Set health check path to: /health"
