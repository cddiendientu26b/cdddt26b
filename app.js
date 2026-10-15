(function(){
const C=window.APP_CONFIG||{};
window.configOk=!!(C.SUPABASE_URL&&C.SUPABASE_ANON_KEY&&!/DÁN/.test(C.SUPABASE_URL+C.SUPABASE_ANON_KEY));
window.sb=configOk&&window.supabase?window.supabase.createClient(C.SUPABASE_URL,C.SUPABASE_ANON_KEY):null;
const TZ='Asia/Ho_Chi_Minh';
window.THU=['Chủ nhật','Thứ Hai','Thứ Ba','Thứ Tư','Thứ Năm','Thứ Sáu','Thứ Bảy'];
window.vnNow=function(){const o={};
 new Intl.DateTimeFormat('en-GB',{timeZone:TZ,year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',second:'2-digit',hourCycle:'h23'}).formatToParts(new Date()).forEach(p=>o[p.type]=p.value);
 return{date:o.year+'-'+o.month+'-'+o.day,time:o.hour+':'+o.minute+':'+o.second};};
window.dayNum=s=>{const a=s.split('-').map(Number);return Math.round(Date.UTC(a[0],a[1]-1,a[2])/864e5);};
window.dowOf=n=>new Date(n*864e5).getUTCDay();
window.fmtDate=s=>{const a=s.split('-');return THU[dowOf(dayNum(s))]+', ngày '+(+a[2])+' tháng '+(+a[1])+' năm '+a[0];};
// Cặp trực = (số ngày trực đã qua kể từ ngày bắt đầu) chia lấy dư cho số cặp.
window.dutyFor=function(s,today){
 const pairs=s.pairs||[];if(!pairs.length)return{status:'empty'};
 if(!s.start_date)return{status:'empty'};
 const t=dayNum(today),st=dayNum(s.start_date);if(t<st)return{status:'notyet'};
 const ok=n=>s.rule==='all'||(dowOf(n)>=1&&dowOf(n)<=5);
 let cnt=0;for(let n=st;n<t;n++)if(ok(n))cnt++;
 const idx=cnt%pairs.length;
 return{status:ok(t)?'duty':'off',idx:idx,pair:pairs[idx],total:pairs.length};};
window.loadSettings=async function(){
 if(!sb)throw new Error('Chưa cấu hình config.js (xem README, Bước 4).');
 const r=await sb.from('settings').select('*').eq('id',1).single();
 if(r.error)throw r.error;return r.data;};
})();
