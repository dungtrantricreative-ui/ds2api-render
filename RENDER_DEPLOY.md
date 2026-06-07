# DS2API - Trien khai tren Render.com

> Huong dan chi tiet de deploy DS2API len Render.com mien phi

## Tinh nang da co san

- **Tool Call (Function Calling)**: Da ho tro chuyen doi giua dinh dang XML/DSML cua DeepSeek sang chuan OpenAI `tool_calls`. Khong can chinh sua gi them.
- **Chat API**: Tuong thich 100% voi thu vien OpenAI Python/JS.
- **WebUI Admin**: Quan ly account va cau hinh tai `/admin`.

---

## Buoc 1: Chuan bi Repository tren GitHub

### Cach 1: Dung GitHub Web UI (Khong can biet code)

1. **Fork repo goc**:
   - Truy cap: https://github.com/CJackHwang/ds2api
   - Click nut **"Fork"** o goc phai tren
   - Chon tai khoan GitHub cua ban
   - Doi vai giay de hoan tat fork

2. **Cap nhat Dockerfile** (quan trong):
   - Trong repo vua fork, tim file `Dockerfile`
   - Click vao file, roi click **"Edit"** (icon but)
   - Doi ten file thanh `Dockerfile` (ghi de len file cu)
   - Commit changes voi message: `Optimize for Render.com`

### Cach 2: Dung Git CLI (Neu ban quen dung terminal)

```bash
# Clone repo da duoc chuan bi
git clone <your-fork-url>
cd ds2api

# Da co Dockerfile, copy thanh Dockerfile
cp Dockerfile Dockerfile

# Commit va push
git add -A
git commit -m "Optimize for Render.com deployment"
git push origin main
```

---

## Buoc 2: Tao Web Service tren Render.com

### 2.1 Dang ky / Dang nhap

1. Truy cap: https://dashboard.render.com
2. Dang nhap bang **"Connect GitHub"** (khuyen nghi)
3. Cap quyen cho Render truy cap repo cua ban

### 2.2 Tao Blueprint tu render.yaml

**Cach nhanh nhat** (Khuyen dung):

1. Trong Dashboard, click **"New +"** > Chon **"Blueprint"**
2. Chon repo `ds2api` tu GitHub
3. Render se tu dong doc file `render.yaml` va cau hinh service
4. Click **"Apply"** de xac nhan

**Cach thu cong** (Neu Blueprint khong hoat dong):

1. Trong Dashboard, click **"New +"** > Chon **"Web Service"**
2. Chon repo `ds2api` tu GitHub
3. Cau hinh nhu sau:
   - **Name**: `ds2api` (hoac ten ban muon)
   - **Region**: Singapore (gan VN nhat) hoac Oregon
   - **Branch**: `main`
   - **Runtime**: `Docker`
   - **Dockerfile Path**: `./Dockerfile`
   - **Plan**: `Free`
4. Click **"Create Web Service"**

---

## Buoc 3: Cau hinh Bien Moi Truong (Environment Variables)

**Day la buoc QUAN TRONG NHAT de bao mat thong tin dang nhap.**

Trong trang cau hinh service cua ban, tim muc **"Environment"** va them cac bien sau:

### Bat buoc (Chon 1 trong cac cach):

**Cach A: Dung Email + Password DeepSeek**

| Key | Value | Ghi chu |
|-----|-------|---------|
| `DS_EMAIL` | `your-email@example.com` | Email dang nhap DeepSeek |
| `DS_PASSWORD` | `your-password` | Mat khau DeepSeek |
| `API_KEY` | `sk-your-custom-key-123` | API key ban tu dat, dung de goi API |

**Cach B: Dung Token DeepSeek (Neu co)**

| Key | Value | Ghi chu |
|-----|-------|---------|
| `DS_TOKEN` | `your-deepseek-token` | Token tu DeepSeek Web |
| `API_KEY` | `sk-your-custom-key-123` | API key ban tu dat |

**Cach C: Nhieu account (Tu chon)**

