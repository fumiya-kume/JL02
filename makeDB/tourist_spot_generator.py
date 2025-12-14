#!/usr/bin/env python3
"""
観光スポット説明文自動生成システム
入力: 地域名のみ
出力: {地域名}_tourist_spots.json

LLM選択可能: Gemini (デフォルト) / OpenAI
"""

import json
import re
import yaml
from datetime import datetime
from typing import Dict, List, Optional
from dataclasses import dataclass
from pathlib import Path

# API imports
import requests
import google.generativeai as genai
from wikipediaapi import Wikipedia
import anthropic


def load_config(config_path: str = "config.yaml") -> Dict:
    """設定ファイルを読み込む"""
    config_file = Path(config_path)
    if not config_file.exists():
        raise FileNotFoundError(f"設定ファイルが見つかりません: {config_path}")

    with open(config_file, 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)

    return config


@dataclass
class SpotData:
    """観光スポットの構造化データ"""
    no: int
    name: str
    latitude: float
    longitude: float
    address: str
    description: str = ""

    # 内部処理用
    _basic_info: Dict[str, any] = None
    _history: str = ""
    _features: List[str] = None
    _official_url: str = ""
    _sources: Dict[str, str] = None
    _metadata: Dict[str, any] = None

    def __post_init__(self):
        if self._features is None:
            self._features = []
        if self._sources is None:
            self._sources = {}
        if self._basic_info is None:
            self._basic_info = {}
        if self._metadata is None:
            self._metadata = {}

    def to_output_format(self) -> Dict:
        """出力形式に変換"""
        return {
            "no": self.no,
            "name": self.name,
            "latitude": self.latitude,
            "longitude": self.longitude,
            "address": self.address,
            "description": self.description
        }


class SpotFinder:
    """地域名から観光スポットを自動検索"""

    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://places.googleapis.com/v1/places:searchText"

    def find_spots(self, region_name: str, max_spots: int = 20) -> List[Dict]:
        """
        地域名から観光スポットを検索

        Google Places API (New) を使用
        """
        print(f"\n{'='*60}")
        print(f"【観光スポット検索】地域: {region_name}")
        print(f"{'='*60}")

        headers = {
            "Content-Type": "application/json",
            "X-Goog-Api-Key": self.api_key,
            "X-Goog-FieldMask": "places.displayName,places.formattedAddress,places.location,places.id"
        }

        data = {
            "textQuery": f"{region_name} 観光スポット",
            "languageCode": "ja",
            "maxResultCount": min(max_spots, 20)  # API上限20
        }

        try:
            response = requests.post(self.base_url, headers=headers, json=data)
            response.raise_for_status()
            result = response.json()

            places = result.get("places", [])
            spots = []

            for place in places:
                spot = {
                    "name": place.get("displayName", {}).get("text", ""),
                    "latitude": place.get("location", {}).get("latitude", 0.0),
                    "longitude": place.get("location", {}).get("longitude", 0.0),
                    "address": place.get("formattedAddress", ""),
                    "place_id": place.get("id", "")
                }
                spots.append(spot)

            print(f"  [OK] {len(spots)}箇所の観光スポットを発見")
            for i, spot in enumerate(spots, 1):
                print(f"    {i}. {spot['name']}")

            return spots

        except requests.exceptions.RequestException as e:
            print(f"  [ERROR] Google Places API エラー: {e}")
            raise


