# Home System

自宅の IoT デバイス・クラウドサービスを統合し、家庭内の通知・自動化・デバイス制御を行うシステム。

## 機能一覧

| 機能 | 概要 |
|------|------|
| SwitchBot ダッシュボード | 照明デバイスの状態表示・ON/OFF 操作（リアルタイム同期） |
| Google カレンダー → LINE 通知 | 予定追加時に家族グループ LINE へ自動通知 |
| 面接アラート | カレンダーの面接予定を検知し、Alexa で音声アナウンス |
| メトロポリタン美術館背景 | Met Museum API から絵画を取得し、ダッシュボード背景に表示 |
| カレンダーパネル | 今日・明日の予定をダッシュボード右側に表示 |

## システム構成

```mermaid
graph TB
    subgraph "クライアント"
        Browser["ブラウザ / Echo Show"]
    end

    subgraph "OCI (Always Free)"
        Nginx["Nginx<br/>リバースプロキシ + SSL"]
        Rails["Rails<br/>Puma"]
        Sidekiq["Sidekiq<br/>バックグラウンドジョブ"]
        Redis["Redis<br/>セッション / キュー / トークン"]
    end

    subgraph "外部サービス"
        Google["Google Calendar API"]
        LINE["LINE Messaging API"]
        SwitchBot["SwitchBot API"]
        Alexa["Alexa API<br/>(amazon.co.jp)"]
        Met["Metropolitan Museum<br/>Collection API"]
        DuckDNS["DuckDNS"]
        LetsEncrypt["Let's Encrypt"]
    end

    Browser <-->|HTTPS / WebSocket| Nginx
    Nginx <--> Rails
    Rails <--> Redis
    Sidekiq <--> Redis
    Rails <--> Google
    Sidekiq <--> Google
    Sidekiq <--> LINE
    Sidekiq <--> Alexa
    Rails <--> SwitchBot
    Sidekiq <--> Met
    DuckDNS -.->|DNS| Nginx
    LetsEncrypt -.->|SSL証明書| Nginx
```

## 機能詳細

### SwitchBot ダッシュボード

```mermaid
sequenceDiagram
    participant User as ユーザー
    participant Dashboard as ダッシュボード
    participant Rails
    participant SwitchBot as SwitchBot API
    participant Cable as ActionCable
    participant Webhook as SwitchBot Webhook

    User->>Dashboard: カードをタップ
    Dashboard->>Rails: POST /dashboard/devices/:id/on
    Rails->>SwitchBot: コマンド送信
    SwitchBot-->>Webhook: 状態変更通知
    Webhook->>Rails: POST /webhooks/switchbot
    Rails->>Cable: broadcast(device_status)
    Cable->>Dashboard: WebSocket push
    Dashboard->>Dashboard: UI更新（リアルタイム）
```

### Google カレンダー → LINE 通知

```mermaid
sequenceDiagram
    participant GCal as Google Calendar
    participant Webhook as Google Webhook
    participant Sidekiq
    participant Google as Google Calendar API
    participant LINE as LINE Messaging API

    GCal->>Webhook: Push通知 (予定追加)
    Webhook->>Sidekiq: GoogleCalendarLineNotifyJob
    Sidekiq->>Google: 最新イベント取得
    Google-->>Sidekiq: イベントデータ
    Sidekiq->>LINE: 家族グループに通知送信
    Note over LINE: 📅 予定が追加されました<br/>タイトル: 〇〇<br/>日時: 2026/04/20 14:00
```

### 面接アラート（Alexa アナウンス）

```mermaid
sequenceDiagram
    participant Scheduler as Sidekiq Scheduler<br/>(15分ごと)
    participant Job as InterviewAlertCheckJob
    participant Google as Google Calendar API
    participant Redis
    participant Alexa as AlexaAnnounceJob
    participant Echo as Echo Show 15

    Scheduler->>Job: 定期実行
    Job->>Google: 今日の予定を取得
    Google-->>Job: イベント一覧
    Job->>Job: 面接キーワード判定<br/>(「面接」「interview」)
    Job->>Redis: 重複チェック
    Job->>Alexa: 15分前・5分前にスケジュール
    Note over Alexa: wait_until: 開始15分前
    Alexa->>Echo: 「面接が15分後に始まります。<br/>書斎付近では静かにお願いします。」
```

### メトロポリタン美術館背景

```mermaid
sequenceDiagram
    participant Scheduler as Sidekiq Scheduler<br/>(1時間ごと)
    participant Job as MetArtRefreshJob
    participant Met as Met Museum API
    participant Redis
    participant Dashboard as ダッシュボード

    Scheduler->>Job: 定期実行
    Job->>Met: 風景画を検索
    Met-->>Job: 作品リスト
    Job->>Met: ランダムに作品詳細取得
    Met-->>Job: 画像URL・タイトル・作者
    Job->>Redis: 現在の作品情報を保存
    Dashboard->>Redis: 作品情報を取得
    Dashboard->>Dashboard: 背景画像を表示
```

## 技術スタック

| カテゴリ | 技術 |
|---------|------|
| バックエンド | Ruby on Rails 8 |
| 非同期処理 | Sidekiq + sidekiq-scheduler |
| リアルタイム通信 | ActionCable (WebSocket) |
| データストア | Redis（DB なし） |
| コンテナ | Docker / Docker Compose |
| リバースプロキシ | Nginx |
| CI/CD | GitHub Actions |
| インフラ | OCI Always Free (AMD 1コア / 1GB) |
| ドメイン | DuckDNS |
| SSL | Let's Encrypt |

## セキュリティ

- Google OAuth 2.0 + Google 2段階認証によるログイン
- 許可メールアドレスのホワイトリスト制御
- 全 Webhook エンドポイントに署名検証（HMAC-SHA256 / secure_compare）
- ActionCable WebSocket 接続に認証必須
- Redis 内のトークン・Cookie は `ActiveSupport::MessageEncryptor` で暗号化
- セッション Cookie に `secure` / `SameSite: Lax` を設定
- ログのパラメータフィルタリング（token, secret, cookie 等）
- HTTPS 強制（Let's Encrypt）

## セットアップ

### 前提条件

- Docker / Docker Compose
- DuckDNS ドメイン
- Let's Encrypt SSL 証明書

### 1. リポジトリのクローン

```bash
git clone https://github.com/syeimee/home-system.git
cd home-system
```

### 2. 環境変数の設定

```bash
cp .env.example .env
# .env を編集して各APIキー・トークンを設定
```

### 3. 起動

```bash
docker compose up -d --build
```

### 4. 初回ログイン

`https://your-domain.duckdns.org/` にアクセスし、Google アカウントでログイン。

### 外部サービスの設定

| サービス | 必要な設定 |
|---------|-----------|
| Google Cloud Console | OAuth クライアント ID / Calendar API 有効化 |
| LINE Developers | Messaging API チャネル / Webhook URL |
| SwitchBot | 開発者向けオプションからトークン取得 |
| Alexa | alexa-cookie-cli で Cookie 取得 → Redis に保存 |

## ライセンス

MIT
