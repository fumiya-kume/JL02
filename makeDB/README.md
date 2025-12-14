# 観光スポット説明文 自動生成システム

## 📋 概要

**入力**: 地名のみ（例: "genza"）  
**処理**: 確固たる情報源（Google Places + Wikipedia + Web検索）とLLMのハイブリッド自動生成  
**出力**: `{地名}_tourist_spots.json`

---

## 🎯 特徴

- ✅ **完全自動** - 地名だけ入力すればOK
- ✅ **高精度** - 多段階検証（検証スコア100点満点）
- ✅ **ハルシネーション防止** - LLMは収集した事実データのみ使用
- ✅ **LLM選択可能** - Gemini（デフォルト）/ OpenAI
- ✅ **低コスト** - 約¥12/スポット

---

## 🚀 使い方

### 1. LLM設定

`tourist_spot_generator.py` の冒頭で選択:

```python
# デフォルト: Gemini
LLM_PROVIDER = "gemini"

# OpenAI使用時（コメント解除）:
# LLM_PROVIDER = "openai"
# import openai
# openai.api_key = "your-api-key-here"
```

### 2. 実行

```bash
python tourist_spot_generator.py
```

入力例: `銀座`

### 3. 出力

`ginza_tourist_spots.json` が生成されます:

```json
[
  {
    "no": 1,
    "name": "銀座和光",
    "latitude": 35.671735,
    "longitude": 139.7650442,
    "address": "東京都中央区銀座4-5-11",
    "description": "約1000字の説明文..."
  }
]
```

---

## 🔄 処理フロー

```
INPUT: "銀座"
    ↓
① スポット自動検索（Google Places API）
    ↓
② 確固たる情報収集
   ├ Google Places（評価、口コミ）
   ├ Wikipedia（歴史、詳細）
   └ Web検索（最新情報）
    ↓
③ 多段階検証（100点満点）
    ↓
④ LLM説明文生成（収集データのみ使用）
    ↓
OUTPUT: ginza_tourist_spots.json
```

---

## 🛡️ ハルシネーション防止

1. **データ収集**: 信頼できる情報源のみ
2. **検証**: 複数ソースで照合
3. **生成**: LLMに「収集データのみ使用」を明示指示
4. **品質チェック**: 生成後に整合性確認

---

## 📊 コスト（推定）

| 項目 | コスト |
|------|--------|
| Google Places API | ¥1/スポット |
| Web検索 | ¥3/スポット |
| LLM生成 | ¥8/スポット |
| Wikipedia API | 無料 |
| **合計** | **¥12/スポット** |

---

## 🎨 システム図解

![システム概要図](system_diagram.png)

![技術フロー詳細図](technical_flow.png)

---

## 🔧 カスタマイズ

### 文字数変更

```python
# AIDescriptionGenerator内
MIN_LENGTH = 950  # 最小文字数
MAX_LENGTH = 1000  # 最大文字数
```

### スポット数変更

```python
# generate_from_region()の引数
generator.generate_from_region("京都", max_spots=50)
```

---

## 📁 ファイル構成

```
tourist_spot_generator/
├── tourist_spot_generator.py  ← メインプログラム
├── README.md                  ← このファイル
├── SUMMARY.md                 ← システムサマリー
├── system_diagram.png         ← システム概要図
├── technical_flow.png         ← 技術フロー図
└── *.json                     ← 生成された出力
```

---

## 💡 実API実装について

現在はデモモードで動作します。実API実装するには:

### Google Places API

```python
# SpotFinder.find_spots()内
import googlemaps
gmaps = googlemaps.Client(key='YOUR_API_KEY')
places = gmaps.places(query=f"{region_name} 観光スポット")
```

### Wikipedia API

```python
# DataCollector.collect_wikipedia()内
import wikipedia
wikipedia.set_lang("ja")
summary = wikipedia.summary(spot_name)
```

### Gemini API

```python
# AIDescriptionGenerator._generate_with_gemini()内
import google.generativeai as genai
genai.configure(api_key="YOUR_API_KEY")
model = genai.GenerativeModel('gemini-pro')
response = model.generate_content(prompt)
```