| Key | Value | Ghi chu |
|-----|-------|---------|
| `DS_EMAIL` | `account1@example.com` | Account chinh |
| `DS_PASSWORD` | `pass1` | |
| `DS_EMAIL_2` | `account2@example.com` | Account phu (tuy chon) |
| `DS_PASSWORD_2` | `pass2` | |
| `API_KEY` | `sk-your-custom-key-123` | API key tu dat |

### Tuy chon them:

| Key | Value | Mac dinh |
|-----|-------|----------|
| `DS2API_ADMIN_KEY` | `admin-secret-key` | Tu sinh |
| `MODEL_ALIASES` | `{"gpt-4o":"deepseek-v4-flash"}` | Da co san |
| `LOG_LEVEL` | `INFO` | INFO |

> **Luu y bao mat**: Cac bien co `sync: false` trong `render.yaml` se duoc danh dau la **sensitive** - Render se che gia tri khi hien thi.

---

## Buoc 4: Deploy va Kiem tra

1. Sau khi them bien moi truong, Render se **tu dong build va deploy**
2. Doi khoang **3-5 phut** de build hoan tat (Go + WebUI build kha lau)
3. Khi thay trang thai **"Live"** mau xanh la -> Deploy thanh cong!

### Kiem tra hoat dong:

```bash
# Lay URL cua ban tu Dashboard (vi du: https://ds2api-xxx.onrender.com)
# Test health check:
curl https://ds2api-xxx.onrender.com/healthz

# Test lay danh sach models:
curl https://ds2api-xxx.onrender.com/v1/models \
  -H "Authorization: Bearer sk-your-custom-key-123"

# Test chat completion:
curl https://ds2api-xxx.onrender.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-your-custom-key-123" \
  -d '{
    "model": "gpt-4o",
    "messages": [{"role": "user", "content": "Hello!"}],
    "stream": true
  }'
```

### Truy cap Admin Panel:

- Mo trinh duyet: `https://ds2api-xxx.onrender.com/admin`
- Dang nhap voi `DS2API_ADMIN_KEY` ban da dat

---

## Buoc 5: Su dung trong code (Python OpenAI)

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-your-custom-key-123",      # API_KEY ban da dat o tren
    base_url="https://ds2api-xxx.onrender.com/v1"  # URL tu Render Dashboard
)

# Chat thong thuong
response = client.chat.completions.create(
    model="gpt-4o",  # Se duoc alias sang deepseek-v4-flash
    messages=[{"role": "user", "content": "Xin chao!"}],
    stream=True
)
for chunk in response:
    print(chunk.choices[0].delta.content or "", end="")

# Tool Call (Function Calling) - Da ho tro san!
response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "Thoi tiet Ha Noi hom nay?"}],
    tools=[{
        "type": "function",
        "function": {
            "name": "get_weather",
            "parameters": {"type": "object", "properties": {"city": {"type": "string"}}}
        }
    }],
    stream=True
)
```

---

## Luu y quan trong

1. **Free tier limitations**:
   - Instance se **sleep sau 15 phut khong co request**
   - Lan request dau tien sau khi sleep se mat **30-60 giay** de wake up
   - Gioi han **750 gio/thang** runtime

2. **Bao mat**:
   - Khong bao gio commit `config.json` co that vao Git
   - Luon dung Environment Variables cho mat khau/token
   - API key ban tu dat (`API_KEY`) la key de xac thuc client goi den API

3. **Debug**:
   - Xem logs trong Render Dashboard > Logs
   - Neu build loi, kiem tra Dockerfile da duoc copy thanh Dockerfile chua

4. **Custom domain** (tuy chon):
   - Trong Render Dashboard > Settings > Custom Domains
   - Them domain va cau hinh DNS theo huong dan

---

## Ho tro

- **GitHub Issues**: https://github.com/CJackHwang/ds2api/issues
- **API Docs**: Xem file `API.md` trong repo
- **Tool Call Docs**: Xem phan "Tool Call" trong `README.MD`
