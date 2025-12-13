# AI Backend - FastAPI on さくらのクラウド AppRun

さくらのクラウド AppRun 共用型で動作する FastAPI アプリケーション

## 構成

```
ai-backend/
├── main.py              # FastAPI アプリケーション
├── requirements.txt     # Python 依存関係
├── Dockerfile          # AppRun 用 Docker イメージ
├── .dockerignore       # Docker ビルドから除外するファイル
├── deploy.sh           # デプロイスクリプト
└── docs/               # ドキュメント
    ├── manual.md       # AppRun デプロイマニュアル
    └── local_info.md   # コンテナレジストリ情報
```

## ローカルでの動作確認

### 必要なもの

- Docker がインストールされていること

### 実行方法

```bash
# イメージをビルド
docker build  linux/amd64 -t ai-backend-apple .

# コンテナを起動
docker run -p 8080:8080 ai-backend-apple

# 別のターミナルで確認
curl http://localhost:8080/
curl http://localhost:8080/health
```

## AppRun へのデプロイ

### 1. デプロイスクリプトを使用する方法（推奨）

```bash
# latest タグでデプロイ
./deploy.sh

# 特定のタグを指定
./deploy.sh v1.0.0
```

### 2. 手動でデプロイする方法

```bash
# 1. linux/amd64 でビルド
docker build --platform linux/amd64 -t ai-backend .

# 2. レジストリにログイン
docker login <ORG>.sakuracr.jp

# 3. タグ付け
docker tag ai-backend <ORG>.sakuracr.jp/ai-backend:latest

# 4. プッシュ
docker push <ORG>.sakuracr.jp/ai-backend:latest
```

### 3. AppRun でアプリケーションを作成

さくらのクラウド コントロールパネルで以下の設定でアプリケーションを作成:

- **コンテナイメージ**: `<ORG>.sakuracr.jp/ai-backend:latest`
- **ポート設定**: `8080`
- **ヘルスチェックパス**: `/health`
- **リソース構成**: 0.5vCPU/1GiB など（要件に応じて）
- **オートスケーリング**: 最小0〜最大10（デフォルト: 最小0/最大1）

詳細は `docs/manual.md` を参照してください。

## エンドポイント

- `GET /` - ルートエンドポイント
- `GET /health` - ヘルスチェック用エンドポイント

## 制限事項

- HTTP/HTTPS のみ対応（WebSocket 非対応）
- 永続ストレージなし
- 独自ドメイン未サポート

詳細は [さくらのクラウド AppRun マニュアル](https://manual.sakura.ad.jp/cloud/apprun/) を参照してください。