class DataCollector:
    """複数ソースからデータを収集"""

    def __init__(self, google_api_key: str, web_search_config: Optional[Dict] = None):
        self.google_api_key = google_api_key
        self.web_search_config = web_search_config or {}
        self.wiki = Wikipedia(
            language='ja',
            user_agent='TouristSpotGenerator/1.0 (https://github.com/fumiya-kume/JL02)'
        )

    def collect_google_places(self, place_id: str, spot_name: str) -> Dict:
        """Google Places APIから詳細データ収集"""
        print(f"  → Google Places APIからデータ収集: {spot_name}")

        # place_idが "places/" で始まっていない場合は追加
        if not place_id.startswith("places/"):
            place_id = f"places/{place_id}"

        url = f"https://places.googleapis.com/v1/{place_id}"
        headers = {
            "X-Goog-Api-Key": self.google_api_key,
            "X-Goog-FieldMask": "rating,userRatingCount,types,regularOpeningHours,internationalPhoneNumber,websiteUri"
        }

        try:
            response = requests.get(url, headers=headers)
            response.raise_for_status()
            data = response.json()

            return {
                "rating": data.get("rating", 0),
                "user_ratings_total": data.get("userRatingCount", 0),
                "types": data.get("types", []),
                "opening_hours": self._format_opening_hours(data.get("regularOpeningHours", {})),
                "phone": data.get("internationalPhoneNumber", ""),
                "website": data.get("websiteUri", "")
            }
        except requests.exceptions.RequestException as e:
            print(f"  [WARN] Google Places API エラー: {e}")
            return {}

    def _format_opening_hours(self, opening_hours: Dict) -> str:
        """営業時間をフォーマット"""
        if not opening_hours:
            return ""
        periods = opening_hours.get("weekdayDescriptions", [])
        return ", ".join(periods[:2]) if periods else ""

    def collect_wikipedia(self, spot_name: str) -> Dict:
        """Wikipedia APIからデータ収集"""
        print(f"  → Wikipediaからデータ収集: {spot_name}")

        try:
            page = self.wiki.page(spot_name)

            if page.exists():
                # HTMLタグを除去してテキストのみ取得
                summary = re.sub('<[^<]+?>', '', page.summary[:1000])
                return {
                    "summary": summary,
                    "source_url": page.fullurl,
                    "exists": True
                }
            else:
                print(f"  [WARN] Wikipedia: {spot_name} のページが見つかりませんでした")
                return {
                    "summary": "",
                    "source_url": "",
                    "exists": False
                }
        except Exception as e:
            print(f"  [WARN] Wikipedia API エラー: {e}")
            return {"summary": "", "source_url": "", "exists": False}

    def collect_web_search(self, spot_name: str) -> Dict:
        """Web検索からデータ収集（オプション）"""
        if not self.web_search_config.get("enabled", False):
            return {"features": [], "snippets": []}

        print(f"  → Web検索からデータ収集: {spot_name}")

        api_key = self.web_search_config.get("api_key")
        search_engine_id = self.web_search_config.get("search_engine_id")

        if not api_key or not search_engine_id:
            print(f"  [WARN] Web検索: APIキーまたは検索エンジンIDが未設定")
            return {"features": [], "snippets": []}

        url = "https://www.googleapis.com/customsearch/v1"
        params = {
            "key": api_key,
            "cx": search_engine_id,
            "q": f"{spot_name} 観光",
            "num": 3,
            "lr": "lang_ja"
        }

        try:
            response = requests.get(url, params=params)
            response.raise_for_status()
            data = response.json()

            items = data.get("items", [])
            snippets = [item.get("snippet", "") for item in items]

            return {
                "features": snippets[:3],
                "snippets": snippets
            }
        except requests.exceptions.RequestException as e:
            print(f"  [WARN] Web検索 API エラー: {e}")
            return {"features": [], "snippets": []}

    def collect_all(self, spot: SpotData, place_id: str = "") -> SpotData:
        """全ソースからデータを収集"""
        print(f"\n【データ収集開始】{spot.name}")

        # Google Places詳細情報
        if place_id:
            google_data = self.collect_google_places(place_id, spot.name)
        else:
            google_data = {}

        # Wikipedia情報
        wiki_data = self.collect_wikipedia(spot.name)

        # Web検索情報（Wikipediaで取得できなかった場合のみ）
        if not wiki_data.get("exists", False):
            web_data = self.collect_web_search(spot.name)
        else:
            web_data = {"features": [], "snippets": []}

        spot._basic_info = google_data
        spot._history = wiki_data.get("summary", "")
        spot._features = web_data.get("features", [])
        spot._sources = {
            "google_places": "Google Places API",
            "wikipedia": wiki_data.get("source_url", ""),
            "web_search": "Web検索" if self.web_search_config.get("enabled") else ""
        }

        print(f"  [OK] データ収集完了")
        return spot


