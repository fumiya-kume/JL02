# AI Backend - FastAPI on さくらのクラウド AppRun

さくらのクラウド AppRun 共用型で動作する FastAPI アプリケーション

Vision-Language Model (VLM) の推論結果に基づいて、ユーザーの属性に合わせた観光ガイド情報をRAG（検索拡張生成）で生成します。

## 主な機能

- **VLM推論**: 画像からランドマークの説明を抽出
- **RAG統合**: Sakura AI Engine RAGで観光スポット情報を検索・生成
- **マルチ言語対応**: Japanese, English, Chinese, Korean, Spanish, French, German, Thai
- **ユーザー属性対応**: 年齢層、予算、興味、活動レベルに基づいたパーソナライズ
- **位置情報ベースの検索**: GinzaDBで最寄りの観光地を取得

## 構成

```
ai-backend/
├── src/
│   ├── main.py                  # FastAPI アプリケーション (VLM + RAG連携)
│   └── location_db_lookup.py    # 位置情報ベースの観光地検索
├── requirements.txt             # Python 依存関係
├── Dockerfile                   # AppRun 用 Docker イメージ (GinzaDB埋め込み)
├── .dockerignore                # Docker ビルドから除外するファイル
├── deploy.sh                    # デプロイスクリプト
└── docs/                        # ドキュメント
    ├── manual.md                # AppRun デプロイマニュアル
    └── local_info.md            # コンテナレジストリ情報
```

## ローカルでの動作確認

### 必要なもの

- Python 3.12+
- Docker (コンテナテスト時)
- VLM APIエンドポイント (`NGROK_DOMAIN` 環境変数)
- Sakura AI Engine APIトークン (`SAKURA_OPENAI_API_TOKEN` 環境変数)

### 環境変数設定

```bash
export NGROK_DOMAIN=your-ngrok-domain.ngrok-free.app
export SAKURA_OPENAI_API_TOKEN=your-api-token
```

### 実行方法(ローカル)

```bash
# 依存関係をインストール
uv sync

# FastAPI サーバーを起動
uv run uvicorn src.main:app --host 0.0.0.0 --reload
```

ローカルサーバーにアクセス: http://localhost:8000

### 実行方法(コンテナ)

```bash
# プロジェクトルートから実行
cd /path/to/project/root

# Docker イメージをビルド (GinzaDBを埋め込み)
docker build \
    -f ai_services/ai-backend/Dockerfile \
    -t ai-backend:latest \
    .

# コンテナを起動
docker run -p 8080:8080 \
    -e NGROK_DOMAIN=your-ngrok-domain.ngrok-free.app \
    -e SAKURA_OPENAI_API_TOKEN=your-api-token \
    ai-backend:latest

# 別のターミナルで確認
curl http://localhost:8080/
curl http://localhost:8080/health
```

### 推論エンドポイントのテスト

```bash
curl -X POST http://localhost:8000/inference \
  -F "image=@path/to/image.jpg" \
  -F "user_age_group=30-40s" \
  -F "user_budget_level=mid-range" \
  -F "user_interests=history" \
  -F "user_activity_level=moderate" \
  -F "user_language=japanese" \
  -F "address=Tokyo, Japan" \
  -F "latitude=35.6762" \
  -F "longitude=139.6503"
```

## AppRun へのデプロイ

### 1. デプロイスクリプトを使用する方法（推奨）

```bash
# プロジェクトルートで実行
export REGISTRY_HOST=your-registry.sakuracr.jp
export AIBE_IMAGE_NAME=your-app-name

# latest タグでデプロイ
./ai_services/ai-backend/deploy.sh

# 特定のタグを指定
./ai_services/ai-backend/deploy.sh v1.0.0
```

デプロイスクリプトは以下の処理を自動実行します:
- GinzaDB と src ディレクトリの存在確認
- requirements.txt の生成
- Docker イメージのビルド（プロジェクトルートコンテキスト）
- レジストリへのプッシュ

### 2. 手動でデプロイする方法

```bash
# 1. プロジェクトルートから linux/amd64 でビルド
docker build --platform linux/amd64 \
    -f ai_services/ai-backend/Dockerfile \
    -t your-registry.sakuracr.jp/ai-backend:latest \
    .

# 2. レジストリにログイン
docker login your-registry.sakuracr.jp

# 3. プッシュ
docker push your-registry.sakuracr.jp/ai-backend:latest
```

### 3. AppRun でアプリケーションを作成

さくらのクラウド コントロールパネルで以下の設定でアプリケーションを作成:

