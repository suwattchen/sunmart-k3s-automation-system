# คู่มือการตั้งค่า Cloudflared

## ขั้นตอนการตั้งค่า Cloudflared

### 1. สร้าง Cloudflare Tunnel

1. เข้าสู่ Cloudflare Dashboard
2. ไปที่ **Access** > **Tunnels**
3. คลิก **Create a tunnel**
4. ตั้งชื่อ Tunnel (เช่น `sunmart-k3s-tunnel`)
5. คลิก **Save tunnel**

### 2. ตั้งค่า Ingress Rules

ใน Tunnel Settings:

```yaml
# Ingress Rules
- hostname: dify.sunmart.online
  service: http://dify-web.automation-system.svc.cluster.local
- hostname: wordpress.sunmart.online
  service: http://wordpress.automation-system.svc.cluster.local
- hostname: activepieces.sunmart.online
  service: http://activepieces.automation-system.svc.cluster.local
- hostname: billing.sunmart.online
  service: http://paymenter.automation-system.svc.cluster.local
- service: http_status:404
```

### 3. สร้าง Credentials

```bash
# ดาวน์โหลด Credentials File จาก Cloudflare Dashboard
# หรือใช้คำสั่ง:
cloudflared tunnel login
```

### 4. สร้าง Kubernetes Secret

```bash
kubectl create secret generic cloudflare-credentials \
  --from-file=credentials.json=/path/to/your/credentials.json \
  -n automation-system
```

### 5. ตั้งค่าใน .env

```bash
# Cloudflare Tunnel
CLOUDFLARE_TUNNEL_ID=your_tunnel_id_here
CLOUDFLARE_TUNNEL_TOKEN=your_tunnel_token_here
```

### 6. ติดตั้ง

```bash
# ติดตั้งพร้อมกับระบบอื่นๆ
./scripts/install-all.sh
```

## ข้อดีของการใช้ Cloudflared

1. **ความปลอดภัย**: ไม่ต้อง expose port โดยตรง
2. **Performance**: ใช้ Cloudflare Network
3. **Zero Trust**: สามารถตั้งค่าการเข้าถึงด้วย Cloudflare Access
4. **DDoS Protection**: ได้รับการป้องกันจาก Cloudflare
5. **Global Load Balancing**: กระจาย traffic ไปยังหลาย location

## การตรวจสอบ

```bash
# ตรวจสอบสถานะ Tunnel
kubectl get pods -n automation-system -l app=cloudflared

# ตรวจสอบ logs
kubectl logs -n automation-system -l app=cloudflared
```