# CLAUDE.md

このファイルは、このリポジトリでコードを扱う際にClaude Code (claude.ai/code) にガイダンスを提供します。

## プロジェクト概要

MyAHK v2は、AutoHotkey v2を使用したカスタムランチャー・ツールマネージャーです。無変換キーをトリガーとしたキーボードショートカットで、アプリケーションやツールを素早く起動できます。

## 開発環境

- **言語**: AutoHotkey v2.0+
- **プラットフォーム**: Windows 10/11
- **デバッグ**: VS Codeの`ahk2`デバッガーを使用

## 重要なコマンド

### テスト実行

個別テストの実行：
```bash
autohotkey.exe tests/test_create_obsidian_url.ahk
autohotkey.exe tests/test_uri_decode.ahk
```

### アプリケーション実行

メインスクリプトの実行：
```bash
autohotkey.exe myahk_v2.ahk
```

または、VS Codeのデバッガーを使用（F5キーまたは「実行とデバッグ」から「AutoHotkey v2 Debugger」を選択）

## アーキテクチャ

### エントリーポイントと依存関係

`myahk_v2.ahk`がメインエントリーポイントで、以下の順序で各モジュールをインクルード：

1. `src/config/constants.ahk` - グローバル定数とパス設定（Constantsクラス）
2. `src/setup/initialization.ahk` - アプリケーション初期化処理
3. `src/menu/menu_setup.ahk` - メニュー構築とハンドラー登録
4. `src/handlers/app_launcher.ahk` - アプリケーション起動ハンドラー
5. `src/utils/common_func.ahk` - 汎用ユーティリティ関数
6. `src/handlers/myfunc_handler.ahk` - テキスト処理・ファイル操作ハンドラー
7. その他のユーティリティ

### 初期化フロー

1. `initializeApplication()` が実行され：
   - 必要なフォルダ作成（`%USERPROFILE%\.myahk_v2\`、`tools\`、`work_dir\`、`backup\`）
   - ツールフォルダのバックアップ実行
   - 空フォルダの削除
   - ショートカットの検証（オプション）

2. メニューシステム構築：
   - `createMainMenu()` - メインメニュー
   - `createToolsMenu()` - よく使うツールメニュー（手動登録）
   - `createToolsAllMenu()` - 全ツールメニュー（自動検出）
   - `createFuncMenu()` - 機能メニュー

3. ホットキー登録：
   - 無変換キー（vk1D）をベースとした各種ショートカット設定

### 重要な設計パターン

#### 定数管理
すべてのフォルダパスとユーザー固有設定は`Constants`クラス（`src/config/constants.ahk`）で集中管理。ユーザー名（`daido`か否か）によって設定が切り替わる。

#### メニューシステム
- `addMenu()` 関数でメニュー項目を動的に追加
- ショートカット（.lnk）ファイルからターゲットパスを取得し、アイコンも自動設定
- ハンドラー関数は`hash`マップでメニュー名とパスを紐付け

#### ショートカット管理
- `getLnkTarget()` でショートカットファイルの実際のパスを取得
- `shortcut_validator.ahk` で無効なショートカットを検証・修復
- バックアップ機能でツールフォルダを安全に管理

#### Obsidian統合
- URI scheme（`obsidian://`）を使用してObsidianと連携
- ユーザーごとに異なるVaultを使用（`Constants.OBSIDIAN_VAULT`）
- `create_obsidian_url.ahk` でファイルパスをObsidian WikiLink URLに変換

### 主要モジュールの役割

- **constants.ahk**: すべてのフォルダパス、ユーザー設定、Obsidian URI定義
- **initialization.ahk**: 起動時のフォルダ作成、バックアップ、検証処理
- **menu_setup.ahk**: メニュー構築ロジック、メニューハンドラー関数
- **app_launcher.ahk**: 一時メモ、Obsidian、作業フォルダなど特定アプリ起動処理
- **common_func.ahk**: `openAny()`, `pasteText()`, `getLnkTarget()`など汎用関数
- **myfunc_handler.ahk**: テキスト整形（空白除去、引用追加、メール用整形など）
- **shortcut_validator.ahk**: ショートカット検証、修復、バックアップ機能
- **shortcut_ui_handler.ahk**: ショートカット管理UI表示

## 新機能追加時のガイドライン

### 新しいツールをメニューに追加

`src/menu/menu_setup.ahk`の`createToolsMenu()`内に追加：
```autohotkey
addMenu(toolsMenu, menuHandler, hash, "表示名", "ファイル名.lnk", "")
```

### 新しいホットキーの追加

`myahk_v2.ahk`にホットキー定義を追加：
```autohotkey
vk1D & [key]::[アクション]
```

### 新しいFuncメニュー機能の追加

1. `src/handlers/myfunc_handler.ahk`にハンドラー関数を作成
2. `src/menu/menu_setup.ahk`の`createFuncMenu()`にメニュー項目を追加

## ユーザー設定のカスタマイズ

- `Constants`クラスの`IS_DAIDO_USER`で条件分岐
- 新しいユーザーを追加する場合は`constants.ahk`を修正し、ユーザー名チェックロジックを拡張

## テストについて

- テストファイルは`tests/`ディレクトリに配置
- テスト結果は`test_results.txt`に出力される形式を使用
- 各ユーティリティ関数（URI処理、Obsidian URL生成など）に対してテストを作成
