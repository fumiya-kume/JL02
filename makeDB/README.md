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
