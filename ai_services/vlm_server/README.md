# Vision Language Model 推論サーバー

FastAPIとpyngrokを使用したVision Language Model（VLM）の推論APIサーバーです。画像とテキストを入力として受け取り、生成されたテキストをレスポンスとして返します。

### 1. 依存関係インストール

```bash
pip intall -r requirements.txt
```

### 2. 環境変数の設定（オプション）

```bash
export MODEL_PATH="sbintuitions/sarashina2.2-vision-3b"  # デフォルト
export PORT="8000"                                        # デフォルト
export NGROK_AUTH_TOKEN="your_ngrok_token"               # ngrok使用時
```

## 🏃 サーバーの起動

### uvを使用した起動（推奨）

```bash
# メインスクリプトを直接実行
uv run serve_vlm.py
```

## 📖 API使用方法

### エンドポイント

- `GET /`: ルートエンドポイント（ステータス確認）
- `GET /health`: ヘルスチェック（モデル読み込み状態確認）
- `POST /inference`: VLM推論実行
- `GET /docs`: Swagger API文書（自動生成）

### 推論APIの使用例

#### curlでの使用

```bash
curl -X POST "http://localhost:8000/inference" \
  -F "image=@your_image.jpg" \
  -F "text=この画像について教えてください" \
  -F "temperature=0.7" \
  -F "max_new_tokens=512"
```
