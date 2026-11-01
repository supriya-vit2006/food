window.API="https://YOUR-APP.onrender.com";
window.api=async(p,o={},t)=>{const r=await fetch(API+'/api'+p,{...o,headers:{'Content-Type':'application/json',...(t?{Authorization:'Bearer '+t}:{})},body:o.body&&JSON.stringify(o.body)});const j=await r.json().catch(()=>({}));if(!r.ok)throw new Error(j.error||'Something went wrong');return j};
