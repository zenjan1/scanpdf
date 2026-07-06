#!/usr/bin/env python3
"""
ScanPDF API 自动化测试套件
测试所有 API 端点的功能
"""
import requests
import json
import sys
from datetime import datetime

BASE_URL = "https://jp.zenjan.store/api/v1"
TEST_EMAIL = "test@scanpdf.app"
TEST_PASSWORD = "Test123456!"
TEST_USERNAME = "TestUser"

class APITester:
    def __init__(self):
        self.base_url = BASE_URL
        self.token = None
        self.user_id = None
        self.test_doc_id = None
        self.passed = 0
        self.failed = 0
        self.results = []
    
    def log(self, test_name, passed, message=""):
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} {test_name}: {message}")
        self.results.append({
            "test": test_name,
            "passed": passed,
            "message": message,
            "timestamp": datetime.now().isoformat()
        })
        if passed:
            self.passed += 1
        else:
            self.failed += 1
    
    def test_health_check(self):
        """测试健康检查端点"""
        try:
            response = requests.get("https://jp.zenjan.store/health", timeout=10)
            if response.status_code == 200:
                data = response.json()
                self.log("健康检查", data.get("status") == "healthy", f"Status: {data.get('status')}")
            else:
                self.log("健康检查", False, f"HTTP {response.status_code}")
        except Exception as e:
            self.log("健康检查", False, str(e))

    def test_root_endpoint(self):
        """测试根端点"""
        try:
            response = requests.get("https://jp.zenjan.store/", timeout=10)
            if response.status_code == 200:
                self.log("根端点", True, "主页加载成功")
            else:
                self.log("根端点", False, f"HTTP {response.status_code}")
        except Exception as e:
            self.log("根端点", False, str(e))
    
    def test_api_docs(self):
        """测试 API 文档页面"""
        try:
            response = requests.get(f"{self.base_url}/docs", timeout=10)
            self.log("API 文档页面", response.status_code == 200 and "swagger-ui" in response.text.lower(),
                    f"HTTP {response.status_code}")
        except Exception as e:
            self.log("API 文档页面", False, str(e))
    
    def test_register_user(self):
        """测试用户注册"""
        try:
            response = requests.post(
                f"{self.base_url}/auth/register",
                json={
                    "email": TEST_EMAIL,
                    "password": TEST_PASSWORD,
                    "username": TEST_USERNAME
                },
                timeout=10
            )
            if response.status_code == 200:
                data = response.json()
                self.user_id = data.get("data", {}).get("user_id")
                self.log("用户注册", self.user_id is not None, f"User ID: {self.user_id}")
            else:
                self.log("用户注册", False, f"HTTP {response.status_code}: {response.text}")
        except Exception as e:
            self.log("用户注册", False, str(e))
    
    def test_login_user(self):
        """测试用户登录"""
        try:
            response = requests.post(
                f"{self.base_url}/auth/login",
                json={
                    "email": TEST_EMAIL,
                    "password": TEST_PASSWORD
                },
                timeout=10
            )
            if response.status_code == 200:
                data = response.json()
                self.token = data.get("access_token")
                self.log("用户登录", self.token is not None, f"Token: {self.token[:20]}...")
            else:
                self.log("用户登录", False, f"HTTP {response.status_code}: {response.text}")
        except Exception as e:
            self.log("用户登录", False, str(e))
    
    def test_get_documents(self):
        """测试获取文档列表"""
        try:
            headers = {"Authorization": f"Bearer {self.token}"} if self.token else {}
            response = requests.get(
                f"{self.base_url}/documents",
                headers=headers,
                timeout=10
            )
            if response.status_code == 200:
                data = response.json()
                documents = data.get("data", [])
                self.log("获取文档列表", True, f"找到 {len(documents)} 个文档")
            else:
                self.log("获取文档列表", False, f"HTTP {response.status_code}")
        except Exception as e:
            self.log("获取文档列表", False, str(e))
    
    def test_create_document(self):
        """测试创建文档"""
        try:
            headers = {"Authorization": f"Bearer {self.token}"} if self.token else {}
            
            # 创建测试文件
            test_file = "test_document.txt"
            with open(test_file, "w") as f:
                f.write("这是一个测试文档\n" * 100)
            
            with open(test_file, "rb") as f:
                files = {"file": ("test.txt", f, "text/plain")}
                data = {"title": "测试文档", "tags": "测试,文档"}
                
                response = requests.post(
                    f"{self.base_url}/documents",
                    headers=headers,
                    files=files,
                    data=data,
                    timeout=10
                )
            
            # 清理测试文件
            import os
            os.remove(test_file)
            
            if response.status_code == 200:
                result = response.json()
                self.test_doc_id = result.get("data", {}).get("id")
                self.log("创建文档", self.test_doc_id is not None, f"Document ID: {self.test_doc_id}")
            else:
                self.log("创建文档", False, f"HTTP {response.status_code}: {response.text}")
        except Exception as e:
            self.log("创建文档", False, str(e))
    
    def test_get_document_detail(self):
        """测试获取文档详情"""
        if not self.test_doc_id:
            self.log("获取文档详情", False, "没有测试文档 ID")
            return
        
        try:
            headers = {"Authorization": f"Bearer {self.token}"} if self.token else {}
            response = requests.get(
                f"{self.base_url}/documents/{self.test_doc_id}",
                headers=headers,
                timeout=10
            )
            if response.status_code == 200:
                data = response.json()
                doc = data.get("data", {})
                self.log("获取文档详情", doc.get("id") == self.test_doc_id,
                        f"Title: {doc.get('title')}")
            else:
                self.log("获取文档详情", False, f"HTTP {response.status_code}")
        except Exception as e:
            self.log("获取文档详情", False, str(e))
    
    def test_update_document(self):
        """测试更新文档"""
        if not self.test_doc_id:
            self.log("更新文档", False, "没有测试文档 ID")
            return
        
        try:
            headers = {"Authorization": f"Bearer {self.token}"} if self.token else {}
            response = requests.put(
                f"{self.base_url}/documents/{self.test_doc_id}",
                headers=headers,
                data={"title": "更新后的测试文档"},
                timeout=10
            )
            if response.status_code == 200:
                data = response.json()
                doc = data.get("data", {})
                self.log("更新文档", doc.get("title") == "更新后的测试文档",
                        f"New title: {doc.get('title')}")
            else:
                self.log("更新文档", False, f"HTTP {response.status_code}")
        except Exception as e:
            self.log("更新文档", False, str(e))
    
    def test_search_documents(self):
        """测试搜索文档"""
        try:
            headers = {"Authorization": f"Bearer {self.token}"} if self.token else {}
            response = requests.get(
                f"{self.base_url}/documents/search/测试",
                headers=headers,
                timeout=10
            )
            if response.status_code == 200:
                data = response.json()
                self.log("搜索文档", True, f"找到 {len(data.get('data', []))} 个结果")
            else:
                self.log("搜索文档", False, f"HTTP {response.status_code}")
        except Exception as e:
            self.log("搜索文档", False, str(e))
    
    def test_delete_document(self):
        """测试删除文档"""
        if not self.test_doc_id:
            self.log("删除文档", False, "没有测试文档 ID")
            return
        
        try:
            headers = {"Authorization": f"Bearer {self.token}"} if self.token else {}
            response = requests.delete(
                f"{self.base_url}/documents/{self.test_doc_id}",
                headers=headers,
                timeout=10
            )
            self.log("删除文档", response.status_code == 200,
                    f"HTTP {response.status_code}")
        except Exception as e:
            self.log("删除文档", False, str(e))
    
    def test_openapi_schema(self):
        """测试 OpenAPI Schema"""
        try:
            response = requests.get(f"{self.base_url}/openapi.json", timeout=10)
            if response.status_code == 200:
                schema = response.json()
                has_paths = len(schema.get("paths", {})) > 0
                self.log("OpenAPI Schema", has_paths,
                        f"包含 {len(schema.get('paths', {}))} 个端点")
            else:
                self.log("OpenAPI Schema", False, f"HTTP {response.status_code}")
        except Exception as e:
            self.log("OpenAPI Schema", False, str(e))
    
    def run_all_tests(self):
        """运行所有测试"""
        print("\n" + "="*60)
        print("🧪 ScanPDF API 自动化测试")
        print("="*60 + "\n")
        
        # 基础测试
        print("📋 基础测试:")
        self.test_health_check()
        self.test_root_endpoint()
        self.test_api_docs()
        self.test_openapi_schema()
        
        # 认证测试
        print("\n🔐 认证测试:")
        self.test_register_user()
        self.test_login_user()
        
        # 文档管理测试
        print("\n📄 文档管理测试:")
        self.test_get_documents()
        self.test_create_document()
        self.test_get_document_detail()
        self.test_update_document()
        self.test_search_documents()
        self.test_delete_document()
        
        # 输出总结
        print("\n" + "="*60)
        print(f"📊 测试结果: {self.passed} 通过, {self.failed} 失败")
        print("="*60 + "\n")
        
        return self.failed == 0

if __name__ == "__main__":
    tester = APITester()
    success = tester.run_all_tests()
    sys.exit(0 if success else 1)
