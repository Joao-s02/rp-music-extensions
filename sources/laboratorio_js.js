function text(value, title) { return {type: 'text', text: String(value), style: title ? 'title' : 'body'}; }
function button(label, action) { return {type: 'button', label, action}; }
function column(children) { return {type: 'column', children}; }
function card(children) { return {type: 'card', children}; }
function run(input) {
  const state = Object.assign({page:'home', count:0, name:'', query:''}, input.state || {});
  const action = input.action || 'open';
  const fields = input.fields || {};
  const tracks = Array.isArray(input.tracks) ? input.tracks : [];
  let play;
  if (action === 'home') state.page='home';
  if (action === 'panel') state.page='panel';
  if (action === 'library') state.page='library';
  if (action === 'plus') state.count++;
  if (action === 'minus') state.count--;
  if (action === 'reset') state.count=0;
  if (action === 'name') state.name=String(fields.nickname || '').trim().slice(0,80);
  if (action === 'search') state.query=String(fields.search || '').trim().slice(0,80);
  if (action.startsWith('play:')) {
    const id=action.slice(5);
    if(tracks.some(t=>t.id===id)) play=id;
  }
  let content=[];
  if(state.page==='home') {
    content=[text('Laboratorio JavaScript',true),text('Esta pantalla, sus páginas y las acciones se definen en la extensión.'),
      card([text('Hola'+(state.name ? ', '+state.name : '')+' 👋'),text('Prueba un formulario con estado persistente.'),
        {type:'input',id:'nickname',label:'Tu apodo',value:state.name},button('Guardar saludo','name')]),
      button('Abrir mi panel','panel'),button('Explorar mi biblioteca','library'),
      text('El motor Dart sigue disponible para YouTube estable y Explorador.')];
  } else if(state.page==='panel') {
    content=[text('Mi panel personalizado',true),text('Contador: '+state.count),
      {type:'row',children:[button('Sumar','plus'),button('Restar','minus'),button('Reiniciar contador','reset')]},
      card([text('Puedes cerrar y abrir: el contador y el saludo se guardan solo en RP Music.')]),button('Volver al inicio','home')];
  } else {
    const query=state.query.toLowerCase();
    const matches=tracks.filter(t=>(t.title+' '+t.artist).toLowerCase().includes(query));
    content=[text('Biblioteca desde JavaScript',true),text('Vista autorizada de hasta 500 canciones locales; se muestran hasta 8 coincidencias.'),
      {type:'input',id:'search',label:'Título o artista',value:state.query},button('Buscar en mi música','search'),
      text(matches.length+' coincidencias'),
      ...matches.slice(0,8).map(t=>card([text(t.title),text(t.artist),button('Escuchar '+t.title,'play:'+t.id)])),
      button('Volver al inicio','home')];
  }
  const result={state,view:column(content)};
  if(play) result.play=play;
  return result;
}
