# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

Hansairyoは裁量エントリーしたポジションに対して自動でナンピン（追加エントリー）を行うMetaTrader 4用のExpert Advisorです。手動でエントリーしたポジションを検出し、不利な方向に価格が動いた場合に自動的にポジションサイズを倍増させながら追加エントリーを行い、平均取得単価から一定のpipsで利益確定を実行します。

## アーキテクチャ

### 主要コンポーネント

1. **ポジション監視システム** (`UpdatePositionInfo()`)
   - 既存ポジションの検出と平均取得単価の計算
   - マジックナンバーによるポジション識別（0も含む裁量ポジション対応）

2. **ナンピン判定エンジン** (`CheckNampinCondition()`)
   - スプレッドを考慮した動的ナンピン条件
   - 調整ナンピン幅 = 基準pips + (スプレッド × スプレッド倍率)
   - インターバル制御による連続エントリー防止

3. **自動決済システム** (`CheckTakeProfitCondition()`, `CloseAllPositions()`)
   - 平均取得単価ベースの利益確定
   - 全ポジション一括決済

4. **リアルタイム表示** (`UpdateDisplay()`)
   - ポジション情報、含み損益、スプレッド情報の表示
   - ポジションなし時の表示リセット

### パラメーター設定

- `InitialLot`: 初期ロット数（ナンピン計算基準）
- `Multiplier`: ナンピン倍率（各追加エントリーのサイズ倍率）
- `NampinPips`: 基準ナンピン幅（pips）
- `TakeProfitPips`: 利確幅（平均価格からのpips）
- `NampinInterval`: ナンピン実行間隔（秒）
- `SpreadMultiplier`: スプレッド補正倍率

## コンパイル

### Windows環境（推奨）
1. MetaTrader 4のMetaEditorを開く（F4キー）
2. Hansairyo.mq4を開く
3. F7キーでコンパイル

### WSL環境（コマンドライン）
```bash
# Wineを使用したコンパイル
wine "/mnt/c/Program Files (x86)/XMTrading MT4/metaeditor.exe" /compile:"$(pwd)/Hansairyo.mq4"

# ファイルをWindows側にコピーしてからコンパイル
cp Hansairyo.mq4 /mnt/c/temp/
```

## 開発ワークフロー

1. **機能追加時**: 各コンポーネントの責務を明確に分離
2. **パラメーター変更**: input変数で設定可能にし、リアルタイム調整を考慮
3. **デバッグ**: Print()文による詳細ログ出力を活用
4. **テスト**: Strategy Testerでの動作確認とライブ環境での慎重なテスト

## 注意事項

- 裁量ポジション（MagicNumber=0）と自動ポジション（MagicNumber指定）の両方を監視
- スプレッドの動的変化に対応したナンピン判定
- ポジションサイズの急激な増加に注意（Multiplier設定）