class DataVerifier:
    """データの検証と整合性チェック"""
    
    def verify_facts(self, spot: SpotData) -> Dict[str, any]:
        """事実の検証"""
        print(f"\n【データ検証】{spot.name}")
        
        verification_result = {
            "verified": True,
            "issues": [],
            "confidence_score": 100
        }
        
        if not spot.name:
            verification_result["issues"].append("名称が空です")
            verification_result["verified"] = False
        
        if not spot.address:
            verification_result["issues"].append("住所が空です")
            verification_result["confidence_score"] -= 10
        
        # 座標検証（日本国内か）
        lat, lng = spot.latitude, spot.longitude
        if not (24 <= lat <= 46 and 123 <= lng <= 146):
            verification_result["issues"].append("座標が日本の範囲外です")
            verification_result["confidence_score"] -= 20
        
        # データソース数チェック
        if len(spot._sources) < 2:
            verification_result["issues"].append("データソースが不足しています")
            verification_result["confidence_score"] -= 10
        
        print(f"  検証スコア: {verification_result['confidence_score']}/100")
        if verification_result["issues"]:
            print(f"  [WARN] 問題点: {', '.join(verification_result['issues'])}")
        else:
            print(f"  [OK] 検証完了")
        
        return verification_result


class AIDescriptionGenerator:
    """LLMを使用した説明文生成（制約付き）"""

    def __init__(self, llm_config: Dict):
        """
        Args:
            llm_config: LLM設定（provider, api_key, modelなど）
        """
        self.provider = llm_config.get("provider", "gemini")
        self.config = llm_config

        # Claude初期化
        if self.provider == "claude":
            api_key = llm_config.get("claude", {}).get("api_key")
            if api_key:
                self.claude_client = anthropic.Anthropic(api_key=api_key)
                self.claude_model = llm_config.get("claude", {}).get("model", "claude-3-5-sonnet-20241022")
            else:
                raise ValueError("Claude APIキーが設定されていません")

        # Gemini初期化
        elif self.provider == "gemini":
            api_key = llm_config.get("gemini", {}).get("api_key")
            if api_key:
                genai.configure(api_key=api_key)
                model_name = llm_config.get("gemini", {}).get("model", "gemini-2.5-flash")
                self.model = genai.GenerativeModel(model_name)
            else:
                raise ValueError("Gemini APIキーが設定されていません")

        # OpenAI初期化
        elif self.provider == "openai":
            self.openai_config = llm_config.get("openai", {})
            if not self.openai_config.get("api_key"):
                raise ValueError("OpenAI APIキーが設定されていません")

    def generate(self, spot: SpotData) -> str:
        """説明文を生成"""
        print(f"\n【説明文生成】{spot.name} (LLM: {self.provider})")

        # プロンプト構築
        prompt = self._build_prompt(spot)

        # LLM呼び出し
        if self.provider == "claude":
            description = self._generate_with_claude(prompt)
        elif self.provider == "gemini":
            description = self._generate_with_gemini(prompt)
        elif self.provider == "openai":
            description = self._generate_with_openai(prompt)
        else:
            raise ValueError(f"未対応のLLM: {self.provider}")

        # 文字数チェックとトリミング
        original_length = len(description)
        if original_length > 1000:
            print(f"  [WARN] 生成文字数が1000字を超過({original_length}字)、トリミングします")
            description = description[:1000]
            print(f"  トリミング後: {len(description)}字")

        print(f"  生成文字数: {len(description)}字")
        print(f"  [OK] 説明文生成完了")

        return description

    def _build_prompt(self, spot: SpotData) -> str:
        """プロンプト構築"""

        # 文字数目標を計算（950-1000字の範囲で、データ量に応じて調整）
        target_length = 975  # 中間値を目標に

        prompt = f"""あなたは観光情報の専門ライターです。以下の事実データのみを使用して、{spot.name}の説明文を正確に950-1000字で作成してください。

【絶対厳守：文字数制限】
- **絶対上限**: 1000字（1文字でも超過禁止）
- **目標範囲**: 950-1000字
- **重要**: 冗長な表現を徹底的に排除し、簡潔に記述してください
- 「この数値は」「これらの情報は」など、同じ情報を繰り返し説明しない
- 座標や住所の詳細説明は最小限に（「位置は〜」で1文のみ）

【構成指示（合計950-1000字）】
第1段落（200-250字）: 名称、位置、基本情報（住所・座標は簡潔に1-2文のみ）
第2段落（300-400字）: 歴史・背景（ある場合のみ、簡潔に）
第3段落（250-300字）: 特徴（ある場合のみ）
第4段落（150-200字）: 評価・口コミ・Webサイト情報、情報源

【執筆ルール】
1. 提供されたデータにない情報は一切追加しない
2. 推測表現（〜と思われる、〜かもしれない、〜だろう）は使用禁止
3. 冗長な表現を避ける（例：「この数値は〜を示す」を繰り返さない）
4. 各段落を書いたら文字数を確認し、超過しないよう調整する

【使用可能なデータ】
名称: {spot.name}
住所: {spot.address}
位置: 緯度{spot.latitude}, 経度{spot.longitude}

歴史・背景:
{spot._history if spot._history else 'データなし'}

特徴:
{', '.join(spot._features) if spot._features else 'データなし'}

基本情報:
- 評価: {spot._basic_info.get('rating', 'なし')}
- 口コミ数: {spot._basic_info.get('user_ratings_total', 'なし')}
- Webサイト: {spot._basic_info.get('website', 'なし')}

情報源:
{spot._sources}

【出力】
説明文のみを出力してください。前置きや補足は不要です。
**絶対に1000字を超えないでください。**
"""
        return prompt

    def _generate_with_claude(self, prompt: str) -> str:
        """Claude APIで生成"""
        try:
            message = self.claude_client.messages.create(
                model=self.claude_model,
                max_tokens=4096,
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )
            return message.content[0].text
        except Exception as e:
            print(f"  [ERROR] Claude API呼び出しエラー: {e}")
            raise

    def _generate_with_gemini(self, prompt: str) -> str:
        """Gemini APIで生成"""
        try:
            response = self.model.generate_content(prompt)
            return response.text
        except Exception as e:
            print(f"  [ERROR] Gemini API呼び出しエラー: {e}")
            raise

    def _generate_with_openai(self, prompt: str) -> str:
        """OpenAI APIで生成"""
        try:
            import openai
            openai.api_key = self.openai_config.get("api_key")
            model = self.openai_config.get("model", "gpt-4")

            response = openai.ChatCompletion.create(
                model=model,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.7
            )
            return response.choices[0].message.content
        except Exception as e:
            print(f"  [ERROR] OpenAI API呼び出しエラー: {e}")
            raise


