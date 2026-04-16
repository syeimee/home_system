# 自宅家庭内システム 要件定義・外部設計書

## 目次
1. [システム概要](#1-システム概要)
2. [技術スタック](#2-技術スタック)
3. [インフラ構成](#3-インフラ構成)
4. [機能要件](#4-機能要件)
5. [非機能要件](#5-非機能要件)
6. [外部設計](#6-外部設計)
7. [API設計](#7-api設計)
8. [ディレクトリ構成](#8-ディレクトリ構成)
9. [環境変数一覧](#9-環境変数一覧)
10. [デプロイフロー](#10-デプロイフロー)
11. [セキュリティ設計](#11-セキュリティ設計)
12. [将来拡張](#12-将来拡張)

---

## 1. システム概要

自宅のIoTデバイス・クラウドサービスを統合し、家庭内の通知・自動化・デバイス制御を行うシステム。

### 解決する課題
- 採用面接の予定が入った際に家族が気づかず騒いでしまう
- Googleカレンダーへの予定追加を家族に手動で共有する手間がある
- SwitchBotデバイスを一元管理する画面がない

---

## 2. 技術スタック

| カテゴリ | 技術 |
|---------|------|
| バックエンド | Ruby on Rails |
| 非同期処理 | Sidekiq |
| キャッシュ/キュー | Redis |
| DB | **なし**（Redisのみ） |
| コンテナ | Docker / Docker Compose |
| リバースプロキシ | Nginx |
| CI/CD | GitHub Actions |
| インフラ | OCI（Always Free / AMD） |
| ドメイン | DuckDNS（無料） |
| SSL | Let's Encrypt |

---

## 3. インフラ構成

```
インターネット
    │
    ▼
DuckDNS（your-name.duckdns.org）
    │
    ▼
OCI 2台目（AMD / 1コア 1GB）
  ├── Nginx（80/443）
  │     └── Rails（3000 ※外部非公開）
  ├── Sidekiq
  └── Redis

GitHub
  └── GitHub Actions → OCI 2台目へ自動デプロイ

外部サービス連携
  ├── Microsoft Graph API（Outlook M365）
  ├── Google Calendar API
  ├── LINE Messaging API
  ├── VoiceMonkey API（Alexa）
  └── SwitchBot API
```

### Docker Compose構成

```yaml
services:
  nginx:      # 80/443 公開
  rails:      # 3000 内部のみ
  sidekiq:    # バックグラウンドジョブ
  redis:      # Sidekiqバックエンド・セッション管理
```

---

## 4. 機能要件

### 機能① Googleカレンダー → LINE通知

| 項目 | 内容 |
|------|------|
| トリガー | Googleカレンダーに予定が追加された瞬間 |
| 対象予定 | 全ての予定 |
| 通知先 | 家族グループLINE |
| 通知内容 | 予定名・開始日時 |
| 通知タイミング | 追加された瞬間にすぐ |

**通知メッセージ例**
```
📅 予定が追加されました
タイトル: 病院の予約
日時: 2025/05/10 14:00
```

---

### 機能② Outlook面接予定 → Googleカレンダー転写

| 項目 | 内容 |
|------|------|
| トリガー | OutlookのM365に予定が追加されたとき |
| 判定条件 | 件名に「面接」または「interview」を含む（大文字小文字を区別しない） |
| 転写タイトル形式 | `【面接】{元の件名}` |
| 転写内容 | タイトル・開始時刻・終了時刻 |
| 副作用 | 転写後、機能③のSidekiqジョブをスケジュール |

---

### 機能③ 面接前 Alexaアナウンス

| 項目 | 内容 |
|------|------|
| トリガー | Googleカレンダーの【面接】タグ付き予定 |
| アナウンス回数 | 2回（15分前・5分前） |
| 対象デバイス | 全台のAmazon Echo |
| 文言 | `config/settings.yml`でカスタマイズ可能 |

**デフォルト文言（`config/settings.yml`）**
```yaml
alexa:
  message_15: "面接が15分後に始まります。書斎付近では静かにお願いします。"
  message_5:  "面接まであと5分です。静かにお願いします。"
```

---

### 機能④ SwitchBotダッシュボード

| 項目 | 内容 |
|------|------|
| 対象デバイス | テープライト・ハブ |
| 操作 | オン・オフのみ |
| 表示 | 各デバイスの現在状態（オン・オフ） |
| 認証 | Google OAuth + MFA（要ログイン） |

---

## 5. 非機能要件

| 項目 | 内容 |
|------|------|
| 認証 | Google OAuth 2.0 + Googleの2段階認証（MFA委譲） |
| アクセス制御 | 許可メールアドレスを`config/settings.yml`で指定 |
| 通信 | 全てHTTPS（Let's Encrypt） |
| セッション | Redisセッションストア・有効期限7日 |
| Webhook保護 | Microsoft/Google署名検証 |
| 秘密情報管理 | GitHub Secretsで管理・OCI上の.envに展開 |
| 設定値管理 | `config/settings.yml`で管理（Gitで管理） |
| .envのGit管理 | .gitignoreで除外 |
| Sidekiq並列数 | 3（メモリ節約）|
| Pumaワーカー数 | 1（メモリ節約） |

---

## 6. 外部設計

### 画面一覧

| 画面名 | パス | 認証 |
|--------|------|------|
| ログイン画面 | `/login` | 不要 |
| SwitchBotダッシュボード | `/dashboard` | 必要 |
| Google OAuthコールバック | `/auth/google_oauth2/callback` | 不要 |

### ログイン画面（`/login`）

- Googleログインボタンのみ
- Google OAuth → 2段階認証 → ダッシュボードへリダイレクト

### SwitchBotダッシュボード（`/dashboard`）

```
┌─────────────────────────────────┐
│  🏠 Home System Dashboard       │
│  ログアウト                      │
├─────────────────────────────────┤
│  📍 デバイス一覧                  │
│                                 │
│  ┌──────────────┐  ┌──────────┐ │
│  │テープライト   │  │ ハブ     │ │
│  │ 状態: ON     │  │ 状態: OFF│ │
│  │ [ON] [OFF]   │  │[ON][OFF] │ │
│  └──────────────┘  └──────────┘ │
└─────────────────────────────────┘
```

- デバイス状態はページ読み込み時にSwitchBot APIから取得
- ON/OFFボタン押下でSwitchBot APIにコマンド送信
- 操作後に状態を自動更新

---

## 7. API設計

### Webhookエンドポイント

#### `POST /webhooks/google`
Googleカレンダーのプッシュ通知受信

| 項目 | 内容 |
|------|------|
| 認証 | `X-Goog-Channel-Token`ヘッダーで検証 |
| 処理 | 最新の追加イベントを取得 → `GoogleCalendarLineNotifyJob`をエンキュー |
| レスポンス | `200 OK` |

#### `POST /webhooks/outlook`
Microsoft Graph Webhookの受信

| 項目 | 内容 |
|------|------|
| 認証 | `clientState`パラメータで検証 |
| 処理 | `validationToken`があれば検証レスポンス返却。面接判定 → `OutlookSyncJob`をエンキュー |
| レスポンス | `200 OK` または `validationToken`の平文 |

### ダッシュボードエンドポイント

| メソッド | パス | 処理 |
|---------|------|------|
| GET | `/dashboard` | デバイス一覧・状態取得 |
| POST | `/dashboard/devices/:id/on` | デバイスON |
| POST | `/dashboard/devices/:id/off` | デバイスOFF |

---

## 8. ディレクトリ構成

```
home-system/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb   # 認証フィルター
│   │   ├── sessions_controller.rb      # Google OAuth
│   │   ├── dashboard_controller.rb     # SwitchBot操作画面
│   │   └── webhooks/
│   │       ├── google_controller.rb    # Googleカレンダー通知受信
│   │       └── outlook_controller.rb   # Outlook通知受信
│   ├── jobs/
│   │   ├── google_calendar_line_notify_job.rb  # 機能①
│   │   ├── outlook_sync_job.rb                 # 機能②
│   │   └── alexa_announce_job.rb               # 機能③
│   ├── services/
│   │   ├── microsoft_graph_service.rb   # Outlook APIクライアント
│   │   ├── google_calendar_service.rb   # Google Calendar APIクライアント
│   │   ├── line_service.rb              # LINE Messaging API
│   │   ├── voicemonkey_service.rb       # VoiceMonkey（Alexa）API
│   │   └── switchbot_service.rb         # SwitchBot APIクライアント
│   └── views/
│       ├── sessions/
│       │   └── new.html.erb             # ログイン画面
│       └── dashboard/
│           └── index.html.erb           # SwitchBotダッシュボード
├── config/
│   ├── routes.rb
│   ├── sidekiq.yml
│   ├── settings.yml                     # 設定値（Gitで管理）
│   └── initializers/
│       ├── omniauth.rb                  # Google OAuth設定
│       ├── session_store.rb             # Redisセッション設定
│       └── settings.rb                  # settings.yml読み込み
├── Dockerfile
├── docker-compose.yml
├── nginx/
│   └── conf.d/
│       └── home-system.conf
├── .env.example                         # 環境変数テンプレート
├── .gitignore                           # .envを除外
└── .github/
    └── workflows/
        └── deploy.yml                   # GitHub Actions自動デプロイ
```

---

## 9. 設定管理

秘密情報と設定値を分離して管理する。

### 分類の考え方

| 種別 | 保管場所 | Git管理 |
|------|---------|--------|
| 秘密情報（トークン・キー類） | `.env` + GitHub Secrets | ❌ 除外 |
| 設定値（文言・ID・デバイス名） | `config/settings.yml` | ✅ 管理 |

---

### `.env`（秘密情報のみ）

```bash
# Rails
RAILS_ENV=production
SECRET_KEY_BASE=

# Google
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REFRESH_TOKEN=
GOOGLE_WEBHOOK_SECRET=       # Webhookチャンネルトークン（任意の文字列）

# Microsoft Graph（Outlook）
MS_CLIENT_ID=
MS_CLIENT_SECRET=
MS_TENANT_ID=
MS_REFRESH_TOKEN=
MS_WEBHOOK_SECRET=           # clientState用（任意の文字列）

# LINE
LINE_CHANNEL_TOKEN=

# VoiceMonkey
VOICEMONKEY_TOKEN=

# SwitchBot
SWITCHBOT_TOKEN=
SWITCHBOT_SECRET=

# Redis
REDIS_URL=redis://redis:6379
```

---

### `config/settings.yml`（設定値）

```yaml
app:
  allowed_email: "your@example.com"   # ダッシュボードへのアクセス許可メールアドレス
  timezone: "Asia/Tokyo"

line:
  group_id: "Cxxxxxxxxxxxxxxxxx"    # 家族グループID

alexa:
  message_15: "面接が15分後に始まります。書斎付近では静かにお願いします。"
  message_5:  "面接まであと5分です。静かにお願いします。"
  devices:
    - "living-room-echo"
    - "bedroom-echo"

switchbot:
  devices:
    - id:   "device-id-1"
      name: "テープライト"
      type: "tape_light"
    - id:   "device-id-2"
      name: "ハブ"
      type: "hub"

interview:
  keywords:
    - "面接"
    - "interview"
  notify_before_minutes:
    - 15
    - 5
```

---

### `config/initializers/settings.rb`（読み込み設定）

```ruby
Settings = YAML.load_file(
  Rails.root.join("config/settings.yml")
).deep_symbolize_keys.freeze
```

**使い方例**

```ruby
Settings[:alexa][:message_15]
Settings[:alexa][:devices]
Settings[:interview][:keywords]
Settings[:switchbot][:devices].each { |d| d[:id] }
Settings[:line][:group_id]
```

---

## 10. デプロイフロー

### GitHub Actions（`.github/workflows/deploy.yml`）

```yaml
name: Deploy to OCI

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to OCI
        uses: appleboy/ssh-action@v1
        with:
          host:     ${{ secrets.OCI_HOST }}
          username: ${{ secrets.OCI_USER }}
          key:      ${{ secrets.OCI_SSH_KEY }}
          script: |
            cd ~/home-system

            # GitHub Secretsから.envを生成（秘密情報のみ）
            cat > .env << EOF
            RAILS_ENV=production
            SECRET_KEY_BASE=${{ secrets.SECRET_KEY_BASE }}
            GOOGLE_CLIENT_ID=${{ secrets.GOOGLE_CLIENT_ID }}
            GOOGLE_CLIENT_SECRET=${{ secrets.GOOGLE_CLIENT_SECRET }}
            GOOGLE_REFRESH_TOKEN=${{ secrets.GOOGLE_REFRESH_TOKEN }}
            GOOGLE_WEBHOOK_SECRET=${{ secrets.GOOGLE_WEBHOOK_SECRET }}
            MS_CLIENT_ID=${{ secrets.MS_CLIENT_ID }}
            MS_CLIENT_SECRET=${{ secrets.MS_CLIENT_SECRET }}
            MS_TENANT_ID=${{ secrets.MS_TENANT_ID }}
            MS_REFRESH_TOKEN=${{ secrets.MS_REFRESH_TOKEN }}
            MS_WEBHOOK_SECRET=${{ secrets.MS_WEBHOOK_SECRET }}
            LINE_CHANNEL_TOKEN=${{ secrets.LINE_CHANNEL_TOKEN }}
            VOICEMONKEY_TOKEN=${{ secrets.VOICEMONKEY_TOKEN }}
            SWITCHBOT_TOKEN=${{ secrets.SWITCHBOT_TOKEN }}
            SWITCHBOT_SECRET=${{ secrets.SWITCHBOT_SECRET }}
            REDIS_URL=redis://redis:6379
            EOF
            # 設定値はconfig/settings.ymlで管理（Gitに含まれる）

            git pull origin main
            docker compose build --no-cache
            docker compose up -d
            docker image prune -f
```

### GitHub Secretsに登録するもの

```
# OCI接続
OCI_HOST
OCI_USER
OCI_SSH_KEY

# Rails
SECRET_KEY_BASE

# Google
GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET
GOOGLE_REFRESH_TOKEN
GOOGLE_WEBHOOK_SECRET

# Microsoft
MS_CLIENT_ID
MS_CLIENT_SECRET
MS_TENANT_ID
MS_REFRESH_TOKEN
MS_WEBHOOK_SECRET

# LINE
LINE_CHANNEL_TOKEN

# VoiceMonkey
VOICEMONKEY_TOKEN

# SwitchBot
SWITCHBOT_TOKEN
SWITCHBOT_SECRET
```

> 設定値（デバイスID・文言・グループIDなど）は`config/settings.yml`で管理するためSecretsへの登録不要

---

## 11. セキュリティ設計

### ネットワーク層

| ポート | 公開範囲 | 用途 |
|--------|---------|------|
| 22 | 自分のIPのみ | SSH |
| 80 | 全開放 | HTTPSリダイレクト |
| 443 | 全開放 | HTTPS |
| 3000 | 内部のみ | Rails（Nginx経由） |

### アプリ層

| 対象 | 認証方式 |
|------|---------|
| ダッシュボード | Google OAuth + Googleの2段階認証 |
| Webhook（Google） | X-Goog-Channel-Tokenヘッダー検証 |
| Webhook（Outlook） | clientStateパラメータ検証 |
| SwitchBot操作 | ログイン済みセッション必須 |

### セキュリティチェックリスト

```
✅ HTTPS（Let's Encrypt）
✅ Google OAuth + MFA
✅ Webhook署名検証
✅ 環境変数はGitHub Secretsで管理
✅ .envはGitignoreで除外
✅ SSHは鍵認証のみ（パスワード認証無効）
✅ 3000番ポートは外部非公開
✅ Redisセッションストア（有効期限7日）
⬜ Fail2ban（SSH不正アクセス対策）
⬜ 定期的なdocker imageアップデート
⬜ Let's Encrypt証明書の自動更新
```

---

## 12. 将来拡張

### Phase 2（NAS稼働後）
- WireGuard VPN構築（外出先から自宅への安全接続）
- Raspberry Pi自動園芸システム連携
  - 土壌水分センサー → 自動水やり
  - センサーデータをRailsに送信（`POST /api/sensors`）

### Phase 3（発展）
- Authelia SSO（全サービスを1つのログインで管理）
- Grafana（サーバー・NAS監視ダッシュボード）
- Outline Wiki（ドキュメント管理）

### 将来のDBが必要になるタイミング
- センサーデータの履歴・グラフ表示
- 面接結果の記録・統計
- ダッシュボードのログ表示

→ そのタイミングでPostgreSQLをDocker Composeに追加する
