# CLAUDE.md

このファイルはClaude Codeがこのプロジェクト内で自動的に読み込む指示書です。

---

## プロジェクト概要

自宅家庭内の通知・自動化・IoT制御を行うRailsアプリ。
詳細な仕様は`docs/home-system-requirements.md`を参照。

---

## 設定管理ルール（最重要）

**必ず以下を守ること。違反しないこと。**

### `.env`に書くもの（秘密情報のみ）
- APIトークン・シークレット・クライアントID/Secret類
- `.gitignore`で除外済み・絶対にGitにコミットしない

### `config/settings.yml`に書くもの（設定値）
- 文言・デバイスID・グループID・キーワード・タイミング設定
- Gitで管理する

### 設定値の参照方法
```ruby
# 環境変数ではなく必ずSettingsから取得する
Settings[:alexa][:message_15]
Settings[:interview][:keywords]
Settings[:switchbot][:devices]
```

---

## コーディング規約

- Rubyは最新の記法を使う
- サービスクラスは`app/services/`に置く
- ジョブクラスは`app/jobs/`に置く
- 外部APIへのアクセスは必ずServiceクラスに閉じ込める
- コントローラーはジョブのエンキューのみ行い、ビジネスロジックを書かない
- マジックナンバーは使わず`Settings`から取得する
- テストコードは必ず書くこと。
---

## セキュリティルール

- WebhookコントローラーはCSRF検証を除外し、代わりに署名検証を実装する
- ダッシュボード系コントローラーは`before_action :require_login`を必須とする
- `Settings[:app][:allowed_email]`以外のメールアドレスでのログインを拒否する
- 秘密情報を絶対にログに出力しない

---

## インフラ制約

- OCI AMD Always Free（1コア・1GB）のためメモリを節約する
- Sidekiqの`concurrency`は3以下にする
- Pumaのワーカー数は1にする

---

## 禁止事項

- `.env`をGitにコミットしない
- 設定値を`.env`に書かない（`settings.yml`に書く）
- コントローラーにビジネスロジックを書かない
- DBを導入しない（Redisのみ使用）
- 秘密情報をコードにハードコードしない

---

## パブリックリポジトリ注意事項（最重要）

**このリポジトリはパブリック公開されている。以下を厳守すること。**

### コミット前チェック（必須）
コミット・プッシュ前に必ず以下を確認する:

1. **個人情報の混入チェック** — コード・コミットメッセージに以下が含まれていないこと:
   - 実際のメールアドレス（`@gmail.com`等）
   - 実際のIPアドレス
   - 実際のドメイン名（DuckDNS等）
   - デバイスのMAC/シリアル番号
   - APIトークン・シークレットの実値

2. **`.env`が絶対にステージングされていないこと** — `git status` で確認

3. **`settings.yml` に個人情報がないこと** — 全て`ENV.fetch`経由であること

### 新しいWebhookエンドポイントを追加する場合
- 必ず署名検証を実装する（`ActiveSupport::SecurityUtils.secure_compare`を使用）
- `skip_forgery_protection`する場合は代替の認証を必ず実装

### 新しいRedisキーにトークン/Cookieを保存する場合
- 必ず`ActiveSupport::MessageEncryptor`で暗号化する

### 新しい外部スクリプト（CDN）を追加する場合
- バージョンを固定する（`@latest`禁止）

### NG例
```ruby
# NG: ハードコード
allowed_email = "user@gmail.com"
webhook_url = "https://my-domain.duckdns.org"
device_id = "AB12CD34EF56"

# OK: 環境変数経由
allowed_email = ENV.fetch('ALLOWED_EMAIL')
webhook_url = ENV.fetch('WEBHOOK_URL')
```

## テスト・Lint 実行方法

Redisが必要なため Docker 経由で実行する。

```bash
# Redis起動
docker compose up -d redis

# テスト実行
docker run --rm -v "$(pwd)":/app -w /app --network home_system_default \
  -e REDIS_URL=redis://redis:6379 ruby:3.3-slim bash -c \
  "apt-get update -qq && apt-get install -y --no-install-recommends build-essential libyaml-dev pkg-config > /dev/null 2>&1 && bundle install --quiet && bundle exec rails test"

# RuboCop実行
docker run --rm -v "$(pwd)":/app -w /app ruby:3.3-slim bash -c \
  "apt-get update -qq && apt-get install -y --no-install-recommends build-essential libyaml-dev pkg-config > /dev/null 2>&1 && bundle install --quiet && bundle exec rubocop"

# Redis停止
docker compose down
```

## 資産管理
- 必要に応じて、適宜コミットをすること。commit前にlintとテストを実行してQMSを担保すること。

## 進捗管理
docs/task.mdで作業状況を管理します。タスクが終わったら必ず更新すること。