**基本設定**
- **コンテナイメージ**: `your-registry.sakuracr.jp/your-app-name:latest`
- **ポート設定**: `8080`
- **ヘルスチェックパス**: `/health`

**環境変数**
- `NGROK_DOMAIN`: VLM APIエンドポイント（例: `xxxxx.ngrok-free.app`）
- `SAKURA_OPENAI_API_TOKEN`: Sakura AI Engine APIトークン

**リソース構成**
- **CPU/メモリ**: 0.5vCPU/1GiB 以上推奨
- **オートスケーリング**: 最小0〜最大10（デフォルト: 最小0/最大1）

詳細は `docs/manual.md` を参照してください。

## エンドポイント

### ヘルスチェック

- `GET /` - ルートエンドポイント
  ```json
  { "message": "Hello from AppRun + FastAPI" }
  ```

- `GET /health` - ヘルスチェック用エンドポイント
  ```json
  { "status": "ok" }
  ```

### VLM推論 + RAG統合

- `POST /inference` - 画像推論とガイド生成

**リクエスト (multipart/form-data)**
```
image: ファイル                           (必須)
address: 文字列                          (必須)
latitude: 浮動小数点数                    (必須)
longitude: 浮動小数点数                   (必須)
user_age_group: "20s" | "30-40s" | "50s+" | "family_with_kids"  (オプション)
user_budget_level: "budget" | "mid-range" | "luxury"             (オプション)
user_interests: "history" | "nature" | "art" | "food" | "architecture" | "shopping" | "nightlife"  (複数選択可, オプション)
user_activity_level: "active" | "moderate" | "relaxed"           (オプション)
user_language: "japanese" | "english" | "chinese" | "korean" | "spanish" | "french" | "german" | "thai"  (デフォルト: "japanese")
text: 文字列                             (オプション)
temperature: 浮動小数点数               (デフォルト: 0.7)
top_p: 浮動小数点数                     (デフォルト: 0.99)
max_new_tokens: 整数                    (デフォルト: 128)
repetition_penalty: 浮動小数点数        (デフォルト: 1.05)
```

**レスポンス**
```json
{
  "generated_text": "観光ガイド情報（RAGで生成）",
  "success": true,
  "error_message": null
}
```

**処理フロー**
1. 画像をVLM APIに送信して説明を抽出
2. ユーザー属性 + 画像説明でRAGクエリを構築
3. Sakura AI Engine RAGで観光情報を検索・生成
4. 指定言語で結果を返却（RAG失敗時はVLMの説明をフォールバック）

## 制限事項

- HTTP/HTTPS のみ対応（WebSocket 非対応）
- 永続ストレージなし
- 独自ドメイン未サポート

詳細は [さくらのクラウド AppRun マニュアル](https://manual.sakura.ad.jp/cloud/apprun/) を参照してください。

## Docker イメージについて

### GinzaDB の埋め込み

Dockerfile はプロジェクトルートからのビルドを前提としており、以下のファイルを自動的にコンテナに組み込みます:

```
COPY ai_services/ai-backend/src ./src          # アプリケーションコード
COPY GinzaDB ./GinzaDB                         # 観光地データベース
```

これにより、LocationDBLookup は実行時に GinzaDB/ginzaDB.json を自動的に検出できます。

### ビルドコンテキスト

**重要**: Docker イメージは常にプロジェクトルートからビルドしてください:

```bash
# ✅ 正しい方法
docker build -f ai_services/ai-backend/Dockerfile -t ai-backend:latest .

# ❌ 間違った方法
cd ai_services/ai-backend
docker build -t ai-backend:latest .
```

ai-backend ディレクトリからビルドすると、GinzaDB と src への COPY パスが失敗します。

## トラブルシューティング

### LocationDBLookup: Could not find tourist spots database

**原因**: GinzaDB/ginzaDB.json がコンテナに含まれていない

**解決法**:
- プロジェクトルートからビルドしているか確認
- Dockerfile のプロジェクトルートからの相対パスを確認
- `docker build -f ai_services/ai-backend/Dockerfile .` コマンドを使用

### RAG API エラー

**環境変数の確認**:
```bash
echo $SAKURA_OPENAI_API_TOKEN
echo $NGROK_DOMAIN
```

トークンが正しく設定されているか確認してください。

### VLM API エラー

**NGROK_DOMAIN の確認**:
- ngrok トンネルが起動しているか確認
- ドメインが `https://` ではなく、ドメイン名のみか確認（例: `xxxxx.ngrok-free.app`）
