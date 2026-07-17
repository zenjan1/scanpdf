import pytest
import os
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_root():
    """测试根路径"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "app" in data
    assert data["app"] == "ScanPDF API"
    assert data["status"] == "running"


def test_health_check():
    """测试健康检查端点"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "ScanPDF API"


def test_api_root():
    """测试 API 根路径"""
    response = client.get("/api/v1")
    assert response.status_code == 200
    data = response.json()
    assert "endpoints" in data
    assert "documents" in data["endpoints"]
    assert "auth" in data["endpoints"]
    assert "ocr" in data["endpoints"]
    assert "scan" in data["endpoints"]


def test_get_documents_empty():
    """测试获取文档列表（空）"""
    response = client.get("/api/v1/documents")
    assert response.status_code == 200
    data = response.json()
    assert "data" in data
    assert isinstance(data["data"], list)


def test_create_document():
    """测试创建文档"""
    import tempfile
    import shutil
    from app.core.config.settings import settings

    # 使用临时目录，避免权限问题
    tmpdir = tempfile.mkdtemp()
    original_upload_dir = settings.UPLOAD_DIR
    settings.UPLOAD_DIR = tmpdir

    try:
        # 创建测试文件
        test_content = b"Test PDF content"
        files = {"file": ("test.pdf", test_content, "application/pdf")}
        data = {"title": "测试文档", "tags": "测试,文档"}

        response = client.post("/api/v1/documents", files=files, data=data)
        assert response.status_code == 200
        result = response.json()
        assert "data" in result
        assert result["data"]["title"] == "测试文档"
        assert "id" in result["data"]

        # 清理测试文件
        doc_id = result["data"]["id"]
        client.delete(f"/api/v1/documents/{doc_id}")
    finally:
        # 恢复原目录设置并清理
        settings.UPLOAD_DIR = original_upload_dir
        shutil.rmtree(tmpdir, ignore_errors=True)


def test_search_documents():
    """测试搜索文档"""
    response = client.get("/api/v1/documents/search/测试")
    assert response.status_code == 200
    data = response.json()
    assert "data" in data


def test_auth_register():
    """测试用户注册"""
    import uuid
    # 使用唯一邮箱避免冲突
    payload = {
        "email": f"test_{uuid.uuid4().hex[:8]}@example.com",
        "password": "test123456",
        "username": "testuser"
    }
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "data" in data
    assert "access_token" in data["data"]
    assert "user" in data["data"]


def test_auth_login():
    """测试用户登录"""
    payload = {
        "email": "test@example.com",
        "password": "test123456"
    }
    response = client.post("/api/v1/auth/login", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "data" in data
    assert "access_token" in data["data"]
    assert data["data"]["token_type"] == "bearer"


def test_ocr_extract():
    """测试 OCR 文字识别（需要测试图片）"""
    # 这个测试需要实际的图片文件
    # 在实际测试中，应该准备一个测试图片
    pass


def test_scan_detect_edges():
    """测试边缘检测"""
    # 这个测试需要实际的图片文件
    pass


def test_scan_enhance():
    """测试文档增强"""
    # 这个测试需要实际的图片文件
    pass


# 运行测试
if __name__ == "__main__":
    pytest.main([__file__, "-v"])