class QualityValidator:
    """生成された説明文の品質検証"""
    
    def validate(self, description: str, spot: SpotData) -> Dict[str, any]:
        """品質検証"""
        print(f"\n【品質検証】{spot.name}")
        
        result = {
            "passed": True,
            "issues": [],
            "metrics": {}
        }
        
        # 文字数チェック
        char_count = len(description)
        result["metrics"]["char_count"] = char_count
        
        if char_count < 950 or char_count > 1000:
            result["issues"].append(f"文字数が範囲外: {char_count}字")
            result["passed"] = False
            print(f"  [ERROR] 文字数: {char_count}字 (950-1000字が必要)")
        else:
            print(f"  [OK] 文字数: {char_count}字")
        
        # 必須キーワードチェック
        if spot.name and spot.name not in description:
            result["issues"].append(f"スポット名が含まれていません")
            result["passed"] = False
            print(f"  [ERROR] スポット名欠如")
        else:
            print(f"  [OK] スポット名含有")
        
        # 推測表現チェック
        speculation_patterns = [r"思われる", r"かもしれない", r"だろう", r"であろう"]
        found = [p for p in speculation_patterns if re.search(p, description)]
        
        if found:
            result["issues"].append(f"推測表現検出: {found}")
            print(f"  [WARN] 推測表現: {found}")
        else:
            print(f"  [OK] 推測表現なし")
        
        if result["passed"]:
            print(f"  [OK] 品質検証合格")
        else:
            print(f"  [ERROR] 品質検証不合格")
        
        return result


