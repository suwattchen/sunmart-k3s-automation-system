#!/bin/bash

# Exit on error
set -e

# Load environment variables
source .env

# Create mysql-credentials secret
kubectl create secret generic mysql-credentials \
  --from-literal=MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
  --from-literal=MYSQL_PASSWORD=$MYSQL_PASSWORD \
  -n automation-system --dry-run=client -o yaml | kubectl apply -f -

# Create postgres-credentials secret
kubectl create secret generic postgres-credentials \
  --from-literal=POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  -n automation-system --dry-run=client -o yaml | kubectl apply -f -

# Create dify-secrets secret
kubectl create secret generic dify-secrets \
  --from-literal=SECRET_KEY=$DIFY_SECRET_KEY \
  --from-literal=API_KEY=$DIFY_API_KEY \
  --from-literal=DB_PASSWORD=$DIFY_DB_PASSWORD \
  --from-literal=REDIS_URL=$REDIS_URL \
  -n automation-system --dry-run=client -o yaml | kubectl apply -f -

# Create wordpress-secrets secret
kubectl create secret generic wordpress-secrets \
  --from-literal=WORDPRESS_DB_PASSWORD=$MYSQL_PASSWORD \
  --from-literal=WORDPRESS_ADMIN_PASSWORD=$WORDPRESS_ADMIN_PASSWORD \
  -n automation-system --dry-run=client -o yaml | kubectl apply -f -

# Create activepieces-secrets secret
kubectl create secret generic activepieces-secrets \
  --from-literal=SECRET=$ACTIVEPIECES_SECRET \
  --from-literal=JWT_SECRET=$ACTIVEPIECES_JWT_SECRET \
  --from-literal=ENCRYPTION_KEY=$ACTIVEPIECES_ENCRYPTION_KEY \
  --from-literal=DB_PASSWORD=$ACTIVEPIECES_DB_PASSWORD \
  -n automation-system --dry-run=client -o yaml | kubectl apply -f -

# Create paymenter-secrets secret
kubectl create secret generic paymenter-secrets \
  --from-literal=APP_KEY=$PAYMENTER_APP_KEY \
  --from-literal=DB_PASSWORD=$PAYMENTER_DB_PASSWORD \
  --from-literal=ADMIN_PASSWORD=$PAYMENTER_ADMIN_PASSWORD \
  -n automation-system --dry-run=client -o yaml | kubectl apply -f -

# Create redis-credentials secret
kubectl create secret generic redis-credentials \
  --from-literal=REDIS_PASSWORD=$REDIS_PASSWORD \
  --from-literal=REDIS_URL=$REDIS_URL \
  -n automation-system --dry-run=client -o yaml | kubectl apply -f -

# Create external-api-keys secret
kubectl create secret generic external-api-keys \
  --from-literal=GEMINI_API_KEY=$GEMINI_API_KEY \
  --from-literal=LINE_CHANNEL_SECRET=$LINE_CHANNEL_SECRET \
  --from-literal=LINE_CHANNEL_ACCESS_TOKEN=$LINE_CHANNEL_ACCESS_TOKEN \
  --from-literal=TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN \
  --from-literal=CLOUDFLARE_API_TOKEN=$CLOUDFLARE_API_TOKEN \
  --from-literal=WEBHOOK_SECRET=$WEBHOOK_SECRET \
  -n automation-system --dry-run=client -o yaml | kubectl apply -f -

echo "All secrets created successfully!"
