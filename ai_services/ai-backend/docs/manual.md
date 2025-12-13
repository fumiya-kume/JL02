以下は、**さくらのクラウド「AppRun共用型」**で **Python/FastAPI のAPIサーバー**をデプロイするための手順書です（公式マニュアル準拠・2025-12-09/10更新）。([さくらのマニュアル][1])

---

## 0. 前提（必要なもの）

* さくらのクラウドの**プロジェクト**（AppRunはプロジェクト内で利用）([さくらのマニュアル][1])
* 開発PCに **Docker** がインストール済み ([さくらのマニュアル][1])
* AppRun共用型は**コンテナイメージ（現状は「コンテナレジストリ」のみ指定可）**でデプロイ ([さくらのマニュアル][2])

---

## 1. FastAPIアプリを用意する

ディレクトリ例：

```
my-fastapi/
  main.py
  requirements.txt
  Dockerfile
```

### main.py（例）

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Hello from AppRun + FastAPI"}

@app.get("/health")
def health():
    return {"status": "ok"}
```

### requirements.txt（例）

```txt
fastapi==0.115.0
uvicorn[standard]==0.30.6
```

---

## 2. Dockerfile を作る（AppRun向け）

ポイント：

* **0.0.0.0**で待ち受ける
* AppRun側の「ポート設定」とアプリの待受ポートを合わせる（例では 8080）
* 使えないポートがある（後述）([さくらのマニュアル][2])

Dockerfile（例）：

```dockerfile
FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# ローカル動作も想定して 8080 をデフォルトに
ENV PORT=8080
EXPOSE 8080

CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT}"]
```

注意：AppRunの「予約済み環境変数」に `PORT` が含まれ、**AppRun側で同名環境変数を設定すると実行時エラー**になります。上のDockerfileはローカル実行の便宜で `ENV PORT=8080` を置いていますが、AppRun運用だけに寄せるなら `ENV PORT=8080` を削り、AppRunが注入する `PORT` に従わせる方が安全です。([さくらのマニュアル][2])

---

## 3. コンテナレジストリを作成する（さくらのクラウド）

AppRunのデプロイ元として、**コンテナレジストリ**を用意します。([さくらのマニュアル][1])

### 3.1 レジストリ作成

* レジストリ接続先は **`<レジストリ名>.sakuracr.jp`** のサブドメイン形式
* レジストリ名は他ユーザーと重複不可、使用文字など制約あり（小文字英数字と`-`等、英字開始など）([さくらのマニュアル][3])

### 3.2 レジストリユーザー作成

非公開運用ならユーザー作成が必要（Push/Pull権限などを付与）。([さくらのマニュアル][3])

---

## 4. イメージをビルドしてレジストリへ push

### 4.1 `linux/amd64` でビルド

AppRunは **x86_64** のため、特にMac等は `--platform linux/amd64` 指定が推奨されています。([さくらのマニュアル][1])

```bash
cd my-fastapi
docker build --platform linux/amd64 -t my-fastapi .
```

### 4.2 ログイン・タグ付け・push

イメージ名は **`[レジストリ名].sakuracr.jp/[任意のイメージ名]:[タグ]`** 形式が必要です。([さくらのマニュアル][3])

```bash
# 例: レジストリ名が myreg の場合
docker login myreg.sakuracr.jp

