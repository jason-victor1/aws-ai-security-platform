import json
import sys
from pathlib import Path

# Anchor project root to sys.path
PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from src.gateway.handler import handler as gateway_handler
from src.rag_sanitizer.sanitizer import handler as rag_handler

print("--- TESTING PILLAR 1: TOKEN INGRESS PROXY ---")
with open("tests/exploits/payload_token_smuggle.json") as f:
    res = gateway_handler(json.load(f), None)
print("Status Code:", res["statusCode"])
print("Response:", res["body"])

print("\n--- TESTING PILLAR 2: RAG CONTEXT SANITIZER ---")
with open("tests/exploits/payload_rag_poison.json") as f:
    res = rag_handler(json.load(f), None)
print("Status Code:", res["statusCode"])
print("Response:", res["body"])
