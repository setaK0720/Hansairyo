# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリのコードで作業する際のガイダンスを提供します。

## プロジェクト概要

これは「Hansairyo」という名前のMetaTrader 4用MQL4エキスパートアドバイザープロジェクトです。プロジェクトには標準的なMQL4構造を持つ基本的なEAテンプレートが含まれています。

## ファイル構造

- `Hansairyo.mq4` - メインのエキスパートアドバイザーソースコードファイル
- `Hansairyo.mqproj` - MetaTraderプロジェクト設定ファイル（JSON形式）

## MQL4開発

このプロジェクトはMetaTrader 4プラットフォーム用のMQL4言語を使用しています。主な特徴：

- 厳密コンパイルモード用の`#property strict`ディレクティブを使用
- OnInit()、OnDeinit()、OnTick()関数を持つ標準的なEA構造
- MT4プラットフォーム用のエキスパートアドバイザープログラムタイプとして設定

## コンパイル

MQL4ファイルは通常、MetaTrader 4のMetaEditor IDE内で、または利用可能な場合はコマンドラインツールを通じてコンパイルされます。プロジェクトファイルでは、メインの.mq4ファイルのコンパイルが有効になっています。