# MyAHK v2

![AutoHotkey v2](https://img.shields.io/badge/AutoHotkey-v2.0+-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## 📋 概要

MyAHK v2は、AutoHotkey v2を使用したカスタムランチャー・ツールマネージャーです。**無変換キー**をトリガーとしたキーボードショートカットで、よく使うアプリケーションやツールを素早く起動できます。

### 🎯 主な特徴

- **🚀 高速アクセス**: 無変換キー + 文字キーでツール・アプリを瞬時に起動
- **📂 自動管理**: ツールフォルダの自動作成・バックアップ機能
- **🔗 Obsidian連携**: 高度なObsidianワークフロー統合
- **📝 テキスト処理**: 書式なしペースト、テキスト整形機能
- **🛠️ 拡張性**: 新しいツールやショートカットの簡単追加
- **🧪 テスト対応**: テストファイル完備で安全な開発


## 🚀 利用者向けガイド

### 📋 前提条件

- **OS**: Windows 10/11
- **必須**: [AutoHotkey v2.0以上](https://www.autohotkey.com/)
- **オプション**: お好みのアプリケーション・ツールのショートカット（.lnk）ファイル

### 🔧 インストール・セットアップ

1. **AutoHotkey v2のインストール**
   ```
   https://www.autohotkey.com/ からダウンロードしてインストール
   ```

2. **プロジェクトのダウンロード**
   ```bash
   git clone [このリポジトリのURL]
   cd myahk_v2
   ```

3. **設定ファイルのセットアップ**

   `config_samples\`フォルダ内のサンプルファイルを`%USERPROFILE%\.myahk_v2\`にコピーして、`.sample`拡張子を削除：

   ```powershell
   # PowerShellで実行（推奨）
   $dest = "$env:USERPROFILE\.myahk_v2"
   New-Item -ItemType Directory -Path $dest -Force
   Copy-Item "config_samples\user_config.ini.sample" "$dest\user_config.ini"
   Copy-Item "config_samples\tools_menu.txt.sample" "$dest\tools_menu.txt"
   Copy-Item "config_samples\main_menu.txt.sample" "$dest\main_menu.txt"
   ```

   または手動でコピーして、必要に応じて編集してください：
   - **`user_config.ini`**: 個人設定（一時メモパス、外部アプリ連携設定など）
   - **`tools_menu.txt`**: ツールメニュー（無変換+T）の項目設定
   - **`main_menu.txt`**: メインメニューのアクション項目とホットキー設定

4. **初回起動**
   ```
   myahk_v2.ahk をダブルクリックで実行
   ```

5. **自動作成されるフォルダ**
   - `%USERPROFILE%\.myahk_v2\` - 設定・データフォルダ
   - `%USERPROFILE%\.myahk_v2\tools\` - ツールショートカット格納
   - `%USERPROFILE%\.myahk_v2\work_dir\` - 作業フォルダ
   - `backup\` - バックアップフォルダ

### 🎮 基本的な使い方

#### 🔑 メインキーショートカット一覧

| ショートカット | 機能 | 説明 |
|:---:|:---|:---|
| **変換** | メインメニュー表示 | 全機能のメニューを表示 |
| **無変換 + T** | ツールメニュー | よく使うツールの選択メニュー |
| **無変換 + A** | 全ツールメニュー | toolsフォルダ内の全ツール表示 |
| **無変換 + S** | Funcメニュー | テキスト処理・ファイル操作メニュー |

#### 🛠️ 直接起動ショートカット（設定例）

以下は`main_menu.txt`で設定可能なホットキーの例です。お好みに応じてカスタマイズできます。

| ショートカット | 機能例 |
|:---:|:---|
| **無変換 + P** | 画面キャプチャツール |
| **無変換 + E** | テキストエディタ |
| **無変換 + M** | 一時メモを開く |
| **無変換 + W** | クリップボードの内容をURL/ファイルとして開く |
| **無変換 + V** | 書式なしペースト |
| **無変換 + Q** | 作業フォルダを開く |

※ 上記は設定例です。`main_menu.txt`を編集することで自由にカスタマイズできます。

#### 📝 Funcメニュー機能

| 機能 | 説明 |
|:---|:---|
| **空白除去** | テキストの不要な空白を削除 |
| **ゴミ箱を空にする** | システムのゴミ箱を完全に空にする |
| **ファイルバックアップ** | 重要ファイルの自動バックアップ |
| **メール用ファイルパス整形** | ファイルパスをメール送信用に整形 |
| **行頭に(> )** | テキストの各行頭に引用マークを追加 |
| **Obsidianリンク生成** | Obsidian Wikilink形式URLを生成（Obsidianユーザー向け） |
| **ショートカット管理** | 無効なショートカットの検出・管理 |

### 🔧 カスタマイズ方法

#### ツールの追加

1. `%USERPROFILE%\.myahk_v2\tools\` フォルダにショートカット（.lnk）を配置
2. アプリケーションを再起動
3. **無変換 + A** で追加したツールが表示されます

#### よく使うツールの登録（設定ファイルベース）

`%USERPROFILE%\.myahk_v2\tools_menu.txt` を編集：

```
; 表示名,ショートカットファイル名
テキストエディタ,editor.lnk
開発ツール,devtool.lnk
```

コード編集不要で、設定ファイルを変更するだけでメニュー項目を追加・削除できます。

#### ホットキーのカスタマイズ

`%USERPROFILE%\.myahk_v2\main_menu.txt` を編集：

```
; 表示名,アクションタイプ,ホットキー
p:キャプチャツール,tool:capture.lnk,p
e:エディタ,tool:editor.lnk,e
m:一時メモを開く,temp_memo,m
v:書式なしペースト,paste_plain,v
```

利用可能なアクションタイプ：
- `tool:ファイル名.lnk` - toolsフォルダ内のツールを起動
- `temp_memo` - 一時メモを開く
- `obsidian` / `obsidian_switcher` / `obsidian_memos` - Obsidian連携（Obsidianユーザー向け）
- `open_clipboard` - クリップボードの内容を開く
- `paste_plain` - 書式なしペースト
- `open_work_dir` - 作業フォルダを開く
- `quickdash` - QuickDashLauncher連携（該当ツールユーザー向け）

---

## 📄 ライセンス

MIT License - 詳細は [LICENSE](LICENSE) ファイルを参照してください。

## 🤝 貢献

バグ報告や機能リクエストは、[Issues](../../issues) からお願いします。

プルリクエストも歓迎します！

## 📮 サポート

- 問題が発生した場合は、[Issues](../../issues) で報告してください
- 使い方の質問も Issues で受け付けています

---

**MyAHK v2** - あなたの作業効率を向上させる、カスタマイズ可能なキーボードランチャー
