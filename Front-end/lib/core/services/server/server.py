# ─────────────────────────────────────────────────────────────────────────────
# server.py
#
# FastAPI inference server for MediLink.
#
# Brain MRI  (all under /brain):
#   POST /brain/analyze           — Upload MRI → CNN + RAG + Groq report
#   POST /brain/followup          — Patient Q&A (FAISS + Groq)
#   POST /brain/cross-reference   — MRI finding vs reported symptoms
#   POST /brain/doctor-summary    — Clinical summary for specialist
#   GET  /brain/info/{class_key}  — Knowledge base for one tumor type
#   GET  /brain/health            — Module status
#
# Chest X-ray  (all under /chest):
#   POST /chest/analyze           — Upload X-ray → DenseNet-121 + RAG + Groq
#   POST /chest/followup          — Patient Q&A  (FAISS + Groq)
#   POST /chest/cross-reference   — Findings vs reported symptoms
#   POST /chest/doctor-summary    — Clinical summary for specialist
#   GET  /chest/info/{class_key}  — Knowledge base for one condition
#   GET  /chest/health            — Module status
#
# Run:
#   cd <this directory>
#   uvicorn server:app --host 0.0.0.0 --port 8000 --reload
# ─────────────────────────────────────────────────────────────────────────────

import os
import sys
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# ── Router setup ──────────────────────────────────────────────────────────────
_SERVER_DIR = os.path.dirname(os.path.abspath(__file__))

# Chest X-ray module
_CHEST_DIR = os.path.join(_SERVER_DIR, "medilink_chest")
if _CHEST_DIR not in sys.path:
    sys.path.insert(0, _CHEST_DIR)
from chest_xray_router import router as chest_router  # noqa: E402

# Brain MRI module — force absolute paths so they survive uvicorn reload cycles
_BRAIN_DIR = os.path.join(_SERVER_DIR, "medilink_brain")
os.environ["BRAIN_MODEL_PATH"]    = os.path.join(_BRAIN_DIR, "brain_tumor_cnn.pth")
os.environ["BRAIN_KNOWLEDGE_DIR"] = os.path.join(_BRAIN_DIR, "brain_tumor_knowledge")
os.environ["BRAIN_FAISS_DIR"]     = os.path.join(_BRAIN_DIR, "brain_rag_faiss_index")
if _BRAIN_DIR not in sys.path:
    sys.path.insert(0, _BRAIN_DIR)
from brain_tumor_router import router as brain_router  # noqa: E402

# ── Logging ───────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(name)s  %(message)s",
)
logger = logging.getLogger("medibot.server")

# ── Lifespan ──────────────────────────────────────────────────────────────────
# Both models are lazy-loaded by their routers on the first request.

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Server starting up.  Brain → /brain/*  |  Chest → /chest/*")
    yield
    logger.info("Server shutting down.")

# ── App ───────────────────────────────────────────────────────────────────────

app = FastAPI(
    title="MediBot AI Inference Server",
    version="3.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

app.include_router(brain_router, prefix="/brain", tags=["Brain MRI"])
app.include_router(chest_router, prefix="/chest", tags=["Chest X-ray"])

# ── Health ────────────────────────────────────────────────────────────────────

@app.get("/health", summary="Liveness probe")
async def health():
    return {
        "status":       "ok",
        "brain_module": "available at /brain/*",
        "chest_module": "available at /chest/*",
    }
