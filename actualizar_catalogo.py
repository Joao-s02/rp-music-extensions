"""Regenera el índice con los bytes exactos de packages/*.rpmx."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parent
def entry(path):
    raw = path.read_bytes()
    package = json.loads(raw.decode('utf-8'))
    return {**{key: package[key] for key in ('id','name','version','description')},
            'minAppVersion': package.get('minAppVersion','0.3.0'),
            'path': path.relative_to(root).as_posix(), 'sha256': hashlib.sha256(raw).hexdigest()}

variants = json.loads((root / 'catalog-variants.json').read_text(encoding='utf-8'))
rows = []
ids = set()
for path in sorted((root / "packages").glob("*.rpmx")):
    raw = path.read_bytes()
    if len(raw) > 128 * 1024:
        raise ValueError(f"Paquete demasiado grande: {path.name}")
    package = json.loads(raw.decode("utf-8"))
    if 'spotify' in package['id']:
        continue  # Cancelled by the author; retain historical package bytes.
    if package["apiVersion"] != 2 or package["id"] in ids:
        raise ValueError(f"API incompatible o id repetido: {path.name}")
    ids.add(package["id"])
    rows.append({**{key: package[key] for key in ("id", "name", "version", "description")},
                 "minAppVersion": package.get("minAppVersion", "0.3.0"),
                 "path": "packages/" + path.name,
                 "sha256": hashlib.sha256(raw).hexdigest()})
for row in rows:
    paths = variants.get(row['id'], [])
    if paths:
        row['versions'] = [entry(root / path) for path in paths]
        if any(v['id'] != row['id'] for v in row['versions']):
            raise ValueError('Variante con identidad diferente')
local = root / 'previews/0.3.5/letras-locales.rpmx'
if local.exists():
    rows.append(entry(local))
explorer = root / 'previews/explorer-0.1.0/youtube-explorer.rpmx'
if explorer.exists():
    rows.append(entry(explorer))
(root / "catalog.json").write_text(json.dumps({"schemaVersion": 1, "extensions": rows}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"Catálogo actualizado: {len(rows)} extensiones")
