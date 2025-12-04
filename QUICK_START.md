# Quick Start Guide (Helm + Traefik)

คู่มือเริ่มต้นอย่างรวดเร็วสำหรับการทดสอบระบบในวันพรุ่งนี้

## ขั้นตอนการติดตั้งแบบรวดเร็ว

### 1. เตรียม K3s Cluster

ตรวจสอบให้แน่ใจว่า K3s ของคุณทำงานอยู่และ Traefik ถูกเปิดใช้งาน:

```bash
kubectl get nodes
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik
```

### 2. ติดตั้ง Cert-Manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --version v1.13.2 --set installCRDs=true

# สร้าง ClusterIssuer (ต้องทำด้วยมือตามคู่มือ INSTALLATION.md)
# kubectl apply -f cluster-issuer.yaml
```

### 3. Clone Repository และตั้งค่า

```bash
git clone <your-repo-url>
cd k3s-automation-system

# คัดลอกและแก้ไข .env
cp .env.example .env
nano .env  # แก้ไข Domain (sunmart.online), Passwords, API Keys
```

### 4. ติดตั้งระบบด้วย Helm

```bash
# สร้าง ConfigMap และ Secrets
kubectl apply -f manifests/01-configmap.yaml
./scripts/create-secrets.sh

# ติดตั้งทุกอย่าง (Databases + Applications ผ่าน Helm)
./scripts/install-all.sh
```

### 5. ตรวจสอบสถานะ

```bash
# ดู Helm Releases
helm list -n automation-system

# ดู Pods
kubectl get pods -n automation-system

# ดู IngressRoutes
kubectl get ingressroute -n automation-system
```

## การเข้าถึง Applications

หลังจากทุกอย่างพร้อม:

- **Dify:** https://dify.sunmart.online
- **WordPress:** https://wordpress.sunmart.online
- **ActivePieces:** https://activepieces.sunmart.online
- **Paymenter:** https://billing.sunmart.online

## ขั้นตอนต่อไป

1. ตั้งค่า Dify และเชื่อมต่อกับ LINE OA (ดู [docs/CONFIGURATION.md](docs/CONFIGURATION.md))
2. ตั้งค่า Paymenter และสร้าง Products
3. ติดตั้ง Paymenter Webhook Extension (ดู [paymenter-webhook-extension/README.md](paymenter-webhook-extension/README.md))
4. สร้าง ActivePieces Flows

## หากพบปัญหา

```bash
# ดู logs ของ Pod ที่มีปัญหา
kubectl logs <pod-name> -n automation-system

# ดู logs ของ Helm Release
helm get manifest <release-name> -n automation-system | kubectl apply -f - --dry-run=client
```

## เอกสารเพิ่มเติม

- [คู่มือการติดตั้งฉบับละเอียด](docs/INSTALLATION.md)
- [คู่มือการตั้งค่า](docs/CONFIGURATION.md)
- [คู่มือ Paymenter Webhook](paymenter-webhook-extension/README.md)