class TouristSpotGenerator:
    """観光スポット情報生成システムのメインクラス"""

    def __init__(self, config: Dict):
        """
        Args:
            config: 設定ファイルから読み込んだ設定
        """
        self.config = config

        # Google Places API設定
        google_api_key = config["data_collection"]["google_places"]["api_key"]

        # 各コンポーネント初期化
        self.spot_finder = SpotFinder(api_key=google_api_key)
        self.collector = DataCollector(
            google_api_key=google_api_key,
            web_search_config=config["data_collection"].get("web_search", {})
        )
        self.verifier = DataVerifier()
        self.ai_generator = AIDescriptionGenerator(llm_config=config["llm"])
        self.validator = QualityValidator()

        # 生成設定
        self.generation_config = config.get("generation", {})

    def generate_from_region(
        self,
        region_name: str,
        max_spots: Optional[int] = None,
        output_file: Optional[str] = None
    ) -> Dict:
        """
        地域名から観光スポットを自動検索・生成

        Args:
            region_name: 地域名（例: "銀座", "京都"）
            max_spots: 最大生成数（省略時は設定ファイルから）
            output_file: 出力ファイル名（省略時は自動命名）

        Returns:
            生成されたJSONデータ
        """
        if max_spots is None:
            max_spots = self.generation_config.get("max_spots", 20)

        if output_file is None:
            region_key = self._to_english_key(region_name)
            output_file = f"{region_key}_tourist_spots.json"

        print(f"\n{'#'*60}")
        print(f"# 観光スポット自動生成")
        print(f"# 入力: {region_name}")
        print(f"# LLM: {self.ai_generator.provider}")
        print(f"{'#'*60}\n")

        # ステップ1: 観光スポット検索
        found_spots = self.spot_finder.find_spots(region_name, max_spots)

        if not found_spots:
            print(f"\n[ERROR] {region_name}で観光スポットが見つかりませんでした")
            return None

        # ステップ2: SpotDataオブジェクト作成
        spots = []
        for i, spot_info in enumerate(found_spots, 1):
            spot = SpotData(
                no=i,
                name=spot_info["name"],
                latitude=spot_info["latitude"],
                longitude=spot_info["longitude"],
                address=spot_info["address"]
            )
            # place_idを保存（内部処理用）
            spot._metadata = {"place_id": spot_info.get("place_id", "")}
            spots.append(spot)

        # ステップ3: 各スポットの説明文生成
        results = []
        success_count = 0

        for i, spot in enumerate(spots, 1):
            print(f"\n{'='*60}")
            print(f"進捗: {i}/{len(spots)}")
            print(f"{'='*60}")

            try:
                result_spot = self._generate_spot_info(spot)

                if result_spot:
                    results.append(result_spot.to_output_format())
                    success_count += 1
            except Exception as e:
                print(f"\n[ERROR] {spot.name} - {e}")
                continue

        # ステップ4: JSON出力
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(results, f, ensure_ascii=False, indent=2)

        print(f"\n{'#'*60}")
        print(f"# 自動生成完了")
        print(f"# 成功: {success_count}/{len(spots)}")
        print(f"# 出力: {output_file}")
        print(f"{'#'*60}\n")

        return results

    def _generate_spot_info(self, spot: SpotData) -> Optional[SpotData]:
        """個別スポットの説明文を生成"""
        # データ収集
        place_id = spot._metadata.get("place_id", "")
        spot = self.collector.collect_all(spot, place_id=place_id)

        # データ検証
        verification = self.verifier.verify_facts(spot)

        if not verification["verified"]:
            print(f"\n[ERROR] データ検証失敗")
            return None

        # AI説明文生成
        description = self.ai_generator.generate(spot)

        # 品質検証
        quality = self.validator.validate(description, spot)

        spot.description = description
        spot._metadata = {
            "generated_at": datetime.now().isoformat(),
            "verification_score": verification["confidence_score"],
            "quality_check": quality["passed"],
            "char_count": len(description)
        }

        print(f"\n[OK] 生成完了: {spot.name}")

        return spot

    def _to_english_key(self, region_name: str) -> str:
        """地域名を英語キーに変換"""
        mapping = {
            "銀座": "ginza", "浅草": "asakusa", "京都": "kyoto",
            "大阪": "osaka", "札幌": "sapporo", "福岡": "fukuoka",
            "渋谷": "shibuya", "新宿": "shinjuku"
        }
        return mapping.get(region_name, region_name.lower())


def main():
    """メイン実行"""

    print("\n" + "="*60)
    print("観光スポット説明文 自動生成システム")
    print("="*60)

    try:
        # 設定ファイル読み込み
        config = load_config("config.yaml")
        print(f"設定ファイル読み込み完了")
        print(f"LLM Provider: {config['llm']['provider']}")

        # ジェネレーター初期化
        generator = TouristSpotGenerator(config=config)

        # ユーザー入力
        print("\n地域名を入力してください（例: 銀座, 京都, 大阪）")
        region_name = input("地域名: ").strip()

        if not region_name:
            print("地域名が入力されていません。終了します。")
            return

        # 生成実行
        generator.generate_from_region(region_name=region_name)

    except FileNotFoundError as e:
        print(f"\n[ERROR] {e}")
        print("config.yamlファイルを確認してください。")
    except ValueError as e:
        print(f"\n[ERROR] {e}")
        print("config.yamlのAPIキー設定を確認してください。")
    except Exception as e:
        print(f"\n[ERROR] 予期しないエラー: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
