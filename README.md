# K3s Automation System

ระบบอัตโนมัติครบวงจรสำหรับการจัดการ Customer Support, Billing และ Provisioning บน Kubernetes (K3s)

## 📋 ภาพรวมของระบบ

ระบบนี้ประกอบด้วยองค์ประกอบหลักดังนี้:

- **Dify** - AI Support Platform สำหรับตอบคำถามลูกค้าอัตโนมัติผ่าน LINE OA
- **WordPress** - Knowledge Base สำหรับจัดเก็บข้อมูลความรู้
- **ActivePieces** - Automation Platform สำหรับเชื่อมโยงทุกระบบเข้าด้วยกัน
- **Paymenter** - Billing System สำหรับจัดการคำสั่งซื้อและการชำระเงิน
- **Integrations** - LINE OA, Google Gemini API, Telegram Bot, Cloudflare

## 🏗️ สถาปัตยกรรมระบบ

```
Internet
    ↓
Cloudflare Edge
    ↓
systemd cloudflared (192.168.1.129)
    ↓
Traefik (Ingress Controller)
    ↓
┌─────────────────────────────────────────────────────────┐
│              Sunmart Cloud K3s Cluster                  │
│                                                         │
│  ┌──────────┐    ┌───────────┐    ┌──────────────┐   │
│  │   Dify   │◄───┤ WordPress │    │ ActivePieces │   │
│  │(AI Chat) │    │(Knowledge)│◄───┤ (Automation) │   │
│  └────┬─────┘    └───────────┘    └──────┬───────┘   │
│       │                                   │           │
│       │          ┌───────────┐            │           │
│       └─────────►│ Paymenter │◄───────────┘           │
│                  │ (Billing) │                        │
│                  └─────┬─────┘                        │
└────────────────────────┼──────────────────────────────┘
                         │
                         ▼
              ┌──────────────────┐
              │  Telegram Bot    │
              │  (Admin Approval)│
              └──────────────────┘
```

**หมายเหตุ:** ใช้ systemd cloudflared ที่มีอยู่แล้ว (PID 1993) แทนการติดตั้งใน Kubernetes เพื่อความปลอดภัยและหลีกเลี่ยงปัญหาการชนกัน

## 📁 โครงสร้าง Repository

```
k3s-automation-system/
├── charts/                 # Helm Charts สำหรับ Deploy Application
│   ├── activepieces/
│   ├── dify/
│   ├── paymenter/
│   └── wordpress/
├── manifests/              # Kubernetes Manifests ฐานข้อมูลและ Secrets
│   ├── 00-namespace.yaml
│   ├── 01-configmap.yaml
│   ├── 01-secrets.yaml
│   ├── 02-mysql.yaml
│   ├── 03-postgres.yaml
│   └── dify/
├── scripts/                # Helper scripts
├── docs/                   # Documentation
├── paymenter-webhook-extension/  # Custom Paymenter extension
└── README.md
```

## 🚀 Quick Start

### ข้อกำหนดเบื้องต้น

- K3s Cluster (v1.27+) พร้อม **Traefik** และ **Local Path Provisioner** (มาพร้อม K3s)
- `kubectl` และ `helm` configured
- Domain name: **sunmart.online** และ DNS configuration
- API Keys: Google Gemini, LINE OA, Telegram Bot

### การติดตั้งแบบรวดเร็ว

```bash
# 1. Clone repository
git clone <your-repo-url>
cd k3s-automation-system

# 2. ตั้งค่า environment variables
cp .env.example .env
# แก้ไขไฟล์ .env ตามความต้องการ (Domain ถูกตั้งค่าเป็น sunmart.online แล้ว)

# 3. ติดตั้งทุก Service ด้วย Helm
./scripts/install-all.sh

# 4. ตรวจสอบสถานะ
helm list -n automation-system
kubectl get pods -n automation-system
```

## 📖 เอกสารเพิ่มเติม

- [คู่มือการติดตั้งแบบละเอียด (Helm + Traefik)](docs/INSTALLATION.md)
- [คู่มือการตั้งค่า](docs/CONFIGURATION.md)
- [คู่มือการพัฒนา Paymenter Webhook Extension](docs/PAYMENTER_WEBHOOK.md)
- [คู่มือการเชื่อมต่อ LINE OA](docs/LINE_OA_INTEGRATION.md)
- [คู่มือการตั้งค่า ActivePieces Flows](docs/ACTIVEPIECES_FLOWS.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## 🔑 จุดสำคัญในการติดตั้ง

### 1. Traefik IngressRoute

ระบบใช้ **Traefik** ที่มาพร้อมกับ K3s และใช้ **IngressRoute** ที่กำหนดไว้ใน Helm Charts เพื่อจัดการ Traffic และ TLS/SSL

### 2. Cert-Manager

คุณต้องติดตั้ง **Cert-Manager** และ **ClusterIssuer** เพื่อให้ Traefik สามารถออก Certificate สำหรับ Domain **sunmart.online** ได้โดยอัตโนมัติ

### 3. Paymenter Webhook Extension

Paymenter ไม่มี Webhook มาตรฐาน ดังนั้นต้องติดตั้ง Custom Extension ที่เราสร้างไว้:

```bash
# ดูคู่มือใน docs/PAYMENTER_WEBHOOK.md
```

## 🔐 ความปลอดภัย

- ใช้ Kubernetes Secrets สำหรับเก็บ API Keys และ Credentials
- ใช้ TLS/SSL สำหรับทุก Ingress Endpoints ผ่าน Cert-Manager
- อัปเดต Container Images เป็นประจำ

## 🤝 การมีส่วนร่วม

หากพบปัญหาหรือต้องการปรับปรุงระบบ สามารถ:
1. เปิด Issue
2. ส่ง Pull Request
3. ติดต่อทีมผ่าน Telegram

## 📝 License

MIT License - ดูรายละเอียดใน [LICENSE](LICENSE)

## 🙏 Acknowledgments

- [Dify](https://dify.ai/) - Open-source LLM app development platform
- [ActivePieces](https://www.activepieces.com/) - Open-source automation platform
- [Paymenter](https://paymenter.org/) - Open-source billing platform
- [WordPress](https://wordpress.org/) - Content management system
