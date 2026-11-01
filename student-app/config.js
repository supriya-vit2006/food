window.API="https://YOUR-APP.onrender.com";
window.api=async(p,o={},t)=>{let r;try{r=await fetch(API+'/api'+p,{...o,headers:{'Content-Type':'application/json',...(t?{Authorization:'Bearer '+t}:{})},body:o.body&&JSON.stringify(o.body)})}catch(e){throw new Error(API.includes('YOUR-APP')?'config.js still has the placeholder address YOUR-APP.onrender.com':'Cannot reach '+API+' - server asleep or wrong address, or FRONTEND_URL on Render is missing this site')}
const j=await r.json().catch(()=>({}));if(!r.ok)throw new Error(j.error||'Server error '+r.status);return j};
