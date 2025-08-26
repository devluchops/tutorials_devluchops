import unittest
import sys
import os

# Add parent directory to path to import app
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import app

class TestApp(unittest.TestCase):
    def setUp(self):
        self.app = app.test_client()
        self.app.testing = True

    def test_health_endpoint(self):
        response = self.app.get('/health')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'healthy', response.data)

    def test_home_endpoint(self):
        response = self.app.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Security Vulnerable App', response.data)

    def test_search_endpoint(self):
        response = self.app.get('/search?q=test')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'test', response.data)

    def test_ping_endpoint(self):
        response = self.app.get('/ping?host=127.0.0.1')
        self.assertEqual(response.status_code, 200)

if __name__ == '__main__':
    unittest.main()