docker tag my-fastapi myreg.sakuracr.jp/my-fastapi:latest
docker push myreg.sakuracr.jp/my-fastapi:latest
```

---

## 5. AppRun共用型でアプリケーションを作成してデプロイ

公式クイックスタートの流れに沿って、AppRun共用型でアプリを作成します。([さくらのマニュアル][1])

### 5.1 アプリケーション設定（重要項目）

* **アプリケーション名**：作成後変更不可 ([さくらのマニュアル][4])
* **ポート設定**：例では `8080`

  * 範囲は 1〜65535、ただし予約済みで使えないポートあり（例：8008, 8012, 8013, 8022, 8443, 9090, 9091）。([さくらのマニュアル][2])
* **オートスケーリング**：最小0〜最大10（デフォルト 最小0/最大1）([さくらのマニュアル][4])
* **リクエストタイムアウト**：1〜300秒（デフォルト60秒）([さくらのマニュアル][4])

### 5.2 コンテナ設定

* **コンテナイメージ**：例 `myreg.sakuracr.jp/my-fastapi:latest` ([さくらのマニュアル][4])
* レジストリが非公開なら **ユーザー名/パスワード** を入力 ([さくらのマニュアル][4])
* **リソース構成**：0.5vCPU/1GiB などから選択 ([さくらのマニュアル][4])
* **ヘルスチェック（推奨）**：パスに `/health` を設定

  * 10秒間隔でチェックされます ([さくらのマニュアル][4])

### 5.3 変数（環境変数）

* 最大50個まで設定可能 ([さくらのマニュアル][4])
* 予約済み（`K_SERVICE`, `K_CONFIGURATION`, `K_REVISION`, `PORT`）は指定するとエラー ([さくらのマニュアル][2])

### 5.4 作成

設定内容を確認して「作成する」。

---

## 6. 動作確認

* AppRunの詳細画面に表示される **公開URL** にアクセスして確認します（クイックスタートでもこの流れ）。([さくらのマニュアル][1])
* 例（curl）：

```bash
curl https://<your-app>.apprun.sakura.ne.jp/
curl https://<your-app>.apprun.sakura.ne.jp/health
```

---

## 7. 運用設定（必要に応じて）

### 7.1 ログ/メトリクス

操作ガイドでは、**モニタリングスイートのストレージ**を使って、アプリ単位の標準出力/標準エラーのログ監視や、リクエスト数・レイテンシ・CPU/メモリ等メトリクス確認ができるとされています。([さくらのマニュアル][4])
一方でFAQには「現在はアプリケーションログ閲覧機能は提供していない」との記載もあり、記述に不整合があります。([さくらのマニュアル][5])
実務的には、**操作ガイド記載の“ログストレージ連携”を前提に設計**するのが安全です。([さくらのマニュアル][4])

### 7.2 トラフィック分割 / ロールバック

AppRun共用型はバージョン管理とトラフィック管理があり、最大4バージョンへの分散、バージョン保持は最大5世代などの仕様が明記されています。([さくらのマニュアル][2])

### 7.3 アクセス制限（IP許可）

パケットフィルターで送信元IP制限が可能（最大10件）。([さくらのマニュアル][4])

---

## 8. 制限事項（設計でハマりやすい点）

* 通信は **HTTP/HTTPSのみ**（WebSocket等は非対応）([さくらのマニュアル][5])
* **永続ストレージなし**：DB等は外部サービス利用推奨 ([さくらのマニュアル][5])
* **独自ドメインは未サポート**（FAQ記載）([さくらのマニュアル][5])

---

必要なら、あなたのリポジトリ構成（依存関係、起動コマンド、想定ポート、ヘルスチェック有無）に合わせて、AppRun用に「最小で事故らないDockerfile/設定値」へ具体化した版も作れます。

[1]: https://manual.sakura.ad.jp/cloud/apprun/getting_started.html "クイックスタート | さくらのクラウド マニュアル"
[2]: https://manual.sakura.ad.jp/cloud/apprun/glossary.html "技術概要 | さくらのクラウド マニュアル"
[3]: https://manual.sakura.ad.jp/cloud/appliance/container-registry/index.html "コンテナレジストリ | さくらのクラウド マニュアル"
[4]: https://manual.sakura.ad.jp/cloud/apprun/operation.html "コントロールパネル操作ガイド | さくらのクラウド マニュアル"
[5]: https://manual.sakura.ad.jp/cloud/apprun/faq.html "サポート | さくらのクラウド マニュアル"
