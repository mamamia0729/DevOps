"""HTTP service exposing application metadata and container health endpoints."""

import logging
import os

from flask import Flask, jsonify

APP_NAME = os.environ.get("APP_NAME", "devops-app")
APP_VERSION = os.environ.get("APP_VERSION", "0.1.0")
LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO").upper()

logging.basicConfig(
    level=LOG_LEVEL,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)

logger = logging.getLogger(__name__)


def create_app() -> Flask:
    app = Flask(__name__)

    @app.get("/")
    def index():
        return jsonify(service=APP_NAME, version=APP_VERSION)

    @app.get("/healthz")
    def healthz():
        """Liveness probe. Returns 200 while the process is able to serve."""
        return jsonify(status="ok")

    @app.get("/readyz")
    def readyz():
        """Readiness probe. Extend with dependency checks as they are added."""
        return jsonify(status="ready")

    logger.info("initialised %s version %s", APP_NAME, APP_VERSION)
    return app


app = create_app()


if __name__ == "__main__":
    # Local development only. Containers run under gunicorn; see Dockerfile.
    app.run(host="127.0.0.1", port=int(os.environ.get("PORT", "5000")))
