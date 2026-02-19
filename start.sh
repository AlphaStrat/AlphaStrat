#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# AlphaStrat — Start All Services
# ═══════════════════════════════════════════════════════════════
# Usage: ./start.sh
#
# Starts both microservices:
#   1. Backend Trading Engine API  (port 8020)
#   2. Frontend Strategy Builder   (port 8010 API + port 5173 UI)
# ═══════════════════════════════════════════════════════════════

set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$ROOT_DIR/backend/algo/trading-pipeline"
FRONTEND_API_DIR="$ROOT_DIR/frontend/backend"
FRONTEND_UI_DIR="$ROOT_DIR/frontend/frontend"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  AlphaStrat — Local Development Startup${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""

# Check Python
if ! command -v python3 &>/dev/null; then
    echo -e "${RED}ERROR: python3 not found. Please install Python 3.10+${NC}"
    exit 1
fi

# Check Node.js
if ! command -v node &>/dev/null; then
    echo -e "${RED}ERROR: node not found. Please install Node.js 18+${NC}"
    exit 1
fi

# ─── Install Backend Dependencies ──────────────────────────────
echo -e "${BLUE}[1/5] Installing backend engine dependencies...${NC}"
cd "$BACKEND_DIR"
pip install -q -r requirements.txt 2>/dev/null || pip install -r requirements.txt
pip install -q fastapi uvicorn[standard] 2>/dev/null || pip install fastapi "uvicorn[standard]"

# ─── Install Frontend API Dependencies ─────────────────────────
echo -e "${BLUE}[2/5] Installing frontend API dependencies...${NC}"
cd "$FRONTEND_API_DIR"
pip install -q -r requirements.txt 2>/dev/null || pip install -r requirements.txt

# ─── Install Frontend UI Dependencies ──────────────────────────
echo -e "${BLUE}[3/5] Installing frontend UI dependencies...${NC}"
cd "$FRONTEND_UI_DIR"
npm install --silent 2>/dev/null || npm install

# ─── Start Backend Engine API ──────────────────────────────────
echo -e "${BLUE}[4/5] Starting Backend Trading Engine API on port 8020...${NC}"
cd "$BACKEND_DIR/src"
python3 api.py &
BACKEND_PID=$!

# ─── Start Frontend API ────────────────────────────────────────
echo -e "${BLUE}[5/5] Starting Frontend Strategy Builder API on port 8010...${NC}"
cd "$FRONTEND_API_DIR"
python3 main.py &
FRONTEND_API_PID=$!

# ─── Start Frontend UI ────────────────────────────────────────
echo ""
echo -e "${YELLOW}Starting Frontend UI dev server on port 5173...${NC}"
cd "$FRONTEND_UI_DIR"
npx vite --host &
FRONTEND_UI_PID=$!

# ─── Wait & Cleanup ───────────────────────────────────────────
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  All services started!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BLUE}Frontend UI:${NC}        http://localhost:5173"
echo -e "  ${BLUE}Frontend API:${NC}       http://localhost:8010"
echo -e "  ${BLUE}Backend Engine API:${NC} http://localhost:8020"
echo ""
echo -e "  Press ${YELLOW}Ctrl+C${NC} to stop all services"
echo ""

# Trap cleanup
cleanup() {
    echo ""
    echo -e "${YELLOW}Shutting down all services...${NC}"
    kill $BACKEND_PID $FRONTEND_API_PID $FRONTEND_UI_PID 2>/dev/null
    wait 2>/dev/null
    echo -e "${GREEN}All services stopped.${NC}"
}
trap cleanup EXIT INT TERM

# Wait for all background processes
wait
