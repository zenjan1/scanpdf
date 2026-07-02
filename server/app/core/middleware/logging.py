import time
import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

logger = logging.getLogger("scanpdf")


class LoggingMiddleware(BaseHTTPMiddleware):
    """请求日志中间件"""

    async def dispatch(self, request: Request, call_next) -> Response:
        start_time = time.time()
        client_ip = request.client.host if request.client else "unknown"

        response = await call_next(request)

        process_time = time.time() - start_time
        logger.info(
            f"{request.method} {request.url.path} | "
            f"Status: {response.status_code} | "
            f"Time: {process_time:.3f}s | "
            f"IP: {client_ip}"
        )

        response.headers["X-Process-Time"] = f"{process_time:.3f}"
        return response
