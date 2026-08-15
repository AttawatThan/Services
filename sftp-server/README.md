# SFTP Server

SFTP-only server สำหรับ Docker โดยต่อยอดแนวคิดจากบทความของ Hadi Khan แต่เพิ่มการ pin เวอร์ชัน, chroot, persistent storage, persistent host keys และไม่ฝังรหัสผ่านลงใน image

## เวอร์ชันที่กำหนดไว้

- SFTP image: `1.0.0`
- Alpine Linux: `3.22.5`
- Alpine image digest: `sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce`
- OpenSSH: `10.0_p1-r10`

เวอร์ชันของ image กำหนดไว้ใน `Dockerfile` และ tag ใน `compose.yaml` ส่วน dependency ถูก pin ไว้ใน `Dockerfile` ทั้ง tag และ digest ของ base image

## เริ่มใช้งาน

```sh
cd sftp-server
cp .env.example .env
```

แก้ `SFTP_PASSWORD` ใน `.env` ให้เป็นรหัสผ่านที่เดายาก แล้วรัน:

```sh
docker compose up --build -d --wait
```

เชื่อมต่อด้วย:

```sh
sftp -P 2222 sftpuser@localhost
```

หลัง login จะอยู่ที่ `/upload` และไฟล์จะถูกเก็บบน host ที่ `./data` ทันที

หยุด server:

```sh
docker compose down
```

คำสั่งนี้ไม่ลบไฟล์ใน `./data` และไม่ลบ host keys หากต้องการลบ named volume ของ host keys ด้วย ให้ใช้ `docker compose down -v`

## Configuration

| ตัวแปร | ค่าเริ่มต้น | รายละเอียด |
|---|---:|---|
| `SFTP_PORT` | `2222` | port บน host |
| `SFTP_USER` | `sftpuser` | ชื่อผู้ใช้ SFTP |
| `SFTP_PASSWORD` | ไม่มี | จำเป็นต้องกำหนดใน `.env` |

สำหรับ Docker secret ให้รัน container โดยตั้ง `SFTP_PASSWORD_FILE` เป็น path ของ secret แทน `SFTP_PASSWORD` ได้

## ทดสอบ

```sh
./tests/smoke-test.sh
```

สคริปต์จะ build image, ตรวจ health check, login และ upload ผ่าน SFTP protocol จริง, ตรวจ configuration ของ `sshd` และ cleanup container/volume ที่ใช้ทดสอบให้ ต้องมีคำสั่ง `expect` บนเครื่องที่รัน test

## Security notes

- ผู้ใช้ถูกบังคับให้ใช้ `internal-sftp` เท่านั้น ไม่มี shell, port forwarding หรือ tunnel
- ผู้ใช้ถูก chroot ไว้ใน `/home/<user>` และเขียนได้เฉพาะ `/upload`
- host keys เก็บใน named volume เพื่อไม่เปลี่ยนทุกครั้งที่ recreate container
- `SFTP_PASSWORD` ใช้สำหรับ bootstrap ตอนเริ่ม container; production ควรใช้ secret manager หรือ `SFTP_PASSWORD_FILE`
