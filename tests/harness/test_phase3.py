import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from src.attestation.verify_artifact import verify_model_provenance, AttestationFailure

with open("tests/exploits/payload_aibom_manifest.json") as f:
    manifest = json.load(f)

# Test 1: Legitimate safetensors artifact matching sha256 of b"hello"
# SHA-256 of "hello" = 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
valid_bytes = b"hello"
is_valid, digest = verify_model_provenance(valid_bytes, manifest, "remediation-weights-v1")
assert is_valid is True
print("  - Legitimate Artifact (.safetensors):  ✅ ATTESTED (Digest and format verified)")

# Test 2: Tampered model weights (Hash mismatch)
tampered_bytes = b"hello_malicious_backdoor"
try:
    verify_model_provenance(tampered_bytes, manifest, "remediation-weights-v1")
    raise AssertionError("Tampered model passed verification!")
except AttestationFailure:
    print("  - Tampered Weights (Backdoor):         ✅ BLOCKED (Digest mismatch caught)")

# Test 3: Unsafe Pickle serialization format
try:
    verify_model_provenance(b"pickle_data", manifest, "untrusted-pickle-weights")
    raise AssertionError("Pickle format was allowed!")
except AttestationFailure:
    print("  - Prohibited Format (.pickle):         ✅ BLOCKED (Only .safetensors allowed)")
