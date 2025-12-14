# Sakura AI Engine RAG Implementation

銀座観光スポットデータ（GinzaDB）を使用したSakura AI EngineのRAG（検索拡張生成）実装ガイド

## 概要

このプロジェクトでは、Sakura AI Engineの RAG API を使用して、GinzaDB/ginzaDB.jsonに含まれる銀座の観光スポット情報を検索可能にしています。

## セットアップ

### 必須要件

- Python 3.7以上
- Sakura AI Engine APIトークン

### 環境変数の設定

```bash
export SAKURA_OPENAI_API_TOKEN='<your-api-token>'
```

APIトークンは[Sakuraクラウドコンソール](https://console.ai.sakura.ad.jp/)から取得できます。

---

## Step 1: ドキュメントのアップロード

GinzaDB/ginzaDB.jsonをSakura AI Engineの RAG データベースにアップロードします。

### 実行方法

```bash
python3 ai_services/rag_maker/step1_upload_documents.py
```

### スクリプトの詳細

**ファイル**: `step1_upload_documents.py`

**処理内容**:
1. GinzaDB/ginzaDB.jsonから20個の銀座観光スポットを読み込む
2. **各観光スポット**を個別のテキストファイルとして作成:
   - ファイル名: `{番号:02d}_{観光地名}.txt` (例: `01_銀座和光.txt`)
   - 内容形式:
     ```
     名前: <観光地名>
     住所: <住所>
     説明: <説明>
     緯度: <緯度>
     経度: <経度>
     ```
3. 各ファイルを個別に `multipart/form-data` 形式でSakura RAG APIにアップロード
4. アップロード結果をサマリーで表示

**使用ライブラリ**:
- `json`: JSON処理
- `urllib`: HTTP通信（標準ライブラリのみ）
- `logging`: ログ出力
- `tempfile`: テンポラリファイル処理

### 実行結果例

```
2025-12-13 19:55:42,736 - INFO - ============================================================
2025-12-13 19:55:42,736 - INFO - Step 1: Upload GinzaDB to Sakura AI Engine RAG
2025-12-13 19:55:42,736 - INFO - ============================================================
2025-12-13 19:55:42,736 - INFO - API token loaded from environment variable
2025-12-13 19:55:42,736 - INFO - Successfully loaded GinzaDB from ...ginzaDB.json
2025-12-13 19:55:42,736 - INFO - Found 20 tourist spots
2025-12-13 19:55:42,736 - INFO - Preparing 20 individual document files...
2025-12-13 19:55:42,737 - INFO - [1/20] Uploading: 01_銀座和光.txt
2025-12-13 19:55:42,737 - INFO - Uploading file: 01_銀座和光.txt
2025-12-13 19:55:43,538 - INFO - Upload successful! Response status: 201
2025-12-13 19:55:43,538 - INFO - Response: {
  "id": "8e2f00c9-87cd-49c6-8298-faf298c1b4f5",
  "status": "pending",
  "content": "",
  "name": "01_銀座和光.txt",
  "tags": [],
  "model": "multilingual-e5-large"
}
2025-12-13 19:55:43,538 - INFO -   ✓ Success! Document ID: 8e2f00c9-87cd-49c6-8298-faf298c1b4f5
[... 中略: 02_歌舞伎座.txt 〜 19_東京ミッドタウン日比谷.txt ...]
2025-12-13 19:55:48,455 - INFO - [20/20] Uploading: 20_皇居外苑.txt
2025-12-13 19:55:48,455 - INFO - Uploading file: 20_皇居外苑.txt
2025-12-13 19:55:48,455 - INFO - Upload successful! Response status: 201
2025-12-13 19:55:48,455 - INFO -   ✓ Success! Document ID: f84f2104-81c1-4252-935d-f8fc9da95d86
2025-12-13 19:55:48,459 - INFO - ============================================================
2025-12-13 19:55:48,460 - INFO - Upload Summary:
2025-12-13 19:55:48,460 - INFO - ============================================================
2025-12-13 19:55:48,460 - INFO - Total documents: 20
2025-12-13 19:55:48,460 - INFO - Successful: 20
2025-12-13 19:55:48,460 - INFO - Failed: 0
2025-12-13 19:55:48,460 - INFO -
Successfully uploaded documents:
2025-12-13 19:55:48,460 - INFO -   - 銀座和光: 8e2f00c9-87cd-49c6-8298-faf298c1b4f5
2025-12-13 19:55:48,460 - INFO -   - 歌舞伎座: cca2d61b-6cee-45d5-81bb-0468656d6553
2025-12-13 19:55:48,460 - INFO -   - GINZA SIX: c0bbd1f9-7d0c-47b7-a2d3-0d246060e86e
2025-12-13 19:55:48,460 - INFO -   - 東急プラザ銀座: b9386d86-c6f2-4d05-ba47-dbcbb2b78529
[... 中略 ...]
2025-12-13 19:55:48,460 - INFO -   - 皇居外苑: f84f2104-81c1-4252-935d-f8fc9da95d86
2025-12-13 19:55:48,460 - INFO - ============================================================
```

**アップロード結果サマリー**:
- **総ドキュメント数**: 20
- **成功**: 20
- **失敗**: 0
- **モデル**: `multilingual-e5-large`

**各ファイルのDocument ID**（一部例）:
| 観光地 | Document ID |
|--------|-------------|
| 銀座和光 | 8e2f00c9-87cd-49c6-8298-faf298c1b4f5 |
| 歌舞伎座 | cca2d61b-6cee-45d5-81bb-0468656d6553 |
| GINZA SIX | c0bbd1f9-7d0c-47b7-a2d3-0d246060e86e |
| 松屋銀座 | 855b8845-2650-4f44-8cb0-04112fd850db |
| 銀座三越 | 4bdeed07-475a-4c1a-a042-af690404ed58 |
| 皇居外苑 | f84f2104-81c1-4252-935d-f8fc9da95d86 |

---

## Step 2: RAG検索の実行

Step 1でアップロードした20個の個別ドキュメントに対してRAG検索を実行します。

**重要**: Step 1で各観光スポットが個別ファイル（例: `01_銀座和光.txt`, `02_歌舞伎座.txt`など）としてアップロードされるため、RAG検索の際には関連する複数のドキュメントから正確な情報を取得できます。

### Step 2-1: curlコマンドでの確認

```bash
curl -X POST \
  -H "Accept: application/json" \
  -H "Authorization: Bearer ${SAKURA_OPENAI_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "model":"multilingual-e5-large",
    "chat_model":"gpt-oss-120b",
    "query":"銀座の有名な百貨店はどこですか？",
    "top_k":3,
    "threshold":0.3
  }' \
  https://api.ai.sakura.ad.jp/v1/documents/chat/
```

#### リクエストパラメータ

| パラメータ | 値 | 説明 |
|-----------|-----|------|
| `model` | `multilingual-e5-large` | 埋め込みモデル |
| `chat_model` | `gpt-oss-120b` | 応答生成用LLM |
| `query` | 質問文 | 日本語での質問 |
| `top_k` | 3 | 取得するチャンク数 |
| `threshold` | 0.3 | 類似度の閾値 |

#### レスポンス例（個別ドキュメント版）

```json
{
  "answer": "銀座にある有名な百貨店としては、次の3つが代表的です。\n\n1. **銀座和光** – 銀座のシンボル的な老舗百貨店。時計塔が目印で、高級時計や宝飾品を中心に取り扱っています。\n2. **銀座三越** – 銀座4丁目に位置する老舗百貨店。幅広いファッション・食品・生活雑貨が揃います。\n3. **松屋銀座** – 銀座3丁目の老舗百貨店。地下の食品売り場や文化イベントで特に有名です。",
  "sources": [
    {
      "document": {
        "id": "855b8845-2650-4f44-8cb0-04112fd850db",
        "created_at": "2025-12-13T19:55:44.xxx+09:00",
        "status": "available",
        "name": "07_松屋銀座.txt",
        "model": "multilingual-e5-large"
      },
      "chunk_index": 0,
      "distance": 0.1490,
      "content": "名前: 松屋銀座\n住所: 東京都中央区銀座3-6-1\n説明: 銀座3丁目の老舗百貨店。地下の食品売り場と文化イベントで知られる..."
    },
    {
      "document": {
        "id": "4bdeed07-475a-4c1a-a042-af690404ed58",
        "created_at": "2025-12-13T19:55:45.xxx+09:00",
        "status": "available",
        "name": "05_銀座三越.txt",
        "model": "multilingual-e5-large"
      },
      "chunk_index": 0,
      "distance": 0.1502,
      "content": "名前: 銀座三越\n住所: 東京都中央区銀座4-6-16\n説明: 銀座4丁目に位置する老舗百貨店。ライオン像が目印で、ファッションからグルメまで幅広い品揃え..."
    },
    {
      "document": {
        "id": "8e2f00c9-87cd-49c6-8298-faf298c1b4f5",
        "created_at": "2025-12-13T19:55:43.xxx+09:00",
        "status": "available",
        "name": "01_銀座和光.txt",
        "model": "multilingual-e5-large"
      },
      "chunk_index": 0,
      "distance": 0.1571,
      "content": "名前: 銀座和光\n住所: 東京都中央区銀座4-5-11\n説明: 銀座のシンボル的な老舗百貨店。時計塔が有名で、高級時計や宝飾品を扱う..."
    }
  ]
}
```

**ポイント**: 各ドキュメントが個別ファイル（例: `01_銀座和光.txt`, `05_銀座三越.txt`, `07_松屋銀座.txt`）として記録されているため、質問に関連した複数の正確な情報源から回答が生成されます。

### Step 2-2: Pythonスクリプトでの実行

**ファイル**: `step2_query_rag.py`

```bash
python3 ai_services/rag_maker/step2_query_rag.py
```

#### スクリプトの詳細

**処理内容**:
1. APIトークンを環境変数から読み込む
2. 3つの例示クエリを順次実行
   - 「銀座の有名な百貨店はどこですか？」
   - 「銀座で美術館や文化施設はありますか？」
   - 「銀座で買い物ができる商業施設を教えてください」
3. 各クエリの回答とソース情報をフォーマットして出力

**使用ライブラリ**:
- `json`: JSON処理
- `urllib`: HTTP通信（標準ライブラリのみ）
- `logging`: ログ出力

#### 実行結果例

**Query 1**: 「銀座の有名な百貨店はどこですか？」

```
============================================================
RAG ANSWER:
============================================================

銀座にある有名な百貨店として、参考文書に記載されているものは次のとおりです。

| 店名 | 住所（参考） | 特徴 |
|------|--------------|------|
| **松屋銀座** | 東京都中央区銀座3丁目 | 銀座3丁目にある老舗百貨店。地下の食品売り場や文化イベントで知られています。 |
| **銀座和光** | 東京都中央区銀座4丁目 | 銀座のシンボル的な老舗百貨店。時計塔が有名で、高級時計や宝飾品を取り扱っています。 |
| **銀座三越** | 東京都中央区銀座4丁目 | 銀座4丁目に位置する老舗百貨店。 |

（※ 「GINZA SIX」や「東急プラザ銀座」も大型商業施設ですが、文書では「百貨店」とは明記されていません。）

============================================================
SOURCES:
============================================================

[1] Document: 07_松屋銀座.txt
    ID: 855b8845-2650-4f44-8cb0-04112fd850db
    Status: available
    Model: multilingual-e5-large
    Chunk Index: 0
    Similarity Distance: 0.1490
    Content Preview: 名前: 松屋銀座
住所: 東京都中央区銀座3-6-1
説明: 銀座3丁目の老舗百貨店。...

[2] Document: 05_銀座三越.txt
    ID: 4bdeed07-475a-4c1a-a042-af690404ed58
    Status: available
    Model: multilingual-e5-large
    Chunk Index: 0
    Similarity Distance: 0.1502
    Content Preview: 名前: 銀座三越
住所: 東京都中央区銀座4-6-16
説明: 銀座4丁目に位置する老舗百貨店。...

[3] Document: 01_銀座和光.txt
    ID: 8e2f00c9-87cd-49c6-8298-faf298c1b4f5
    Status: available
    Model: multilingual-e5-large
    Chunk Index: 0
    Similarity Distance: 0.1571
    Content Preview: 名前: 銀座和光
住所: 東京都中央区銀座4-5-11
説明: 銀座のシンボル的な老舗百貨店。...
```

**Query 2**: 「銀座で美術館や文化施設はありますか？」

```
============================================================
RAG ANSWER:
============================================================

はい、銀座エリアには美術館や文化施設がいくつかあります。文書に記載されている主な施設は以下の通りです。

| 施設名 | 住所 | 内容 |
|---|---|---|
| **ポーラミュージアムアネックス** | 東京都中央区銀座1‑7 ポーラ銀座ビル3階 | 現代アートギャラリー。スタイリッシュな高層ビル内で企画展を開催し、無料入場です。 |
| **歌舞伎座** | 東京都中央区銀座4‑12‑15 | 伝統的な日本の演劇を鑑賞できる劇場。歌舞伎公演を定期開催し、売店やレストランも併設。バリアフリー対応。 |
| **銀座ソニーパーク** | 東京都中央区銀座5‑3‑1 | ソニーの技術体験ができる多層型施設。展示・イベント・レストランに加え、Aibo（ロボット犬）との触れ合いなどユニークな体験が可能です。 |

これらはすべて銀座に位置し、美術・アート・演劇・テクノロジーといった文化的体験ができる施設です。
```

**Query 3**: 「銀座で買い物ができる商業施設を教えてください」

```
============================================================
RAG ANSWER:
============================================================

銀座エリアで買い物ができる主な商業施設は、以下の通りです（すべて参考文書に記載されています）。

| 施設名 | 主な特徴・取り扱い商品 |
|--------|------------------------|
| **松屋銀座** | 銀座3丁目にある老舗百貨店。地下の食品売り場や文化イベントも開催。 |
| **銀座和光** | 銀座4丁目交差点に位置するシンボル的老舗百貨店。高級時計・宝飾品をはじめ、幅広いブランドを取り扱う。 |
| **銀座三越** | 銀座4丁目にある老舗百貨店。ファッション・アクセサリー・食品など多彩な商品を展開。 |
| **GINZA SIX** | 2017年開業の大型商業施設。241店舗が入居し、レストラン・屋上庭園・ラグジュアリーブランド・アート展示などが楽しめる。 |
| **東急プラザ銀座** | 江戸切子をモチーフにした外観が特徴。多様なテナントが入居し、屋上に「キリコテラス」庭園もある。 |
| **銀座伊東屋** | 12階建ての文房具専門店。高品質な文房具・筆記用具・デスク用品を幅広く扱い、カフェも併設。 |
| **銀座博品館** | 銀座8丁目にある4階建ての玩具専門店。クラシック・モダン・レア玩具などを取り揃え、4階にミニレースカートラックがある。 |
| **銀座中央通り** | 銀座のメインストリート。高級ブランド店や百貨店が立ち並び、週末は歩行者天国になるため、ショッピングに最適。 |
| **銀座ソニーパーク** | ソニーの技術体験ができる多層型施設。イベントや展示、レストラン、Aiboとの触れ合いなどがあり、ショップエリアも併設。 |
```

---

## API リファレンス

### ドキュメント アップロード API

**エンドポイント**: `POST https://api.ai.sakura.ad.jp/v1/documents/upload/`

**リクエストヘッダー**:
```
Authorization: Bearer <Token>
Content-Type: multipart/form-data
Accept: application/json
```

**リクエストボディ**:
```
file: <binary file data>
```

**レスポンス** (201 Created):
```json
{
  "id": "1aa21d05-e7c1-44e2-9956-df7dd99b1376",
  "status": "pending",
  "content": "",
  "name": "ginza_tourist_spots.txt",
  "tags": [],
  "model": "multilingual-e5-large"
}
```

### RAG チャット API

**エンドポイント**: `POST https://api.ai.sakura.ad.jp/v1/documents/chat/`

**リクエストヘッダー**:
```
Authorization: Bearer <Token>
Content-Type: application/json
Accept: application/json
```

**リクエストボディ**:
```json
{
  "model": "multilingual-e5-large",
  "chat_model": "gpt-oss-120b",
  "query": "質問文",
  "top_k": 3,
  "threshold": 0.3
}
```

**レスポンス** (200 OK):
```json
{
  "answer": "LLMが生成した回答",
  "sources": [
    {
      "document": {
        "id": "document-id",
        "created_at": "timestamp",
        "status": "available",
        "name": "filename",
        "model": "multilingual-e5-large"
      },
      "chunk_index": 0,
      "distance": 0.123,
      "content": "..."
    }
  ]
}
```

---

## ファイル構成

```
ai_services/rag_maker/
├── README.md                      # このファイル
├── step1_upload_documents.py       # ドキュメント アップロード スクリプト
└── step2_query_rag.py              # RAG検索実行スクリプト
```

---

## トラブルシューティング

### エラー: 415 Unsupported Media Type

**原因**: リクエストのContent-Typeが不正

**解決法**: `multipart/form-data`形式を使用し、適切なboundaryを指定してください

### エラー: 401 Unauthorized

**原因**: APIトークンが無効または設定されていない

**解決法**:
```bash
echo $SAKURA_OPENAI_API_TOKEN
export SAKURA_OPENAI_API_TOKEN='<your-valid-token>'
```

### クエリ結果が期待と異なる

**原因**: `threshold`値が高すぎるか、`top_k`が少なすぎる可能性

**調整**:
- `top_k`: 増やすとより多くの結果を取得
- `threshold`: 減らすと類似度の低い結果も含まれる

---

## 参考資料

- [Sakura AI Engine 操作ガイド](https://manual.sakura.ad.jp/cloud/ai-engine/03-operation-guide.html#rag-api)
- [GinzaDB データセット](../../GinzaDB/ginzaDB.json)

---

## 注記

- ドキュメント保存とエンベディング処理は課金対象です
- テキストファイルは約512文字ごとにチャンク化されます
- `multilingual-e5-large`モデルは多言語対応の埋め込みモデルです
