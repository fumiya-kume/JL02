#!/usr/bin/env python3
"""
テスト実行用スクリプト
引数で地域名を指定して実行
"""

import sys
from tourist_spot_generator import load_config, TouristSpotGenerator

def main():
    if len(sys.argv) < 2:
        print("使い方: python test_run.py <地域名>")
        print("例: python test_run.py 銀座")
        sys.exit(1)

    region_name = sys.argv[1]

    try:
        # 設定ファイル読み込み
        config = load_config("config.yaml")
        print(f"設定ファイル読み込み完了")
        provider = config['llm']['provider']
        print(f"LLM Provider: {provider}")

        # プロバイダーに応じたモデル名を表示
        if provider == "claude":
            model = config['llm']['claude'].get('model', 'claude-3-5-sonnet-20241022')
        elif provider == "gemini":
            model = config['llm']['gemini'].get('model', 'gemini-2.5-flash')
        elif provider == "openai":
            model = config['llm']['openai'].get('model', 'gpt-4')
        else:
            model = "unknown"
        print(f"LLM Model: {model}")

        # ジェネレーター初期化
        generator = TouristSpotGenerator(config=config)

        # 生成実行
        print(f"\n地域名: {region_name}")
        generator.generate_from_region(region_name=region_name, max_spots=3)

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
