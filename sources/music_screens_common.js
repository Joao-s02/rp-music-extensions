function txt(value, title) { return {type:'text',text:String(value || '').slice(0,2000),style:title?'title':'body'}; }
function btn(label, action) { return {type:'button',label:String(label).slice(0,180),action:action}; }
function col(children) { return {type:'column',children:children}; }
function card(children) { return {type:'card',children:children}; }
function row(children) { return {type:'row',children:children}; }
function clean(value, fallback) { return String(value || fallback || '').slice(0,180); }
function done(s, message, play, error) {
  const bytes=value=>encodeURIComponent(JSON.stringify(value)).replace(/%[0-9A-F]{2}/g,'x').length;
  let limited=false;
  while(bytes(s)>60000 && Array.isArray(s.items) && s.items.length>8) {s.items.pop();limited=true;}
  if(limited) message='La página supera el espacio disponible. Se muestra una parte; afina la búsqueda. '+(message||'');
  const out={state:s,view:render(s,message || ''),message:message||'',error:!!error};
  if(play) out.playRemote=play;
  return out;
}
function net(url, next, s, extra, body) {
  const request={url:url,headers:{'User-Agent':'RP-Music/0.3.9'}};
  if(body) {request.method='POST';request.body=body;request.headers['User-Agent']='Mozilla/5.0';}
  return {request:request,next:next,context:Object.assign({s:s},extra||{})};
}
function jsonResponse(input) {
  if(!input.response || input.response.status!==200) throw Error('No se pudo consultar el servicio. Comprueba la conexión y vuelve a intentarlo.');
  return JSON.parse(input.response.body);
}
