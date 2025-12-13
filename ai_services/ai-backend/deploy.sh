#!/bin/bash

# さくらのクラウド AppRun デプロイスクリプト

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

# コンテナレジストリ情報
TAG="${1:-latest}"

# フルイメージ名
FULL_IMAGE_NAME="${REGISTRY_HOST}/${AIBE_IMAGE_NAME}:${TAG}"

echo "=== Generating requirements.txt from uv dependencies ==="
# uvの依存関係からrequirements.txtを生成
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
docker build --platform linux/amd64 -t ${AIBE_IMAGE_NAME} .

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
