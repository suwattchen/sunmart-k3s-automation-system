#!/bin/bash

# Exit on error
set -e

# Load environment variables
source .env

# Function to apply manifests
apply_manifests() {
    echo "Applying manifests in $1..."
    for file in $(find $1 -name "*.yaml" | sort); do
        echo "Applying $file..."
        envsubst < $file | kubectl apply -f -
    done
}

# Function to install Helm Chart
install_chart() {
    local chart_name=$1
    local release_name=$2
    local namespace="automation-system"
    local values_file="charts/$chart_name/values.yaml"

    echo "Installing Helm Chart: $chart_name (Release: $release_name)"
    helm upgrade --install $release_name charts/$chart_name \
        --namespace $namespace \
        --create-namespace \
        -f $values_file \
        --set ingress.host=$3 \
        --set persistence.storageClass=$STORAGE_CLASS
}

# 1. Create Namespace, ConfigMap, and Secrets
kubectl apply -f manifests/00-namespace.yaml
kubectl apply -f manifests/01-configmap.yaml
./scripts/create-secrets.sh

# 2. Install Databases (Still using Manifests for simplicity of single-instance DBs)
kubectl apply -f manifests/02-mysql.yaml
kubectl apply -f manifests/03-postgres.yaml
kubectl apply -f manifests/dify/redis.yaml

# Wait for databases to be ready
echo "Waiting for databases to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n automation-system --timeout=300s
kubectl wait --for=condition=ready pod -l app=postgres -n automation-system --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n automation-system --timeout=300s

# 3. Install Applications using Helm Charts
install_chart "wordpress" "wordpress" $WORDPRESS_DOMAIN
install_chart "paymenter" "paymenter" $PAYMENTER_DOMAIN
install_chart "dify" "dify" $DIFY_DOMAIN
install_chart "activepieces" "activepieces" $ACTIVEPIECES_DOMAIN

# 4. Apply IngressRoute (Placeholder - already included in Helm Charts)
# apply_manifests "manifests/ingress"

echo "Installation complete!"
echo "Waiting for all pods to be ready..."
kubectl get pods -n automation-system -w
