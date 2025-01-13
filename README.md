# シンプルなタスク管理アプリケーションのKubernetes化とCI/CD構築

## 1. アプリケーション概要

このアプリケーションは、シンプルなタスク管理システムを実装したマイクロサービスアーキテクチャのWebアプリケーションです。

主な機能：

- タスクの一覧表示
- タスクの追加
- タスクの削除

技術スタック：

- フロントエンド：Flask (Python)
- バックエンドAPI：FastAPI (Python)
- データベース：MySQL
- リバースプロキシ：Nginx
- コンテナオーケストレーション：Kubernetes
- CI/CD：GitHub Actions, Flux

## 2. システム構成図

### 2-1. シーケンス図

```mermaid
sequenceDiagram
    participant User as ユーザー（アプリ）
    participant Nginx as Nginx<br>プロキシサーバー
    participant Flask as Flask<br>フロントエンド
    participant FastAPI as FastAPI<br>バックエンドAPI
    participant MySQL as MySQL<br>データベース

    User->>Nginx: タスクアプリにアクセス
    Nginx->>Flask: フロントエンドへのリクエスト転送
    Flask->>User: タスクアプリのレスポンス表示

    User->>Nginx: APIリクエスト
    Nginx->>FastAPI: バックエンドAPIへのリクエスト転送
    FastAPI->>MySQL: データ取得要求
    MySQL-->>FastAPI: データ返却
    FastAPI-->>Nginx: APIレスポンス返却
    Nginx-->>User: APIレスポンス返却
```

### 2-2. K8Sリソース構成

```mermaid
flowchart TB
%% Proxy Subgraph
subgraph Proxy[Proxyサービス]
direction TB
P1[Ingress<br>/app2/] --> P2[Service<br>proxy-service:80]
P2 --> P3[Deployment<br>nginx:alpine]
end
%% Web Subgraph
subgraph Web[Webサービス]
direction TB
W2[Service<br>web-service:5000] --> W3[Deployment<br>simple-taskapp-flask-web]
end
%% API Subgraph
subgraph API[APIサービス]
direction TB
A2[Service<br>api-service:8000]--> A3[Deployment<br>simple-taskapp-fastapi]
end
%% Migrator Subgraph
subgraph Migrator[マイグレーター]
direction TB
M1[Job<br>db-migration-job]
end
%% DB Subgraph
subgraph DB[データベース]
direction TB
D1[Service<br>db-service:3306] --> D2[Deployment<br>mysql:8.0]
D2 --> D3[PersistentVolumeClaim<br>mysql-pvc]
end
%% サービス間の通信フロー
P3 --> |/app2/|W2
P3 --> |/app2/api/|A2
W3 --> |HTTP|A2
A3 --> |MySQL|D1
M1 --> |MySQL|D1
%% スタイル設定
classDef proxyStyle fill:#e1f3d8,color:#444444
classDef webStyle fill:#fff0b3,color:#444444
classDef apiStyle fill:#f0e6ff,color:#444444
classDef migratorStyle fill:#ffe6e6,color:#444444
classDef dbStyle fill:#e6f3ff,color:#444444
%% スタイルの適用
class P1,P2,P3 proxyStyle
class W1,W2,W3 webStyle
class A1,A2,A3 apiStyle
class M1 migratorStyle
class D1,D2,D3 dbStyle
```

## 3. Kubernetesリソースと各構成要素の対応

### 3.1 主要なKubernetesリソース

1. **Deployment**
    - アプリケーションのコンテナを管理
    - レプリカ数の制御
    - ローリングアップデートの実現
    
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: web-deployment
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: web
    
    ```
    
2. **Service**
    - Pod間の通信を可能にする
        - IPアドレスが自動的に付与
    - 安定したエンドポイントの提供
    
    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: web-service
    spec:
      selector:
        app: web
      ports:
        - protocol: TCP
          port: 5000
    
    ```
    
3. **ConfigMap**
    - Nginxの設定を外部化
    - 環境に応じた設定変更が容易
    
    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: nginx-config
    data:
      default.conf: |
        server {
          listen 80;
          # ...
        }
    
    ```
    
4. **Job**
    - データベースマイグレーション用
    - 一度だけ実行される処理の管理
    
    ```yaml
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: db-migration-job
    spec:
      template:
        spec:
          containers:
          - name: db-migration
    
    ```
    

### 3.2 Kubernetesクラスタ化のメリット

⇒この資料がわかりやすくまとまっている 
[kubernetes入門 - Speaker Deck](https://speakerdeck.com/cybozuinsideout/introduction-to-kubernetes-2024)

1. **スケーラビリティ**
    - レプリカ数の動的な調整が可能
    - 負荷に応じた自動スケーリング
2. **可用性の向上**
    - 複数Podによる冗長化
    - 自動的な障害検知と復旧
3. **デプロイメントの効率化**
    - ローリングアップデート
    - ゼロダウンタイムデプロイ
4. **構成管理の一元化**
    - マニフェストによる宣言的な管理
    - バージョン管理との連携

## 4. CI/CDパイプラインの構築

```mermaid
flowchart TB
subgraph CI[CI - GitHub Actions]
direction LR
A1[Checkout] --> A2[Build Images]
A2 --> A3[Push Images]
end
subgraph Resources[CRUD対象]
direction TB
B1[Git Repository]
B2[Container Registry]
B3[Git Repository]
B4[K8s Cluster]
end
subgraph CD[CD - Flux]
direction LR
C1[Check New Images] --> C2[Update Image Tag]
C3[Check Repository] --> C4[Sync to Cluster]
end
%% CI と Resources の関係
A1 --> B1
A3 --> B2
%% CD と Resources の関係
C1 --> B2
C2 --> B3
C3 --> B3
C4 --> B4
%% スタイル設定
classDef ciStyle fill:#e1f3d8,color:#444444
classDef resourceStyle fill:#fff0b3,color:#444444
classDef cdStyle fill:#f0e6ff,color:#444444
class A1,A2,A3 ciStyle
class B1,B2,B3,B4 resourceStyle
class C1,C2,C3,C4 cdStyle
```

### 4.1 GitHub Actions

- Gitのタグ付きでプッシュすると実行
- タグ名（v*）をイメージタグとしてDockerHubにプッシュ

### 4.2 Flux

- リポジトリを定期的に監視してタグの変更情報を取得
- 変更を検知したらリポジトリのK8S設定ファイル内のイメージタグを更新
- K8Sクラスターにもデプロイして同期

### 4.3 イメージ

GitHub Actionsでイメージのビルド＆プッシュ

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/032b8dcf-679b-4b7c-9b58-8e80ab145042/b48d6823-f4ca-40e3-9bb1-292ee6a907af/image.png)

↓　DockerHubにイメージをプッシュ

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/032b8dcf-679b-4b7c-9b58-8e80ab145042/7b0fa927-b471-44e3-85ee-8ff9d12f2033/image.png)

↓　FluxのImageControllerがタグの変更を検知

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/032b8dcf-679b-4b7c-9b58-8e80ab145042/64308cb5-0d07-4348-b660-678b713d041d/image.png)

↓　リモートリポジトリのK8S設定ファイルを自動更新

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/032b8dcf-679b-4b7c-9b58-8e80ab145042/b7e42d5a-b84a-4028-83a1-198162a9b700/image.png)

↓　K8Sクラスター（アプリ）にも自動デプロイして同期

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/032b8dcf-679b-4b7c-9b58-8e80ab145042/9dcb2bba-41fd-45ce-8985-24c6ec7abe15/image.png)

## 5. AKSへのデプロイ方法

- xxx