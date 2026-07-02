# ScanPDF API 文档

## API 概览

- **Base URL**: `https://jp.zenjan.store/api/v1`
- **协议**: HTTPS
- **数据格式**: JSON
- **认证**: Bearer Token

## 认证

### 用户注册

**POST** `/auth/register`

**请求体**:
```json
{
  "email": "user@example.com",
  "password": "password123",
  "username": "张三"
}
```

**响应**:
```json
{
  "data": {
    "user_id": "uuid-string",
    "email": "user@example.com"
  },
  "message": "注册成功"
}
```

### 用户登录

**POST** `/auth/login`

**请求体**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**响应**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "user_id": "uuid-string"
}
```

### 刷新令牌

**POST** `/auth/refresh`

**Headers**:
```
Authorization: Bearer <access_token>
```

## 文档管理

### 获取文档列表

**GET** `/documents`

**查询参数**:
- `skip`: 跳过数量（默认 0）
- `limit`: 返回数量（默认 100）

**Headers**:
```
Authorization: Bearer <access_token>
```

**响应**:
```json
{
  "data": [
    {
      "id": "doc-uuid",
      "title": "文档标题",
      "created_at": "2026-07-02T10:00:00Z",
      "updated_at": "2026-07-02T10:00:00Z",
      "page_count": 3,
      "tags": ["工作", "合同"],
      "file_path": "/data/uploads/doc-uuid.pdf",
      "thumbnail_path": "/data/uploads/doc-uuid_thumb.jpg",
      "is_favorite": false,
      "is_deleted": false,
      "file_size": 1024000,
      "mime_type": "application/pdf"
    }
  ]
}
```

### 获取单个文档

**GET** `/documents/{document_id}`

**Headers**:
```
Authorization: Bearer <access_token>
```

**响应**:
```json
{
  "data": {
    "id": "doc-uuid",
    "title": "文档标题",
    ...
  }
}
```

### 创建文档

**POST** `/documents`

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**表单数据**:
- `file`: 文件（PDF/JPG/PNG）
- `title`: 文档标题
- `tags`: 标签（逗号分隔，可选）

**响应**:
```json
{
  "data": {
    "id": "doc-uuid",
    "title": "新文档",
    ...
  },
  "message": "Document created successfully"
}
```

### 更新文档

**PUT** `/documents/{document_id}`

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**表单数据**:
- `title`: 新标题（可选）
- `tags`: 新标签（可选）
- `is_favorite`: 是否收藏（可选）

**响应**:
```json
{
  "data": {
    "id": "doc-uuid",
    "title": "更新后的标题",
    ...
  },
  "message": "Document updated successfully"
}
```

### 删除文档

**DELETE** `/documents/{document_id}`

**Headers**:
```
Authorization: Bearer <access_token>
```

**响应**:
```json
{
  "message": "Document deleted successfully"
}
```

### 搜索文档

**GET** `/documents/search/{query}`

**Headers**:
```
Authorization: Bearer <access_token>
```

**响应**:
```json
{
  "data": [
    {
      "id": "doc-uuid",
      "title": "匹配的文档",
      ...
    }
  ]
}
```

## OCR 文字识别

### 提取文字

**POST** `/ocr/extract`

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**表单数据**:
- `file`: 图片文件
- `language`: 语言（默认 `chi_sim+eng`，可选）
- `preprocess`: 是否预处理（默认 `true`，可选）

**响应**:
```json
{
  "data": {
    "success": true,
    "text": "识别出的文字内容...",
    "confidence": 0.95,
    "blocks": [
      {
        "text": "文字块",
        "confidence": 0.98,
        "bbox": {
          "x": 100,
          "y": 50,
          "width": 200,
          "height": 30
        }
      }
    ],
    "language": "chi_sim+eng"
  }
}
```

## 扫描处理

### 边缘检测

**POST** `/scan/detect-edges`

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**表单数据**:
- `file`: 图片文件

**响应**:
```json
{
  "data": {
    "corners": [
      [100, 50],
      [500, 50],
      [500, 700],
      [100, 700]
    ],
    "file_id": "temp-file-uuid"
  }
}
```

### 透视矫正

**POST** `/scan/correct-perspective`

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**表单数据**:
- `file`: 图片文件
- `corners`: 四个角点坐标（JSON 字符串）

**响应**: 返回矫正后的图片文件

### 文档增强

**POST** `/scan/enhance`

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**表单数据**:
- `file`: 图片文件

**响应**: 返回增强后的图片文件

## 错误处理

### 错误响应格式

```json
{
  "detail": "错误描述信息"
}
```

### 常见错误码

| 状态码 | 说明 |
|--------|------|
| 400 | 请求参数错误 |
| 401 | 未认证或令牌无效 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 413 | 文件过大 |
| 415 | 不支持的文件类型 |
| 500 | 服务器内部错误 |

## 速率限制

- 普通用户：100 次/分钟
- 认证用户：500 次/分钟
- OCR 接口：50 次/分钟

## 文件限制

- 最大文件大小：50MB
- 支持的文件类型：PDF, JPG, JPEG, PNG
- 图片分辨率：建议 300 DPI 以上

## 示例代码

### Python

```python
import requests

# 登录获取 token
response = requests.post(
    'https://jp.zenjan.store/api/v1/auth/login',
    json={'email': 'user@example.com', 'password': 'password123'}
)
token = response.json()['access_token']

headers = {'Authorization': f'Bearer {token}'}

# 上传文档
with open('document.pdf', 'rb') as f:
    files = {'file': f}
    data = {'title': '我的文档', 'tags': '工作,报告'}
    response = requests.post(
        'https://jp.zenjan.store/api/v1/documents',
        files=files,
        data=data,
        headers=headers
    )
```

### JavaScript (Fetch)

```javascript
// 登录
const loginResponse = await fetch('https://jp.zenjan.store/api/v1/auth/login', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    email: 'user@example.com',
    password: 'password123'
  })
});
const {access_token} = await loginResponse.json();

// 获取文档列表
const docs = await fetch('https://jp.zenjan.store/api/v1/documents', {
  headers: {'Authorization': `Bearer ${access_token}`}
});
const data = await docs.json();
```

## 在线文档

- **Swagger UI**: https://jp.zenjan.store/api/v1/docs
- **ReDoc**: https://jp.zenjan.store/api/v1/redoc
