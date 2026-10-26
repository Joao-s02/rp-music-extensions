"""Regenera el índice con los bytes exactos de packages/*.rpmx."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parent
rows = []
ids = set()
for path in sorted((root / "packages").glob("*.rpmx")):
    raw = path.read_bytes()
    if len(raw) > 128 * 1024:
        raise ValueError(f"Paquete demasiado grande: {path.name}")
    package = json.loads(raw.decode("utf-8"))
    if package["apiVersion"] != 2 or package["id"] in ids:
        raise ValueError(f"API incompatible o id repetido: {path.name}")
    ids.add(package["id"])
    rows.append({**{key: package[key] for key in ("id", "name", "version", "description")},
                 "path": "packages/" + path.name,
                 "sha256": hashlib.sha256(raw).hexdigest()})
(root / "catalog.json").write_text(json.dumps({"schemaVersion": 1, "extensions": rows}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"Catálogo actualizado: {len(rows)} extensiones")
