from pathlib import Path
import json, hashlib
root=Path(__file__).resolve().parent
folder=root/'previews/explorer-0.1.0'
baseline=json.loads((folder/'BASELINE.json').read_text(encoding='utf-8'))
original=root/baseline['source']
assert hashlib.sha256(original.read_bytes()).hexdigest()==baseline['sha256'], 'Stable package changed'
package=json.loads((folder/'youtube-explorer.rpmx').read_text(encoding='utf-8'))
assert package['id'] != baseline['originalId']
source=(root/'sources/youtube_explorer_base.dart').read_text(encoding='utf-8')+'\n'+(root/'sources/youtube_explorer_browse.dart').read_text(encoding='utf-8')
assert len(source.encode())<=65536
(root/'sources/youtube_explorer.dart').write_text(source,encoding='utf-8')
package['source']=source
(folder/'youtube-explorer.rpmx').write_text(json.dumps(package,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Explorer rebuilt; stable package unchanged.')
