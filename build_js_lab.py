from pathlib import Path
import json
r=Path(__file__).resolve().parent
p=r/'previews/js-lab-0.1.0/laboratorio-js.rpmx'
j=json.loads(p.read_text(encoding='utf-8'));j['source']=(r/'sources/laboratorio_js.js').read_text(encoding='utf-8');p.write_text(json.dumps(j,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
