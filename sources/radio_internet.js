const MIRRORS=['https://de1.api.radio-browser.info','https://nl1.api.radio-browser.info','https://at1.api.radio-browser.info'];
function station(r) {
  const url=r.url_resolved||r.url||'';
  if(url.length>1024 || !/^[A-Za-z0-9-]{1,80}$/.test(r.stationuuid||'') || !/^https:\/\/[^/@:]+(?:\/|$)/i.test(url) || r.hls===1 || /\.(m3u8?|pls)(?:[?#]|$)/i.test(url) || !['MP3','AAC','AAC+'].includes(String(r.codec||'').toUpperCase())) return null;
  return {id:r.stationuuid,title:clean(r.name,'Emisora'),artist:clean(r.country,'Radio'),album:clean((r.tags||'').split(',').slice(0,3).join(' · '),'En directo'),url:url};
}
function api(s,path,next,extra) {return net(MIRRORS[s.mirror||0]+path,next,s,extra);}
function search(s) {
  let path='/json/stations/search?hidebroken=true&limit=40&offset='+(s.offset||0)+'&order=clickcount&reverse=true';
  if(s.query) path+='&name='+encodeURIComponent(s.query);
  if(s.country) path+='&country='+encodeURIComponent(s.country);
  if(s.tag) path+='&tag='+encodeURIComponent(s.tag);
  return api(s,path,'stations',{path:path,retries:0});
}
function render(s,message) {
  const c=[txt('Radio por internet',true),txt('Radio Browser · emisoras en directo MP3/AAC por HTTPS. Algunas emisoras pueden estar fuera de servicio.'),
    row([btn('Explorar emisoras','explore'),btn('Mis favoritas ('+(s.favorites||[]).length+')','favorites')])];
  if(s.mode!=='favorites') c.push(
    {type:'input',id:'name',label:'Nombre de emisora',value:s.query||''},
    {type:'input',id:'country',label:'País (opcional)',value:s.country||''},
    {type:'input',id:'tag',label:'Género o etiqueta (opcional)',value:s.tag||''},
    btn('Buscar emisoras','search'),btn('Emisoras populares','popular'));
  if(message) c.push(txt(message));
  const items=s.mode==='favorites'?(s.favorites||[]):(s.items||[]), page=s.page||0;
  items.slice(page*8,page*8+8).forEach((t,i)=>{
    const index=page*8+i,fav=(s.favorites||[]).some(f=>f.id===t.id);
    c.push(card([txt(t.title,true),txt(t.artist+' · '+t.album),row([btn('Escuchar','play:'+index),btn(fav?'Quitar favorita':'Guardar favorita','fav:'+index)])]));
  });
  if(items.length) c.push(txt('Página '+(page+1)+' de '+Math.ceil(items.length/8)));
  if(s.mode==='favorites' && !items.length) c.push(txt('Guarda emisoras desde Explorar para encontrarlas aquí.'));
  const buttons=[];
  if(page>0) buttons.push(btn('Página anterior','prev'));
  if((page+1)*8<items.length) buttons.push(btn('Página siguiente','next'));
  if(s.mode!=='favorites' && s.hasMore) buttons.push(btn('Más emisoras','more'));
  if(s.mode!=='favorites' && s.offset>0) buttons.push(btn('Bloque anterior','earlier'));
  if(buttons.length)c.push(row(buttons));return col(c);
}
function run(input) {
  let s=Object.assign({mode:'explore',items:[],favorites:[],page:0,offset:0,mirror:0,query:'',country:'',tag:''},input.state||{});
  const a=input.action||'open',ctx=input.context||{};
  if(input.stage && input.stage!=='start') s=ctx.s;
  try {
    if(input.stage==='stations' || input.stage==='station') {
      if((!input.response || input.response.status!==200) && (ctx.retries||0)<2) {
        s.mirror=((s.mirror||0)+1)%MIRRORS.length;
        return api(s,ctx.path,input.stage,Object.assign({},ctx,{s:s,retries:(ctx.retries||0)+1}));
      }
      const rows=jsonResponse(input);
      if(!Array.isArray(rows)) throw Error('El directorio devolvió un formato incompatible.');
      const items=rows.map(station).filter(Boolean);
      if(input.stage==='station') {
        if(!items.length) throw Error('La emisora ya no ofrece audio HTTPS MP3/AAC compatible.');
        const t=items[0];
        s.favorites=s.favorites.map(f=>f.id===t.id?t:f);
        return api(s,'/json/url/'+encodeURIComponent(t.id),'click',{track:t});
      }
      s.items=items;s.page=0;s.hasMore=rows.length===40;
      return done(s,items.length?'Solo se muestran emisoras HTTPS MP3/AAC compatibles.':'No hay emisoras compatibles en este bloque. Cambia los filtros o carga más emisoras.');
    }
    if(input.stage==='click') return done(s,'Se solicitó la reproducción de '+ctx.track.title,ctx.track);
    if(a==='favorites') {s.mode='favorites';s.page=0;return done(s);}
    if(a==='explore') {s.mode='explore';s.page=0;return done(s);}
    if(a==='popular') {s.query='';s.country='';s.tag='';s.offset=0;s.mode='explore';return search(s);}
    if(a==='search') {const f=input.fields||{};s.query=clean(f.name).trim();s.country=clean(f.country).trim();s.tag=clean(f.tag).trim();s.offset=0;s.mode='explore';return search(s);}
    if(a==='more' || a==='earlier') {s.offset=Math.max(0,s.offset+(a==='more'?40:-40));return search(s);}
    const items=s.mode==='favorites'?s.favorites:s.items;
    if(a==='prev')s.page=Math.max(0,s.page-1);
    if(a==='next')s.page=Math.min(Math.max(0,Math.ceil(items.length/8)-1),s.page+1);
    if(a.startsWith('fav:')) {
      const t=items[Number(a.slice(4))];if(!t)return done(s,'La emisora ya no está disponible.');
      if(s.favorites.some(f=>f.id===t.id))s.favorites=s.favorites.filter(f=>f.id!==t.id);
      else if(s.favorites.length<30) {
        s.favorites.push(t);
        if(encodeURIComponent(JSON.stringify(s.favorites)).replace(/%[0-9A-F]{2}/g,'x').length>45000) {
          s.favorites.pop();return done(s,'No queda espacio para otra favorita. Quita una antes de añadirla.');
        }
      }
      else return done(s,'Límite de 30 favoritas. Quita una para añadir otra.');
      s.page=Math.min(s.page,Math.max(0,Math.ceil((s.mode==='favorites'?s.favorites:s.items).length/8)-1));
    }
    if(a.startsWith('play:')) {
      const t=items[Number(a.slice(5))];if(!t)return done(s,'La emisora ya no está disponible.');
      const path='/json/stations/byuuid/'+encodeURIComponent(t.id);
      return api(s,path,'station',{path:path,retries:0});
    }
    return done(s);
  } catch(e) {return done(s,clean(e.message,'No se pudo consultar el directorio.'),null,true);}
}
