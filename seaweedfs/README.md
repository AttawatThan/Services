# SeaweedFS Community POC

Single-node POC โดยใช้ `weed mini` บน SeaweedFS 4.42 ซึ่งรัน Master, Volume, Filer, S3, WebDAV และ Admin UI ใน container เดียว ข้อมูลจะถูกเก็บถาวรไว้ที่ `./seaweed-data` บนเครื่อง host

> ชุดนี้เหมาะกับ development, testing, learning และ POC เท่านั้น ค่า credential เริ่มต้นเป็นค่าตัวอย่างและ UI ต่าง ๆ ไม่มีการป้องกันสำหรับการเปิดออกสู่ network ภายนอก

## เริ่มใช้งาน

```bash
docker compose up -d
docker compose ps
```

เมื่อพร้อมใช้งาน `docker compose ps` จะแสดงสถานะเป็น `healthy`

ค่าเริ่มต้นคือ:

- Access key: `admin`
- Secret key: `secret`
- Bucket: `poc`

ถ้าต้องการเปลี่ยนค่า ให้คัดลอก `.env.example` เป็น `.env` แล้วแก้ค่าก่อนสตาร์ต

## Endpoints

| Service | URL |
| --- | --- |
| S3 API | http://localhost:8333 |
| Master UI | http://localhost:9333 |
| Filer UI | http://localhost:8888 |
| WebDAV | http://localhost:7333 |
| Volume server | http://localhost:9340 |
| Admin UI | http://localhost:23646 |

## ทดสอบอัตโนมัติ

สคริปต์ด้านล่างใช้ AWS CLI ผ่าน Docker จึงไม่ต้องติดตั้ง `aws` บนเครื่อง โดยจะตรวจ bucket, upload, list, download, เทียบเนื้อหา และลบ object ทดสอบให้เอง

```bash
./scripts/smoke-test.sh
```

## ทดสอบด้วย AWS CLI บนเครื่อง

```bash
export AWS_ACCESS_KEY_ID=admin
export AWS_SECRET_ACCESS_KEY=secret
export AWS_DEFAULT_REGION=us-east-1

aws --endpoint-url http://localhost:8333 s3 ls
printf 'hello seaweedfs\n' > hello.txt
aws --endpoint-url http://localhost:8333 s3 cp hello.txt s3://poc/hello.txt
aws --endpoint-url http://localhost:8333 s3 ls s3://poc/
aws --endpoint-url http://localhost:8333 s3 cp s3://poc/hello.txt downloaded.txt
```

## คำสั่งดูแลพื้นฐาน

```bash
# ดู log
docker compose logs -f seaweedfs

# หยุด service แต่เก็บข้อมูลไว้
docker compose down

# สตาร์ตใหม่โดยใช้ข้อมูลเดิม
docker compose up -d
```

หากต้องการล้างข้อมูล POC ให้รัน `docker compose down` ก่อน แล้วจึงลบโฟลเดอร์ `seaweed-data` ด้วยตนเอง

เอกสารอ้างอิง: [SeaweedFS Quick Start](https://github.com/seaweedfs/seaweedfs#quick-start), [SeaweedFS 4.42 release](https://github.com/seaweedfs/seaweedfs/releases/tag/4.42)
