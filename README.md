# Dify on AWS App Runner

Dify 1.13.0 を AWS App Runner にデプロイする Terraform + Docker 構成一式です。

## アーキテクチャ

```
┌─────────────────────────────────────────────────┐
│  AWS App Runner                                 │
│  ┌───────────────────────────────────────────┐  │
│  │  All-in-One コンテナ (supervisord)        │  │
│  │  ├── nginx (リバースプロキシ :5001)       │  │
│  │  ├── Dify API (Flask :5100)               │  │
│  │  ├── Dify Worker (Celery)                 │  │
│  │  ├── Dify Web (Next.js :3000)             │  │
│  │  └── Plugin Daemon (:5002)                │  │
│  └───────────────────────────────────────────┘  │
│           │          │          │                │
│      ┌────┘     ┌────┘     ┌────┘               │
│      ▼          ▼          ▼                     │
│   RDS        ElastiCache   S3                    │
│  (PostgreSQL)  (Redis)   (ファイルストレージ)     │
└─────────────────────────────────────────────────┘
```

## 前提条件

- AWS CLI 設定済み
- Terraform >= 1.5
- Docker
- AWS アカウントに以下の権限:
  - VPC, RDS, ElastiCache, S3, ECR, App Runner, IAM

## ディレクトリ構成

```
├── docker/
│   ├── Dockerfile              # All-in-One イメージ
│   ├── nginx.conf              # リバースプロキシ設定
│   ├── supervisord.conf        # プロセス管理
│   ├── start.sh                # エントリポイント
│   ├── init-db.sh              # DB初期化 (dify_plugin DB作成)
│   └── run-plugin-daemon.sh    # Plugin Daemon ラッパー
├── terraform/
│   ├── modules/
│   │   ├── vpc/                # VPC + サブネット + NAT Gateway
│   │   ├── rds/                # PostgreSQL 16 (pgvector)
│   │   ├── elasticache/        # Redis 7.1
│   │   ├── s3/                 # ファイルストレージ
│   │   ├── ecr/                # コンテナレジストリ
│   │   └── apprunner/          # App Runner サービス
│   ├── development/            # 開発環境
│   └── production/             # 本番環境
```

## セットアップ手順

### 1. リポジトリをクローン

```bash
git clone https://github.com/xim2jp/dify-on-aws-apprunner.git
cd dify-on-aws-apprunner
```

### 2. Terraform 変数を設定

```bash
cd terraform/development
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` を編集して、`aws_account_id` をあなたの AWS アカウント ID に変更してください。

### 3. インフラを構築

```bash
terraform init
terraform plan
terraform apply
```

以下のリソースが作成されます:
- **VPC**: パブリック/プライベートサブネット、NAT Gateway
- **RDS**: PostgreSQL 16 (db.t4g.micro)、自動パスワード生成
- **ElastiCache**: Redis 7.1 (cache.t4g.micro)
- **S3**: ファイルストレージ用バケット
- **ECR**: Docker イメージリポジトリ
- **App Runner**: Dify サービス

### 4. Docker イメージをビルド・プッシュ

```bash
# ECR リポジトリ URL を取得
ECR_URL=$(terraform output -raw ecr_repository_url)
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "ap-northeast-1")

# ECR にログイン
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_URL

# ビルド & プッシュ
cd ../../docker
docker build --platform linux/amd64 -t dify-all-in-one .
docker tag dify-all-in-one:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

### 5. App Runner にデプロイ

ECR にイメージをプッシュ後、App Runner コンソールから手動デプロイを実行するか、`auto_deployments_enabled = true` に変更してください。

## 環境変数一覧

Terraform が App Runner に自動設定する環境変数です（`terraform/modules/apprunner/main.tf` で定義）。

| カテゴリ | 変数名 | 説明 | 設定元 |
|---------|--------|------|--------|
| **Core** | `SECRET_KEY` | 暗号化キー | 自動生成 (random_password) |
| **DB** | `DB_HOST` | RDS エンドポイント | Terraform output |
| | `DB_PORT` | PostgreSQL ポート | `5432` |
| | `DB_DATABASE` | データベース名 | `dify` |
| | `DB_USERNAME` | DB ユーザー名 | Terraform output |
| | `DB_PASSWORD` | DB パスワード | 自動生成 |
| **Redis** | `REDIS_HOST` | ElastiCache エンドポイント | Terraform output |
| | `REDIS_PORT` | Redis ポート | `6379` |
| | `CELERY_BROKER_URL` | Celery ブローカー | `redis://{REDIS_HOST}:6379/1` |
| **S3** | `STORAGE_TYPE` | ストレージ種別 | `s3` |
| | `S3_BUCKET_NAME` | バケット名 | Terraform output |
| | `S3_REGION` | バケットリージョン | 変数値 |
| **Vector DB** | `VECTOR_STORE` | ベクトルDB種別 | `pgvector` |
| | `PGVECTOR_HOST` | pgvector ホスト | RDS と共用 |
| **Plugin** | `PLUGIN_API_URL` | Plugin Daemon URL | `http://127.0.0.1:5002` |
| | `MARKETPLACE_ENABLED` | マーケットプレイス | `true` |

> **注意**: `SECRET_KEY`, `DB_PASSWORD` 等のシークレットは Terraform が自動生成します。手動設定は不要です。

## All-in-One コンテナ構成

1つのコンテナ内で supervisord が以下の5プロセスを管理します:

| プロセス | ポート | 役割 |
|---------|--------|------|
| nginx | 5001 (外部公開) | リバースプロキシ |
| Dify API | 5100 | Flask API サーバー |
| Dify Worker | - | Celery ワーカー |
| Dify Web | 3000 | Next.js フロントエンド |
| Plugin Daemon | 5002 | プラグイン管理 |

### なぜ All-in-One？

App Runner は1サービス＝1コンテナ構成のため、API / Worker / Web / Plugin Daemon を1コンテナに統合しています。ECS を使えばサービス分割できますが、App Runner のシンプルさ（VPC コネクタ設定のみでデプロイ可能）を優先しました。

## コスト概算 (development 環境)

| リソース | スペック | 月額概算 |
|---------|---------|---------|
| App Runner | 1 vCPU / 2GB | ~$30 |
| RDS | db.t4g.micro | ~$15 |
| ElastiCache | cache.t4g.micro | ~$12 |
| NAT Gateway | 1台 | ~$35 |
| S3 + ECR | 従量課金 | ~$1-5 |
| **合計** | | **~$90-110/月** |

## 本番環境へのデプロイ

```bash
cd terraform/production
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を編集
terraform init
terraform plan
terraform apply
```

production 環境はデフォルトで:
- RDS Multi-AZ 有効
- ElastiCache 2ノード
- NAT Gateway 2台
- S3 バージョニング有効
- App Runner 最大4インスタンス

## ハマりポイント・Tips

- **Plugin Daemon**: Dify 1.13.0 では必須。`PLATFORM=local` と SSL 設定を忘れると起動しない
- **DB SSL**: RDS はデフォルトで SSL 必須。`DB_SSL_MODE=require` が必要
- **Next.js**: `HOSTNAME=0.0.0.0` を設定しないと localhost にバインドされ外部からアクセスできない
- **Celery**: デフォルトは RabbitMQ を探しに行くので `CELERY_BROKER_URL` で Redis を明示指定する

## ライセンス

MIT
