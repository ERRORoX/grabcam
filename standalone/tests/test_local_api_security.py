"""Security tests for the standalone management API.

Run from the repository root with:
    python3 -m unittest discover -s standalone/tests
"""
import unittest

from standalone.app import app


class LocalManagementApiSecurityTests(unittest.TestCase):
    def setUp(self):
        app.config["TESTING"] = True
        self.client = app.test_client()

    def test_loopback_client_can_read_run_status(self):
        response = self.client.get(
            "/api/tools/grabcam/run-status",
            environ_base={"REMOTE_ADDR": "127.0.0.1"},
        )
        self.assertEqual(response.status_code, 200)

    def test_remote_client_is_rejected(self):
        response = self.client.get(
            "/api/tools/grabcam/run-status",
            environ_base={"REMOTE_ADDR": "192.0.2.10"},
        )
        self.assertEqual(response.status_code, 403)

    def test_external_origin_is_rejected(self):
        response = self.client.get(
            "/api/tools/grabcam/run-status",
            headers={"Origin": "https://example.invalid"},
            environ_base={"REMOTE_ADDR": "127.0.0.1"},
        )
        self.assertEqual(response.status_code, 403)

    def test_local_origin_is_allowed(self):
        response = self.client.get(
            "/api/tools/grabcam/run-status",
            headers={"Origin": "http://127.0.0.1:5050"},
            environ_base={"REMOTE_ADDR": "127.0.0.1"},
        )
        self.assertEqual(response.status_code, 200)


if __name__ == "__main__":
    unittest.main()
