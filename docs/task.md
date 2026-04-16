# 実装タスク一覧

## Phase 0: プロジェクト基盤

- [x] Rails アプリ雛形作成（`rails new --skip-active-record`）
- [x] Gemfile 整備（omniauth, sidekiq, line-bot-api, google-apis-calendar_v3, httparty 等）
- [x] `config/settings.yml` 作成（サンプル値入り）
- [x] `config/initializers/settings.rb` 作成（Settings 定数の定義）
- [x] `.env.example` 作成（値は空欄）
- [x] `.gitignore` に `.env` を追加
- [x] Dockerfile 作成
- [x] docker-compose.yml 作成（rails, sidekiq, redis, nginx）
- [x] Nginx 設定ファイル作成（`nginx/conf.d/home-system.conf`）
- [x] Puma 設定（workers 1, threads 1..3）
- [x] Sidekiq 設定（concurrency: 3）
- [x] GitHub Actions デプロイワークフロー（`.github/workflows/deploy.yml`）

## Phase 1: Google OAuth 認証（全機能の基盤）

- [x] `omniauth.rb` initializer 作成（Google OAuth 設定）
- [x] `session_store.rb` initializer 作成（Redis セッションストア、有効期限7日）
- [x] `routes.rb` にログイン・ログアウト・OAuth コールバックのルート定義
- [x] `ApplicationController` に `require_login` フィルター実装
- [x] `SessionsController` 実装（OAuth コールバック処理・許可メール検証・ログアウト）
- [x] ログイン画面ビュー（`sessions/new.html.erb`）

## Phase 2: 機能① Google カレンダー → LINE 通知

- [x] `GoogleCalendarService` 実装（予定取得 API クライアント）
- [x] `LineService` 実装（LINE Messaging API v2 クライアント）
- [x] `Webhooks::GoogleController` 実装（Push 通知受信・署名検証・CSRF 除外）
- [x] `GoogleCalendarLineNotifyJob` 実装（予定取得 → LINE 送信）
- [x] `routes.rb` に `POST /webhooks/google` 追加

## Phase 3: 機能④ SwitchBot ダッシュボード

- [x] `SwitchbotService` 実装（HMAC-SHA256 署名・デバイス一覧取得・コマンド送信）
- [x] `DashboardController` 実装（`before_action :require_login`・デバイス一覧・ON/OFF 操作）
- [x] ダッシュボードビュー（`dashboard/index.html.erb`）
- [x] `routes.rb` にダッシュボード関連ルート追加

## Phase 4: 機能② Outlook → Google カレンダー転写

- [x] `MicrosoftGraphService` 実装（Outlook API クライアント・トークン更新）
- [x] `Webhooks::OutlookController` 実装（Graph Webhook 受信・validationToken 応答・clientState 検証・CSRF 除外）
- [x] `OutlookSyncJob` 実装（面接キーワード判定 → Google カレンダー転写 → Alexa ジョブスケジュール）
- [x] `routes.rb` に `POST /webhooks/outlook` 追加
- [x] Microsoft Graph Webhook サブスクリプション更新ジョブ（`MsWebhookRenewalJob`）

## Phase 5: 機能③ 面接前 Alexa アナウンス

- [x] `VoicemonkeyService` 実装（VoiceMonkey API クライアント）
- [x] `AlexaAnnounceJob` 実装（全 Echo デバイスへアナウンス POST）
- [x] Sidekiq の `perform_at` で15分前・5分前にスケジュール

## Phase 6: テスト・品質

- [x] Minitest セットアップ（test_helper.rb・WebMock・Mocha）
- [x] 各サービスクラスのテスト（5ファイル）
- [x] 各ジョブクラスのテスト（4ファイル）
- [x] コントローラーのテスト（4ファイル）
- [x] RuboCop セットアップ・全ファイル 0 offenses

## Phase 7: 運用整備

- [ ] Google Calendar Push 通知チャンネルの定期更新ジョブ
- [ ] Let's Encrypt 証明書の自動更新設定
- [ ] エラー通知の仕組み検討（Sidekiq リトライ・失敗時の LINE 通知等）
