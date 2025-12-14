# ArGlass

ARグラス越しに見えるランドマークをリアルタイム認識し、未来的な字幕UIで情報を重ねて表示する観光ガイドアプリの SwiftUI プロトタイプです。

## できていること（プロトタイプ）

- 中央ターゲットマーカー（スキャン中 / ロック中 + パルス）
- 下部ホログラム風字幕パネル（タイピングエフェクトで解説を表示）
- スキャンライン / グリッチ風エフェクト
- 距離・方角のインジケーター
- DEBUGビルド時のみ、右上の Debug Menu からダミーの検出状態を切り替え可能

※ ランドマーク認識は現状ダミーで、Debug Menu のタップ操作で状態を切り替えます（自動ループはしません）。

## 開き方

`arglass/` に `ArGlass.xcodeproj` を同梱しています。必要に応じてそのまま開いて実行してください。

XcodeGen を使って再生成したい場合は、`arglass/` で以下を実行します。

```sh
xcodegen generate
```

生成後は `ArGlass.xcodeproj` を開いて実行してください。

## 補足

- ARグラス（例: Xreal Air）での表示を想定し、背景は黒一色です（黒は発光しにくく、透過っぽく見せる前提）。
- Xreal Air での表示を想定して、画面の向きは横（ランドスケープ）固定です。
- 配色は `AccentColor` + ニュートラル（白/黒/グレー）中心で、複数の有彩色は使わない方針です。

## 署名まわり（Speech Recognition）

`Speech` フレームワークで音声認識を有効にする場合、端末実機でのビルド/実行で `com.apple.developer.speech-recognition` の Entitlement が必要になることがあります（Team/契約状況によっては付与できずエラーになります）。

このリポジトリは、`Personal Team` 等でもビルドできるように **デフォルトでは当該 Entitlement を付けていません**（必要なら `arglass/ArGlass/ArGlass.entitlements` に追加してください）。

もし Xcode で以下のエラーが出る場合:

- `Provisioning profile "iOS Team Provisioning Profile: com.fumiya-kume.arglass" doesn't include the com.apple.developer.speech-recognition entitlement.`

次を試してください。

1. `ArGlass` ターゲット → `Signing & Capabilities` で `Automatically manage signing` を ON、Team を正しく選択
2. `+ Capability` から `Speech Recognition` を追加（追加済みでも一度削除→再追加が効くことがあります）
3. 古いプロファイルを掴んでいる場合は、`~/Library/MobileDevice/Provisioning Profiles/` を整理してから再ビルド
4. 手動署名の場合は Developer Portal 側で App ID/Provisioning Profile を作り直して、`com.apple.developer.speech-recognition` が入るように再ダウンロード
