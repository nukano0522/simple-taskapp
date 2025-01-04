# AKSクラスタ作成
az aks create --resource-group rg-nukano0522-01 --name nk-aks --enable-managed-identity --network-plugin azure -a ingress-appgw --appgw-name nk-gateway --appgw-subnet-cidr "10.225.0.0/16" --node-count 1 --g
enerate-ssh-keys

# AKSクラスタの認証情報取得
az aks get-credentials --resource-group rg-nukano0522-01 --name nk-aks

# コンテキストの確認
kubectl config get-contexts

# コンテキストの切り替え
kubectl config use-context nk-aks
kubectl config use-context docker-desktop

# namespace作成
kubectl create namespace simple-taskapp