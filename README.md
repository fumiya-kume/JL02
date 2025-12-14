# JL02

ARグラス向けツーリズムガイドアプリのプロトタイプです。

## 概要

ArGlassは、Vision Language Model (VLM) を活用してリアルタイムでランドマークを認識し、ユーザーの興味に合わせた情報を表示するiOSアプリです。Xreal Air等のARグラス向けに最適化されたサイバーパンク風HUDインターフェースを提供します。

## 機能

- リアルタイムランドマーク認識（VLM API連携）
- パーソナライズ（10カテゴリから興味を選択）
- 位置情報連携（GPS・逆ジオコーディング）
- 検出履歴の保存・閲覧
- サイバーパンク風HUD UI（グリッチエフェクト、スキャンライン）

## セットアップ

### 必要環境

- Xcode 15.0以上
- iOS 17.0以上
- 実機（カメラ・位置情報使用のため）

### ビルド手順

1. リポジトリをクローン
2. `arglass/ArGlass.xcodeproj` をXcodeで開く
3. 実機を接続してビルド・実行

## アーキテクチャ

```
arglass/ArGlass/
├── Services/      # ビジネスロジック（VLM, カメラ, 位置情報, 履歴）
├── ViewModel/     # 状態管理（HUD, オンボーディング, 履歴）
├── Views/         # SwiftUI コンポーネント
└── Models/        # データ構造
```

## プロジェクト構成

### ディレクトリ構造

```
JL02/
├── arglass/                 # iOS ARグラスアプリケーション
│   └── ArGlass/
│       ├── Services/        # ビジネスロジック（VLM API, カメラ, GPS, 履歴管理）
│       ├── ViewModel/       # MVVM状態管理（HUD, オンボーディング, 履歴表示）
│       ├── Views/           # SwiftUIコンポーネント
│       └── Models/          # データ構造
│
├── ai_services/             # AIバックエンド・サービス群
│   ├── ai-backend/          # FastAPI メインバックエンドサーバー
│   ├── vlm_server/          # Visual Language Model推論サーバー
│   └── rag_maker/           # RAG（検索拡張生成）コンポーネント
│
├── makeDB/                  # データベース生成ツール（Python）
│   ├── main.py              # DB生成メインスクリプト
│   ├── tourist_spot_generator.py  # 観光スポット情報生成
│   ├── config.yaml          # 設定ファイル
│   └── dependencies.txt     # Python依存ライブラリ
│
├── Katanori_M5stack/        # M5Stack対応ハードウェアプロジェクト
└── onboarding/              # プロジェクト導入ドキュメント
```

### 役割分担

| コンポーネント | 技術スタック | 主な役割 |
|---|---|---|
| **arglass** | Swift, SwiftUI, ARKit | ユーザー向けiOSアプリ、AR表示、カメラ・位置情報処理 |
| **ai-backend** | Python, FastAPI | API仲介、ビジネスロジック、データ管理 |
| **vlm_server** | Python, Vision Language Model | ランドマーク認識、画像解析推論 |
| **makeDB** | Python, Anthropic AI, Google Generative AI | 観光スポット情報の生成・DB構築 |
| **Katanori_M5stack** | C++/MicroPython | IoTハードウェア連携（推測） |

### 技術スタック

**フロントエンド:**
- Swift / SwiftUI
- ARKit（ARグラス対応）

**バックエンド:**
- Python FastAPI
- Vision Language Model API
- Anthropic AI / Google Generative AI

**データ:**
- JSON（観光スポット情報）
- YAML（設定管理）

## ライセンス

- TBD
