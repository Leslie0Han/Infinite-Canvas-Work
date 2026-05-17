#!/bin/bash
cd "$(dirname "$0")"
LAN_IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)"
if [ -z "$LAN_IP" ]; then
  LAN_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
fi
if [ -z "$LAN_IP" ]; then
  LAN_IP="127.0.0.1"
fi
APP_URL="http://${LAN_IP}:3000/"

echo "Starting ComfyUI-API-Modelscope..."
echo "Visit: ${APP_URL}"
echo "Local: http://127.0.0.1:3000/"
echo "Press Ctrl+C to stop."
echo ""

if [ ! -x ".venv/bin/python" ]; then
    echo "Virtual environment not found. Creating .venv..."
    python3 -m venv .venv
fi

if ! .venv/bin/python -c "import fastapi, uvicorn, requests, pydantic, multipart, httpx, PIL" >/dev/null 2>&1; then
    echo "Installing dependencies..."
    .venv/bin/python -m pip install --upgrade pip
    .venv/bin/python -m pip install -r requirements.txt
fi

# Open browser after 3 seconds
sleep 3 && open "${APP_URL}" &

.venv/bin/python main.py

echo ""
echo "Server stopped."
