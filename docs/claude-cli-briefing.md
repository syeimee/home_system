# Claude CLI への引き継ぎ資料

## このドキュメントの使い方

`home-system-requirements.md`と一緒にClaude CLIに渡してください。

```bash
claude --context home-system-requirements.md --context claude-cli-briefing.md
```

---

## プロジェクト概要

自宅家庭内の通知・自動化・IoT制御を行うRailsアプリを実装する。
要件定義・外部設計は`home-system-requirements.md`に記載済み。
これからRailsアプリの実装を始める段階。

---

## 実装の前提条件

### インフラ
- OCI（Oracle Cloud Infrastructure）AMD Always Free インスタンス
- Ubuntu 24系
- Docker / Docker Compose インストール済み
- Nginx + Let's Encrypt（DuckDNSドメイン）
- GitHub Actions で main ブランチへのpush時に自動デプロイ

### 言語・フレームワーク
- Ruby on Rails（最新安定版）
- Sidekiq（非同期ジョブ）
- Redis（Sidekiqバックエンド・セッション管理）
- DBは**使わない**（Redisのみ）

---

## 設定管理の方針（重要）

**必ず以下のルールに従うこと。**

### `.env`に書くもの（秘密情報のみ）
- APIトークン・シークレット・クライアントID/Secret
- リフレッシュトークン
- Webhook検証用シークレット
- `SECRET_KEY_BASE`
- `.gitignore`で除外済み

### `config/settings.yml`に書くもの（設定値）
- Alexaアナウンス文言
- 面接判定キーワード
- 通知タイミング（分数）
- SwitchBotデバイスID・名前
- LINEグループID
- アクセス許可メールアドレス
- AlexaデバイスID
- **Gitで管理する**

### 読み込み方法
```ruby
# config/initializers/settings.rb
Settings = YAML.load_file(
  Rails.root.join("config/settings.yml")
).deep_symbolize_keys.freeze

# 使い方
Settings[:alexa][:message_15]
Settings[:interview][:keywords]
```

---

## セキュリティ要件（必ず守ること）

- ダッシュボードはGoogle OAuth + 2段階認証（MFA委譲）で保護
- 許可メールアドレスは`Settings[:app][:allowed_email]`で1件のみ
- WebhookエンドポイントはCSRF除外 + 署名検証で保護
  - Google: `X-Goog-Channel-Token`ヘッダー検証
  - Outlook: `clientState`パラメータ検証
- セッションはRedisストア（有効期限7日）
- 3000番ポートは外部非公開（Nginx経由のみ）

---

## メモリ節約設定（OCI 1GBのため必須）

```yaml
# config/sidekiq.yml
:concurrency: 3
```

```ruby
# config/puma.rb
workers 1
threads 1, 3
```

---

## 実装する機能（優先順）

### 1. Google OAuth認証（全機能の基盤）
- `omniauth-google-oauth2` gem使用
- Calendarスコープも同時に取得
- Redisセッションストア

### 2. 機能① Googleカレンダー → LINE通知
- Google Calendar Push通知のWebhook受信
- `GoogleCalendarLineNotifyJob`をエンキュー
- LINEグループに予定名・日時を送信

### 3. 機能④ SwitchBotダッシュボード
- `/dashboard`でデバイス一覧・状態表示
- オン・オフ操作のみ
- SwitchBot API v1.1（HMAC-SHA256署名必要）

### 4. 機能② Outlook → Googleカレンダー転写
- Microsoft Graph Webhook受信
- 件名に「面接」「interview」を含む予定を検知
- `【面接】{元の件名}`形式でGoogleカレンダーに転写
- 転写後、機能③のSidekiqジョブをスケジュール

### 5. 機能③ 面接前Alexaアナウンス
- 面接15分前・5分前にSidekiqジョブを起動
- VoiceMonkey API経由で全EchoにアナウンスをPOST
- 文言は`Settings[:alexa][:message_15]`・`Settings[:alexa][:message_5]`から取得

---

## 使用するGem

```ruby
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection'
gem 'redis-session-store'
gem 'sidekiq'
gem 'line-bot-api'
gem 'google-apis-calendar_v3'
gem 'httparty'
```

---

## 外部APIの注意点

### SwitchBot API v1.1
- HMAC-SHA256署名が必要（token + timestamp + nonceを署名）
- デバイス一覧取得: `GET /v1.1/devices`
- コマンド送信: `POST /v1.1/devices/{deviceId}/commands`

### Microsoft Graph Webhook
- 有効期限が最大3日（定期的な更新ジョブが必要）
- 登録時に`validationToken`のレスポンスが必要

### Google Calendar Push通知
- WebhookチャンネルにTTLがある（定期的な更新が必要）
- `X-Goog-Channel-Token`で認証

### VoiceMonkey
- `POST https://api.voicemonkey.io/trigger`
- クエリパラメータ: `token` / `device` / `text`

---

## ディレクトリ構成（期待する構成）

```
home-system/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── sessions_controller.rb
│   │   ├── dashboard_controller.rb
│   │   └── webhooks/
│   │       ├── google_controller.rb
│   │       └── outlook_controller.rb
│   ├── jobs/
│   │   ├── google_calendar_line_notify_job.rb
│   │   ├── outlook_sync_job.rb
│   │   └── alexa_announce_job.rb
│   ├── services/
│   │   ├── microsoft_graph_service.rb
│   │   ├── google_calendar_service.rb
│   │   ├── line_service.rb
│   │   ├── voicemonkey_service.rb
│   │   └── switchbot_service.rb
│   └── views/
│       ├── sessions/new.html.erb
│       └── dashboard/index.html.erb
├── config/
│   ├── routes.rb
│   ├── sidekiq.yml
│   ├── settings.yml               ← Git管理
│   └── initializers/
│       ├── omniauth.rb
│       ├── session_store.rb
│       └── settings.rb
├── Dockerfile
├── docker-compose.yml
├── nginx/conf.d/home-system.conf
├── .env.example                   ← Git管理（値は空欄）
├── .env                           ← Git除外
├── .gitignore
└── .github/workflows/deploy.yml
```

---

## `.env.example`のテンプレート（値は空欄で作成）

```bash
# Rails
RAILS_ENV=production
SECRET_KEY_BASE=

# Google
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REFRESH_TOKEN=
GOOGLE_WEBHOOK_SECRET=

# Microsoft Graph
MS_CLIENT_ID=
MS_CLIENT_SECRET=
MS_TENANT_ID=
MS_REFRESH_TOKEN=
MS_WEBHOOK_SECRET=

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

## 最初に作成してほしいもの

1. Railsアプリの雛形（`rails new`）
2. 上記ディレクトリ構成のファイル群
3. `Dockerfile` / `docker-compose.yml`
4. `config/settings.yml`（サンプル値入り）
5. `.env.example`
6. `.github/workflows/deploy.yml`
7. Google OAuth認証の実装から始める
