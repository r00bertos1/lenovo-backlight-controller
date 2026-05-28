#!/usr/bin/env python3
"""Validate devices.json structure for lenovo-backlight-controller.

Usage:
    python tools/validate-devices.py devices.json

Exits 0 if the file is valid, 1 if it isn't. No third-party dependencies.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REQUIRED_KEYS = {
    "name", "principal",
    "getIoctl", "getOff", "getLow", "getHigh",
    "setIoctl", "setOff", "setLow", "setHigh",
}
OPTIONAL_KEYS = {"getIn", "credits"}
ALL_KEYS = REQUIRED_KEYS | OPTIONAL_KEYS
HEX_KEYS = {
    "getIoctl", "getIn",
    "getOff", "getLow", "getHigh",
    "setIoctl", "setOff", "setLow", "setHigh",
}
HEX_RE = re.compile(r"^0x[0-9a-fA-F]{8}$")


def main(path: str) -> int:
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    errors: list[str] = []

    if data.get("schemaVersion") != 1:
        errors.append(f"schemaVersion must be 1, got {data.get('schemaVersion')!r}")

    devices = data.get("devices")
    if not isinstance(devices, list) or not devices:
        errors.append("devices must be a non-empty array")
        return _report(errors)

    for i, d in enumerate(devices):
        prefix = f"devices[{i}]"
        if not isinstance(d, dict):
            errors.append(f"{prefix}: must be an object")
            continue

        missing = REQUIRED_KEYS - d.keys()
        if missing:
            errors.append(f"{prefix}: missing required keys: {sorted(missing)}")

        unknown = d.keys() - ALL_KEYS
        if unknown:
            errors.append(f"{prefix}: unknown keys: {sorted(unknown)}")

        for k in HEX_KEYS & d.keys():
            v = d[k]
            if not isinstance(v, str) or not HEX_RE.match(v):
                errors.append(
                    f"{prefix}.{k}: must be a hex string like '0x00222680', got {v!r}"
                )

        for k in ("name", "principal"):
            v = d.get(k)
            if not isinstance(v, str) or not v:
                errors.append(f"{prefix}.{k}: must be a non-empty string")

    return _report(errors)


def _report(errors: list[str]) -> int:
    if not errors:
        print("devices.json: OK")
        return 0
    for e in errors:
        print(f"ERROR: {e}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: validate-devices.py <path-to-devices.json>", file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
