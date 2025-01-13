```mermaid

flowchart TB
subgraph CI[CI - GitHub Actions]
direction LR
A1[Checkout] --> A2[Build Images]
A2 --> A3[Push Images]
end
subgraph Resources[CRUD対象]
direction TB
B1[Git Repository\n(Application)]
B2[Container Registry\n(DockerHub)]
B3[Git Repository\n(GitOps)]
B4[K8s Cluster\n(AKS/Local)]
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
classDef ciStyle fill:#e1f3d8
classDef resourceStyle fill:#fff0b3
classDef cdStyle fill:#f0e6ff
class A1,A2,A3 ciStyle
class B1,B2,B3,B4 resourceStyle
class C1,C2,C3,C4 cdStyle

```