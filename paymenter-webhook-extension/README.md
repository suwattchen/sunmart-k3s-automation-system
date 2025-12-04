# Paymenter Webhook Sender Extension

Extension สำหรับส่ง Webhook จาก Paymenter ไปยัง ActivePieces เมื่อมี Event สำคัญเกิดขึ้น

## Events ที่รองรับ

1. **invoice.paid** - เมื่อ Invoice ถูกชำระเงินแล้ว
2. **order.created** - เมื่อมีการสร้าง Order ใหม่
3. **order.updated** - เมื่อ Order มีการอัปเดต

## Webhook Payload

### invoice.paid

```json
{
  "event": "invoice.paid",
  "invoice_id": 123,
  "order_id": 456,
  "user_id": 789,
  "amount": 99.99,
  "currency": "USD",
  "status": "paid",
  "paid_at": "2024-12-04T10:30:00Z",
  "timestamp": 1733308200,
  "signature": "hmac_sha256_signature",
  "metadata": {
    "invoice_number": "INV-2024-001",
    "user_email": "customer@example.com"
  }
}
```

### order.created / order.updated

```json
{
  "event": "order.created",
  "order_id": 456,
  "user_id": 789,
  "product_id": 12,
  "status": "pending",
  "created_at": "2024-12-04T10:30:00Z",
  "timestamp": 1733308200,
  "signature": "hmac_sha256_signature",
  "metadata": {
    "product_name": "VPS Hosting",
    "user_email": "customer@example.com"
  }
}
```

## การติดตั้ง

### วิธีที่ 1: ติดตั้งใน Kubernetes (แนะนำ)

Extension นี้จะถูกติดตั้งอัตโนมัติผ่าน ConfigMap ใน Kubernetes Deployment

### วิธีที่ 2: ติดตั้งแบบ Manual

1. คัดลอกโฟลเดอร์ `paymenter-webhook-extension` ไปยัง Paymenter server

```bash
scp -r paymenter-webhook-extension user@server:/tmp/
```

2. เข้าไปยัง Paymenter directory

```bash
cd /var/www/paymenter
```

3. คัดลอก Extension ไปยัง `app/Extensions/Custom/WebhookSender`

```bash
mkdir -p app/Extensions/Custom/WebhookSender
cp -r /tmp/paymenter-webhook-extension/src/* app/Extensions/Custom/WebhookSender/
```

4. ติดตั้ง dependencies

```bash
composer require guzzlehttp/guzzle
```

5. ลงทะเบียน Service Provider ใน `config/app.php`

เพิ่มบรรทัดนี้ใน `providers` array:

```php
App\Extensions\Custom\WebhookSender\WebhookSenderServiceProvider::class,
```

6. เพิ่ม Environment Variables ใน `.env`

```bash
ACTIVEPIECES_WEBHOOK_URL=https://activepieces.yourdomain.com/api/v1/webhooks/paymenter
WEBHOOK_SECRET=your_secure_webhook_secret_here
```

7. Clear cache

```bash
php artisan config:clear
php artisan cache:clear
```

8. Restart services

```bash
sudo systemctl restart paymenter.service
```

## การตรวจสอบ

### ตรวจสอบ Logs

```bash
tail -f /var/www/paymenter/storage/logs/laravel.log
```

### ทดสอบ Webhook

สร้าง Order ทดสอบหรือชำระ Invoice แล้วตรวจสอบว่า Webhook ถูกส่งไปยัง ActivePieces

## การตั้งค่า ActivePieces

1. เข้าไปยัง ActivePieces Dashboard
2. สร้าง Flow ใหม่
3. เพิ่ม Trigger: **Webhook**
4. คัดลอก Webhook URL และนำไปใส่ใน `ACTIVEPIECES_WEBHOOK_URL`
5. สร้าง Actions ตามต้องการ เช่น:
   - ส่งข้อความไปยัง Telegram Bot
   - อัปเดตสถานะใน Database
   - เรียก Cloudflare API

## Security

Extension นี้ใช้ HMAC-SHA256 สำหรับ signature verification:

```php
$signature = hash_hmac('sha256', json_encode($payload), $webhookSecret);
```

ใน ActivePieces คุณสามารถตรวจสอบ signature ได้ด้วย:

```javascript
const crypto = require('crypto');
const signature = crypto
  .createHmac('sha256', webhookSecret)
  .update(JSON.stringify(payload))
  .digest('hex');

if (signature === receivedSignature) {
  // Webhook is valid
}
```

## Troubleshooting

### Webhook ไม่ถูกส่ง

1. ตรวจสอบว่า `ACTIVEPIECES_WEBHOOK_URL` ถูกตั้งค่าใน `.env`
2. ตรวจสอบ logs: `tail -f storage/logs/laravel.log`
3. ตรวจสอบว่า Service Provider ถูกลงทะเบียนแล้ว

### Webhook ถูกส่งแต่ ActivePieces ไม่ได้รับ

1. ตรวจสอบว่า URL ถูกต้อง
2. ตรวจสอบ Network/Firewall
3. ตรวจสอบ ActivePieces logs

### Signature Verification Failed

1. ตรวจสอบว่า `WEBHOOK_SECRET` ตรงกันทั้งสองฝั่ง
2. ตรวจสอบว่า payload ไม่ถูกแก้ไขระหว่างทาง

## License

MIT License
