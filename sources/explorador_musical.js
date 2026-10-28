const FILTERS={song:'EgWKAQIIAWoMEA4QChADEAQQCRAF',artist:'EgWKAQIgAWoMEA4QChADEAQQCRAF',album:'EgWKAQIYAWoMEA4QChADEAQQCRAF',playlist:'EgWKAQIoAWoMEA4QChADEAQQCRAF'};
const LABELS={song:'Canciones',artist:'Artistas',album:'Álbumes',playlist:'Listas'};
function walk(node, visit, depth) {
  const pending=[{node:node,depth:depth||0}];let count=0;
  while(pending.length && count++<60000) {
    const entry=pending.pop(),n=entry.node;
    if(!n || typeof n!=='object' || entry.depth>38) continue;
    visit(n);
    const keys=Object.keys(n);
    for(let i=keys.length-1;i>=0;i--) if(n[keys[i]] && typeof n[keys[i]]==='object') pending.push({node:n[keys[i]],depth:entry.depth+1});
  }
}
function words(node) { return node && (node.simpleText || (node.runs||[]).map(r=>r.text||'').join('')) || ''; }
function findBrowse(node) {
  let id='';walk(node,n=>{if(!id && typeof n.browseId==='string') id=n.browseId;});return id;
}
function parsePage(data, collection) {
  let scope=data;
  if(collection && collection.kind!=='artist') {
    let shelf;walk(data,n=>{if(!shelf) shelf=n.musicPlaylistShelfRenderer||n.musicPlaylistShelfContinuation||n.musicShelfContinuation;});
    if(shelf) scope=shelf;
  }
  const items=[],seen={};let cursor='',title='';
  walk(scope,n=>{
    if(!cursor && n.nextContinuationData) cursor=n.nextContinuationData.continuation||'';
    if(!cursor && n.continuationCommand) cursor=n.continuationCommand.token||'';
    const r=n.musicResponsiveListItemRenderer||n.musicTwoRowItemRenderer;
    if(!r || items.length>=200) return;
    const columns=(r.flexColumns||[]).map(c=>c.musicResponsiveListItemFlexColumnRenderer||{});
    const name=words(r.title)||words(columns[0] && columns[0].text);
    const video=r.playlistItemData && r.playlistItemData.videoId;
    if(video && /^[A-Za-z0-9_-]{11}$/.test(video) && name && !seen[video]) {
      let artist='',album='';
      columns.forEach(c=>(c.text && c.text.runs||[]).forEach(run=>{
        const browse=findBrowse(run.navigationEndpoint);
        if(browse.startsWith('UC')) artist+=(artist?', ':'')+(run.text||'');
        if(browse.startsWith('MPRE')) album=run.text||'';
      }));
      if(!artist) artist=words(columns[1] && columns[1].text).split(' • ')[0];
      seen[video]=true;items.push({id:video,kind:'song',title:clean(name),artist:clean(artist,'YouTube Music'),album:clean(album,'Sin álbum')});return;
    }
    const id=findBrowse(r.navigationEndpoint || (columns[0] && columns[0].text));
    const kind=id.startsWith('UC')?'artist':id.startsWith('MPRE')?'album':id.startsWith('VL')?'playlist':'';
    if(kind && name && !seen[id]) {seen[id]=true;items.push({id:id,kind:kind,title:clean(name)});}
  });
  walk(data,n=>{
    const h=n.musicDetailHeaderRenderer||n.musicResponsiveHeaderRenderer||n.musicImmersiveHeaderRenderer||n.musicVisualHeaderRenderer;
    if(!title && h) title=words(h.title);
  });
  return {items:items,cursor:cursor.slice(0,16000),title:clean(title)};
}
function browse(input,s,entity,cursor) {
  const body={context:{client:{clientName:'WEB_REMIX',clientVersion:'1.'+input.date+'.01.00',hl:'es',gl:'BO'}}};
  let endpoint=entity?'browse':'search';
  if(cursor) body.continuation=cursor;
  else if(entity) body.browseId=entity.id;
  else {body.query=s.query;body.params=FILTERS[s.kind];}
  return net('https://music.youtube.com/youtubei/v1/'+endpoint+'?prettyPrint=false','browse-result',s,{entity:entity||null},body);
}
function render(s,message) {
  const c=[txt('Explorador musical',true),txt('YouTube Music · público, sin cuenta. Reproducción experimental; disponibilidad según servicio y plataforma.'),
    {type:'input',id:'query',label:'Artista, álbum, canción o enlace de lista pública',value:s.query||''},
    row(Object.keys(LABELS).map(k=>btn((s.kind===k?'✓ ':'')+LABELS[k],'search:'+k))),
    row([btn('Inicio','home'),btn('Atrás','back')])];
  if(message) c.push(txt(message));
  if(s.title) c.push(txt(s.title,true));
  const items=s.items||[],page=s.page||0;
  items.slice(page*8,page*8+8).forEach((t,i)=>c.push(card([txt(t.title,true),txt(t.kind==='song'?t.artist+' · '+t.album:LABELS[t.kind]),btn(t.kind==='song'?'Escuchar':'Abrir','item:'+(page*8+i))])));
  if(items.length) c.push(txt('Página '+(page+1)+' de '+Math.ceil(items.length/8)+' · '+items.length+' elementos en este bloque'));
  const buttons=[];
  if(page>0) buttons.push(btn('Página anterior','prev'));
  if((page+1)*8<items.length) buttons.push(btn('Página siguiente','next'));
  if(s.cursor) buttons.push(btn('Cargar siguiente bloque','more'));
  if(buttons.length) c.push(row(buttons));
  return col(c);
}
function run(input) {
  let s=Object.assign({query:'',kind:'artist',items:[],page:0,history:[]},input.state||{});
  const a=input.action||'open',ctx=input.context||{};
  if(input.stage && input.stage!=='start') s=ctx.s;
  try {
    if(input.stage==='browse-result') {
      const page=parsePage(jsonResponse(input),ctx.entity);
      s.items=page.items;s.cursor=page.cursor;s.title=page.title||s.query;s.entity=ctx.entity;s.page=0;
      return done(s,page.items.length?'':'No se encontraron elementos públicos. Prueba otra búsqueda.');
    }
    if(input.stage==='prepare') {
      if(!input.response || input.response.status!==200) throw Error('No se pudo preparar la canción.');
      const match=input.response.body.match(/ytcfg\.set\((\{.*?\})\);/s);
      if(!match) throw Error('El servicio cambió su formato de reproducción.');
      const config=JSON.parse(match[1]);
      const headers={'User-Agent':'Mozilla/5.0','X-Youtube-Client-Name':'VISIONOS','X-Youtube-Client-Version':'1.02','Origin':'https://www.youtube.com'};
      const cookies=input.response.cookies||[];if(cookies.length) headers.Cookie=cookies.join('; ');
      const visitor=config.INNERTUBE_CONTEXT && config.INNERTUBE_CONTEXT.client && config.INNERTUBE_CONTEXT.client.visitorData;
      if(visitor) headers['X-Goog-Visitor-Id']=visitor;
      const body={context:{client:{clientName:'VISIONOS',clientVersion:'1.02',deviceMake:'Apple',deviceModel:'RealityDevice17,1',osName:'visionOS',osVersion:'26.5.23O471',hl:'en',timeZone:'UTC',utcOffsetMinutes:0}},videoId:ctx.track.id};
      if(config.STS) body.playbackContext={contentPlaybackContext:{html5Preference:'HTML5_PREF_WANTS',signatureTimestamp:config.STS}};
      return {request:{url:'https://www.youtube.com/youtubei/v1/player?prettyPrint=false',method:'POST',headers:headers,body:body},next:'audio',context:ctx};
    }
    if(input.stage==='audio') {
      const data=jsonResponse(input);
      if(!data.playabilityStatus || data.playabilityStatus.status!=='OK') throw Error('Esta canción no está disponible sin cuenta.');
      const formats=(data.streamingData && data.streamingData.adaptiveFormats||[]).filter(f=>f.url && /^https:\/\//.test(f.url) && (f.mimeType||'').includes('audio/mp4'));
      const audio=formats.find(f=>f.itag===140)||formats.find(f=>f.itag===139);
      if(!audio) throw Error('No hay audio AAC compatible disponible.');
      return done(s,'Se solicitó la reproducción de '+ctx.track.title,Object.assign({},ctx.track,{url:audio.url}));
    }
    if(a.startsWith('search:')) {
      const query=String((input.fields||{}).query||s.query||'').trim().slice(0,200);
      if(!query) return done(s,'Escribe algo para buscar.');
      s.query=query;s.kind=a.slice(7);if(!FILTERS[s.kind]) s.kind='song';s.history=[];s.entity=null;
      if(query.includes('://')) {
        const m=query.match(/^https:\/\/(?:music\.|www\.)?youtube\.com\/playlist\?[^#]*\blist=([A-Za-z0-9_-]+)/);
        if(!m) return done(s,'Introduce un enlace HTTPS de una lista pública de YouTube.');
        return browse(input,s,{id:'VL'+m[1],kind:'playlist'});
      }
      return browse(input,s,null);
    }
    if(a.startsWith('item:')) {
      const t=s.items[Number(a.slice(5))];if(!t) return done(s,'El elemento ya no está disponible.');
      if(t.kind==='song') return net('https://www.youtube.com/watch?v='+t.id+'&hl=en','prepare',s,{track:t});
      s.history=(s.history||[]).concat([{entity:s.entity||null,title:s.title||s.query}]).slice(-8);
      return browse(input,s,{id:t.id,kind:t.kind});
    }
    if(a==='back' && (s.history||[]).length) {
      const previous=s.history.pop();s.title=previous.title;return browse(input,s,previous.entity);
    }
    if(a==='home') {s.items=[];s.cursor='';s.title='';s.entity=null;s.history=[];s.page=0;}
    if(a==='more' && s.cursor) return browse(input,s,s.entity,s.cursor);
    if(a==='prev') s.page=Math.max(0,s.page-1);
    if(a==='next') s.page=Math.min(Math.max(0,Math.ceil(s.items.length/8)-1),s.page+1);
    return done(s);
  } catch(e) {return done(s,clean(e.message,'No se pudo abrir esta página.'),null,true);}
}
