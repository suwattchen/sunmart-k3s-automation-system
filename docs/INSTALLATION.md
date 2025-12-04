# คู่มือการติดตั้งระบบอัตโนมัติบน K3s (ฉบับละเอียด: Helm + Traefik)

เอกสารนี้จะแนะนำขั้นตอนการติดตั้งระบบอัตโนมัติทั้งหมดบน K3s Cluster ของคุณ โดยใช้ **Helm Charts** สำหรับการ Deploy และ **Traefik** สำหรับ Ingress

## 1. ข้อกำหนดเบื้องต้น (Prerequisites)

ก่อนเริ่มต้น โปรดตรวจสอบให้แน่ใจว่าคุณมีสิ่งต่อไปนี้ครบถ้วน:

- **K3s Cluster:** ติดตั้ง K3s บน Server ของคุณ (แนะนำ Ubuntu 22.04) โดย **Traefik** และ **Local Path Provisioner** ควรถูกเปิดใช้งาน (เป็นค่า Default ของ K3s)
- **Domain Name:** **sunmart.online**
- **DNS Records:** สร้าง A Record สำหรับแต่ละ Subdomain ให้ชี้ไปยัง IP Address ของ K3s Master Node:
  - `dify.sunmart.online`
  - `wordpress.sunmart.online`
  - `activepieces.sunmart.online`
  - `billing.sunmart.online`
- **Helm:** ติดตั้ง Helm 3.x
- **Git:** สำหรับ Clone Repository
- **API Keys:** เตรียม API Keys และ Credentials ทั้งหมดที่จำเป็น (ดูใน `.env.example`)

## 2. การเตรียม K3s Cluster

### 2.1 ตรวจสอบ Traefik และ Local Path Provisioner

Traefik และ Local Path Provisioner ควรถูกติดตั้งมาพร้อมกับ K3s โดยอัตโนมัติ

```bash
# ตรวจสอบ Traefik
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik

# ตรวจสอบ StorageClass
kubectl get sc
# ควรเห็น 'local-path' เป็น StorageClass
```

### 2.2 ติดตั้ง Cert-Manager (สำหรับ TLS/SSL อัตโนมัติ)

Cert-Manager จะช่วยสร้างและต่ออายุ SSL Certificate จาก Let's Encrypt โดยอัตโนมัติ

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.2 \
  --set installCRDs=true
```

หลังจากติดตั้งแล้ว ให้สร้าง `ClusterIssuer` เพื่อให้ Cert-Manager สามารถออก Certificate ได้:

```yaml
# cluster-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@sunmart.online # <--- แก้ไขเป็นอีเมลของคุณ
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
      - http01:
          ingress:
            class: traefik # <--- ใช้ Traefik Ingress Class
```

```bash
# บันทึกไฟล์ cluster-issuer.yaml
kubectl apply -f cluster-issuer.yaml
```

## 3. การติดตั้งระบบอัตโนมัติด้วย Helm

### 3.1 Clone Repository

```bash
git clone <your-repo-url> # <--- แก้ไขเป็น URL ของ Repo คุณ
cd k3s-automation-system
```

### 3.2 ตั้งค่า Configuration

คัดลอกไฟล์ `.env.example` และแก้ไขค่าต่างๆ ให้ถูกต้อง

```bash
cp .env.example .env
nano .env # แก้ไขค่า Domain, Passwords, API Keys
```

### 3.3 สร้าง Kubernetes Secrets และ ConfigMap

```bash
# สร้าง ConfigMap สำหรับชื่อ DB/User
kubectl apply -f manifests/01-configmap.yaml

# สร้าง Secret ทั้งหมดจากไฟล์ .env
./scripts/create-secrets.sh
```

### 3.4 ติดตั้ง Databases

เรายังคงใช้ Manifests สำหรับ Databases เพื่อให้ง่ายต่อการอ้างอิงชื่อ Service ภายใน Cluster

```bash
kubectl apply -f manifests/02-mysql.yaml
kubectl apply -f manifests/03-postgres.yaml
kubectl apply -f manifests/dify/redis.yaml

# รอให้ Databases พร้อม
kubectl wait --for=condition=ready pod -l app=mysql -n automation-system --timeout=300s
kubectl wait --for=condition=ready pod -l app=postgres -n automation-system --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n automation-system --timeout=300s
```

### 3.5 ติดตั้ง Applications ด้วย Helm

ใช้ script `install-all.sh` เพื่อติดตั้งทุก Application โดยใช้ Helm Charts

```bash
./scripts/install-all.sh
```

## 4. การตรวจสอบหลังการติดตั้ง

### 4.1 ตรวจสอบสถานะ Helm Releases

```bash
helm list -n automation-system
```

### 4.2 ตรวจสอบสถานะ Pods

```bash
kubectl get pods -n automation-system -w
```

### 4.3 ตรวจสอบ Certificate และ IngressRoute

```bash
kubectl get certificate -n automation-system
kubectl get ingressroute -n automation-system
```

คุณควรจะเห็น Certificate ทั้งหมดมีสถานะ `Ready: True` และ IngressRoute ถูกสร้างขึ้น

### 4.4 เข้าถึง Application

เมื่อทุกอย่างพร้อมแล้ว คุณสามารถเข้าถึงแต่ละ Service ผ่าน URL ที่ตั้งค่าไว้:

- **Dify:** `https://dify.sunmart.online`
- **WordPress:** `https://wordpress.sunmart.online`
- **ActivePieces:** `https://activepieces.sunmart.online`
- **Paymenter:** `https://billing.sunmart.online`

## 5. ขั้นตอนต่อไป (Next Steps)

โปรดดูคู่มือการตั้งค่าเฉพาะทางในโฟลเดอร์ `docs/` สำหรับรายละเอียดเพิ่มเติม

- [คู่มือการตั้งค่า (Configuration)](CONFIGURATION.md)
- [คู่มือการพัฒนา Paymenter Webhook Extension](PAYMENTER_WEBHOOK.md)
- [คู่มือการเชื่อมต่อ LINE OA](LINE_OA_INTEGRATION.md)
- [คู่มือการตั้งค่า ActivePieces Flows](ACTIVEPIECES_FLOWS.md)
