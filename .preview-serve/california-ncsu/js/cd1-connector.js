(function(){
var btn=document.getElementById('cd1-btn'),dlg=document.getElementById('cd1-dialog'),ov=document.getElementById('cd1-overlay'),ta=document.getElementById('cd1-textarea');
if(!btn||!dlg)return;
var open=false;
function toggle(){open=!open;dlg.style.display=open?'block':'none';ov.style.display=open?'block':'none';btn.setAttribute('aria-pressed',open);btn.style.transform=open?'scale(0.9)':'';}
btn.addEventListener('click',toggle);
ov.addEventListener('click',toggle);
window.cd1Send=function(){var sel=document.getElementById('cd1-action');var dp=document.getElementById('cd1-direct-port');var port=dp&&dp.checked?window.CD1_MODULE_PORT:'20000';ta.value+='['+new Date().toLocaleTimeString()+'] '+sel.value+' → localhost:'+port+'\n';};
window.cd1Ok=function(){toggle();};
})();
