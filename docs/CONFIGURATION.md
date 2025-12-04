# คู่มือการตั้งค่า Application

หลังจากติดตั้งระบบบน K3s เรียบร้อยแล้ว คุณต้องทำการตั้งค่าเริ่มต้นสำหรับแต่ละ Application

## 1. การตั้งค่า Dify

1.  **เข้าสู่ระบบ:** ไปที่ `https://dify.yourdomain.com` และเข้าสู่ระบบด้วย Admin account ที่ตั้งค่าไว้ใน `.env`
2.  **สร้าง Application:**
    - คลิก "Create App"
    - เลือก "Chat App"
    - ตั้งชื่อ App (เช่น "LINE OA Support")
3.  **เชื่อมต่อ Knowledge Base (WordPress):**
    - ไปที่ "Knowledge"
    - คลิก "Create Knowledge"
    - เลือก "Sync from website"
    - ใส่ URL ของ WordPress ของคุณ (`https://wordpress.yourdomain.com`)
    - ตั้งค่าการ Sync ตามต้องการ
4.  **เชื่อมต่อ LLM (Google Gemini):**
    - ไปที่ "Settings" > "Model Provider"
    - เลือก "Google Gemini"
    - ใส่ Gemini API Key ของคุณ
5.  **เชื่อมต่อ LINE OA:**
    - ไปที่ "App" > "Integrations"
    - ค้นหา "LINE Bot" และทำการเชื่อมต่อ
    - นำ Webhook URL ที่ Dify สร้างให้ไปใส่ใน LINE Developers Console
    - นำ Channel Secret และ Channel Access Token จาก LINE Developers Console มาใส่ใน Dify

## 2. การตั้งค่า Paymenter

1.  **เข้าสู่ระบบ:** ไปที่ `https://billing.yourdomain.com` และเข้าสู่ระบบด้วย Admin account ที่ตั้งค่าไว้ใน `.env`
2.  **ตั้งค่าทั่วไป:**
    - ไปที่ "Settings" > "General"
    - ตั้งค่าสกุลเงิน, รูปแบบวันที่, และข้อมูลบริษัท
3.  **ตั้งค่า Payment Gateways:**
    - ไปที่ "Settings" > "Payment Gateways"
    - เลือก Gateway ที่คุณต้องการ (เช่น Stripe, PayPal, หรือ Manual/Bank Transfer)
    - ใส่ API Keys และตั้งค่าตามต้องการ
4.  **สร้าง Products:**
    - ไปที่ "Products"
    - คลิก "Create Product"
    - ตั้งชื่อ, ราคา, และรายละเอียดของสินค้า/บริการ

## 3. การตั้งค่า ActivePieces

1.  **เข้าสู่ระบบ:** ไปที่ `https://activepieces.yourdomain.com` และสร้าง Account ใหม่
2.  **สร้าง Flow สำหรับรับ Webhook จาก Paymenter:**
    - คลิก "New Flow"
    - **Trigger:** เลือก "Webhook"
    - คัดลอก Webhook URL ที่ ActivePieces สร้างให้
    - **สำคัญ:** นำ URL นี้ไปใส่ในไฟล์ `.env` ของคุณในส่วน `ACTIVEPIECES_WEBHOOK_URL` และทำการ `helm upgrade` Paymenter เพื่ออัปเดตค่า
    - **Action:** เพิ่ม Action เพื่อทดสอบ เช่น "Send Email" หรือ "Send Telegram Message"
3.  **สร้าง Flow สำหรับ Admin Approval:**
    - **Trigger:** Webhook (จาก Flow ก่อนหน้า หรือ Flow ใหม่)
    - **Action:** ใช้ "Telegram Bot" Connector
        - เลือก Action "Send Message"
        - ส่งรายละเอียด Order และปุ่ม "Approve" / "Reject" ไปยัง Admin Chat ID
    - **Action:** ใช้ "Wait for Webhook" หรือ "Wait for Condition" เพื่อรอการตอบกลับจาก Admin
4.  **สร้าง Flow สำหรับ Provisioning (Cloudflare):**
    - **Trigger:** Webhook (หลังจาก Admin Approve)
    - **Action:** ใช้ "Cloudflare" Connector
        - เลือก Action ที่ต้องการ เช่น "Create DNS Record"
        - ใส่ Cloudflare API Token และ Zone ID
        - ตั้งค่า Record ตามข้อมูลจาก Order

## 4. การตั้งค่า WordPress

1.  **เข้าสู่ระบบ:** ไปที่ `https://wordpress.yourdomain.com/wp-admin` และเข้าสู่ระบบด้วย Admin account ที่ตั้งค่าไว้ใน `.env`
2.  **ตั้งค่า Permalinks:**
    - ไปที่ "Settings" > "Permalinks"
    - เลือก "Post name" เพื่อให้ URL อ่านง่าย
3.  **สร้างบทความเริ่มต้น:**
    - สร้างบทความหรือหน้าเว็บที่เป็น Knowledge Base เริ่มต้นเพื่อให้ Dify สามารถดึงข้อมูลไปใช้ได้

เมื่อตั้งค่าทั้งหมดนี้เรียบร้อยแล้ว ระบบของคุณก็พร้อมที่จะทำงานแบบอัตโนมัติ!