### OpenAI API

```python
# ファイル冒頭
import openai
openai.api_key = "YOUR_API_KEY"

# AIDescriptionGenerator._generate_with_openai()内
response = openai.ChatCompletion.create(
    model="gpt-4",
    messages=[{"role": "user", "content": prompt}]
)
```

---

## 🎉 まとめ

このシステムは**地名だけ**入力すれば、**確固たる情報とLLMを組み合わせて**、**高品質な観光スポット説明文を自動生成**します。

**今すぐ試す:**

```bash
python tourist_spot_generator.py
```

---

## プレゼンテーション構成案

### 1. タイトル
**観光DXを加速する「AI観光スポット説明文 自動生成システム」**

### 2. 課題：観光コンテンツ制作の現状
- **膨大な手間とコスト**: 観光地の情報を収集・整理し、魅力的な説明文を作成するには、多大な時間とライター費用がかかる。
- **情報の陳腐化**: イベント情報や営業時間の変更など、情報の鮮度を保つための継続的な更新作業が負担。
- **品質のばらつき**: ライターによって文章の質やスタイルが異なり、ブランドイメージの統一が難しい。
- **機械翻訳の限界**: 多言語対応時に、不自然な翻訳で現地の魅力が伝わらない。

### 3. 解決策：本システムの提案
**「地名」を入力するだけ**で、**信頼性の高い情報**に基づいた**高品質な説明文**を**完全自動で生成**。
→ コンテンツ制作を圧倒的に効率化し、常に最新で魅力的な情報発信を実現します。

### 4. システム概要
**入力**: 地名（例: "銀座"）
**出力**: 観光スポット情報（JSON形式）
**コア技術**: 外部API連携 + LLM（大規模言語モデル）

#### **ハイブリッド・アプローチ**
- **事実収集 (Fact API)**: Google Places, Wikipedia, Web検索APIを駆使し、信頼性の高い情報を自動収集。
- **文章生成 (LLM)**: 収集した「事実のみ」を制約としてLLMに与え、自然で魅力的な文章を生成。

### 5. 処理フロー（5ステップ）
1.  **① スポット検索**: 入力された地名に基づき、Google Places APIで主要な観光スポットをリストアップ。
2.  **② データ収集**: 各スポットについて、Wikipedia（歴史・背景）やGoogle（口コミ・評価・営業時間）などから詳細情報を収集。情報が不足する場合はWeb検索で補完。
3.  **③ データ検証**: 収集した情報の整合性をチェックし、信頼性をスコアリング。不正確な情報はここで除外。
4.  **④ 説明文生成**: 検証済みの「事実」のみをLLMに渡し、「この情報だけを使って、指定の文字数と構成で文章を作成せよ」という厳密な指示（プロンプト）で説明文を生成。
5.  **⑤ 品質検証と出力**: 生成された文章が指示通りか（文字数、必須キーワードなど）を最終チェックし、JSONファイルとして出力。

### 6. 3つの特徴
1.  **圧倒的な高精度・信頼性（ハルシネーション防止）**
    - LLMに自由な作文をさせず、「事実データ」という"素材"だけを与えて"調理"させるアプローチ。
    - 複数ソースの情報を照合・検証するステップを組み込み、誤った情報の混入を徹底的に防止。

2.  **完全自動化と柔軟なカスタマイズ性**
    - 実行は地名を入力するだけ。人手は一切不要。
    - 生成するスポット数や説明文の文字数、使用するLLM（Gemini/Claude/OpenAI）も設定ファイルから簡単に変更可能。

3.  **驚異的な低コスト**
    - 1スポットあたり約12円で生成可能。
    - 従来のライター発注コストを90%以上削減（※推定）。

### 7. まとめ
本システムは、**信頼性・自動化・コスト効率**を極限まで追求した、次世代の観光コンテンツ制作ソリューションです。
観光業界のデジタルトランスフォーメーションを力強く推進します。
