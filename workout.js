/* =====================================================================
   Strata · Workout mode
   Source of truth for the native iOS port. Every screen here is meant to be
   rebuilt 1:1 in SwiftUI. Lines marked "IOS:" say what is simulated in the
   browser and which Apple API replaces it. Full mapping: IOS_NOTES.md
   ===================================================================== */

/* ---------- icons (24px line icons) ---------- */
const WI=(p,f)=>`<svg viewBox="0 0 24 24" fill="${f?'currentColor':'none'}" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round">${p}</svg>`;
const WIC={
  treadmill:WI('<circle cx="11" cy="4.5" r="1.6"/><path d="M8.5 15l2-4 3 2.5M10.5 11l-.5-3.5-3 2M3 19h13.5l4-9.5M16.5 9.5l-1.5-3"/>'),
  bike_out:WI('<circle cx="6" cy="16" r="3.5"/><circle cx="18" cy="16" r="3.5"/><path d="M6 16l4-7h5l3 7M10 9l3.2 7H6M13.5 6.5h2.5M14 4l3-2 3 3"/>'),
  bike_in:WI('<circle cx="8" cy="15" r="4"/><path d="M8 15h7.5l2-7.5M16 7.5h3.5M11.5 11l-2-5H7M5 21h14M15.5 15l1.5 6"/>'),
  walk:WI('<circle cx="13" cy="4.5" r="1.8"/><path d="M11 21l2-6-2.5-3 1.2-4.5 3.3 3 3 1M10.7 8L7 10.5v3.5M13 15l3 6"/>'),
  elliptical:WI('<circle cx="8" cy="17" r="3"/><path d="M4 21h15M8 17l7-4.5L17 4M15 12.5l3.5 4.5"/>'),
  row:WI('<circle cx="10" cy="5.5" r="1.6"/><path d="M3 19h18M6 19l4-5.5h5l3 5.5M10 13.5l-1-4.5 3-.8 3 3"/>'),
  swim:WI('<circle cx="16.5" cy="6" r="1.8"/><path d="M3 18c2 0 2.2-1.5 4.5-1.5S9.7 18 12 18s2.3-1.5 4.5-1.5S19 18 21 18M7 14l4-4 4 3-2.5-5.5-5 2"/>'),
  watch:WI('<rect x="7" y="6" width="10" height="12" rx="3"/><path d="M9 6l1-3h4l1 3M9 18l1 3h4l1-3"/>'),
  mount:WI('<path d="M3 19l6-10 4 6 2.5-3.5L21 19z"/>'),
  stop:WI('<circle cx="12" cy="13" r="8"/><path d="M12 9v4l2.5 2M10 2h4"/>'),
  flag:WI('<path d="M5 21V4m0 0h12l-2.5 4L17 12H5"/>'),
  busy:WI('<path d="M4 7v10M20 7v10M4 12h16M7 9v6M17 9v6"/>'),
  plus:WI('<path d="M12 5v14M5 12h14"/>'),
  minus:WI('<path d="M5 12h14"/>'),
  trend:WI('<path d="M3 17l6-6 4 4 8-8M15 7h6v6"/>'),
  flat:WI('<path d="M3 12h18M15 6l6 6-6 6"/>'),
  fire:WI('<path d="M12 21c-4 0-6.5-2.7-6.5-6.2 0-3.6 3-5.3 3.6-9.3 2.6 1.8 3.4 4 3.4 6 1-1 1.6-2.2 1.7-3.6 2.4 1.9 4.3 4.3 4.3 7.2 0 3.4-2.6 5.9-6.5 5.9z"/>')
};

/* ---------- cardio catalogue ----------
   IOS: hk = HKWorkoutActivityType + HKWorkoutConfiguration.locationType used when saving. */
const CARDIO_ACTS={
  treadmill:{n:'Treadmill',out:false,hk:'.walking or .running, locationType .indoor'},
  bike_out:{n:'Outdoor bike',out:true,hk:'.cycling, locationType .outdoor'},
  bike_in:{n:'Indoor bike',out:false,hk:'.cycling, locationType .indoor'},
  walk:{n:'Walk',out:true,hk:'.walking, locationType .outdoor'},
  elliptical:{n:'Elliptical',out:false,hk:'.elliptical'},
  row:{n:'Rower',out:false,hk:'.rowing, locationType .indoor'},
  swim:{n:'Swim',out:false,hk:'.swimming, swimmingLocationType .pool'}
};
const GRID_ACTS=['bike_out','bike_in','walk','elliptical','row','swim'];
const ZNAME=['','Warm-up','Easy','Endurance','Threshold','Max'];
const ZCOL=['','#6E7385','#8A8FA0','#FF6B4A','#C9553B','#8E3B2A'];

/* ---------- tunables: every number the workout logic uses lives here ---------- */
const WCFG={
  countdownSec:3,
  sampleEverySec:5,        // a heart-rate / altitude reading is stored every 5 s
  maxSampleGapSec:15,      // a longer gap between readings (app asleep) is not credited to any zone
  zoneTops:[.6,.7,.8,.9],  // upper bound of Z1..Z4 as a fraction of HRmax; Z5 is above
  elevNoiseM:1,            // altitude changes smaller than this are GPS noise
  elevMaxAccuracyM:20,     // discard altitude readings less accurate than this
  intervalCreditFrac:.75,  // a hard 4x4 interval counts once 75% of it is done
  shortCardioMin:20,       // cardio blocks shorter than this on a non-heart day don't count as a Heart session
  busyMin:3,               // how long a "machine busy" lift is skipped by "next up"
  warmupSteps:[[.5,6],[.7,3]], // warm-up options: fraction of today's weight, reps
  emptyBarReps:8,
  fallbackAct:{'4x4':'treadmill',z2:'treadmill',walk:'walk',office:'walk',other:'elliptical'},
  guide:{z2:'45–60 min at a conversational pace',walk:'45–90 min, easy pace',office:'Counts toward your steps goal',other:'Easy cardio block before or after your lift'}
};

/* What today's plan asks for decides the menu: a heart day only offers cardio,
   a strength day goes straight into the lift. Mode follows the plan; the activity
   is just the equipment (a 4x4 can be done on a bike). The recommended activity is
   the one you last used for the same kind of session, falling back to WCFG.fallbackAct. */
function lastActFor(match){const c=[...(DB.cardio||[])].reverse().find(x=>x.act&&CARDIO_ACTS[x.act]&&match(x));return c?c.act:null}
function cardioPlan(){
  const slot=weekPlan()[wdOf(today())], n=rcDefaultIntervals();
  const kind=slot==='vo2'?'4x4':slot==='z2'?'z2':slot==='walk'?'walk':slot==='office'?'office':'other';
  const mode=kind==='4x4'?'4x4':kind==='z2'?'z2':'free';
  const type=kind==='4x4'?'4x4':kind==='z2'?'z2':kind==='walk'?'walk':'cardio';
  const act=lastActFor(x=>x.type===type)||WCFG.fallbackAct[kind];
  const sub=kind==='4x4'?`${n} hard intervals with recovery · ~${rcMinutes(n)} min`:WCFG.guide[kind];
  return {slot,kind,mode,n,act,title:`${CARDIO_ACTS[act].n}${mode!=='free'?' · '+modeLbl(mode):''}`,sub};
}
const modeLbl=m=>m==='4x4'?'4×4':m==='z2'?'Zone 2':'';

/* ---------- heart-rate zones (real logic) ---------- */
const hrMax=()=>{const h=rcHR();return h?h.max:null};            // Tanaka, from the age in Settings. No age = no zones.
const zoneOf=(h,M)=>{const f=h/M, t=WCFG.zoneTops;return f<t[0]?1:f<t[1]?2:f<t[2]?3:f<t[3]?4:5};
const zoneRange=(z,M)=>{const t=[0,...WCFG.zoneTops,1.1];return [Math.round(M*t[z-1]),Math.round(M*t[z])]};

/* ---------- sensors: one adapter, real sources only ----------
   Web: altitude comes from the phone's GPS (real, outdoor activities only).
   Heart rate has no web source on iPhone, so it shows "—" unless demo data is
   switched on (sensors.demo.js, testing only, always labelled DEMO on screen).
   IOS: hr = HKLiveWorkoutBuilder heart-rate stream from the Strata watch app;
        alt = HKWorkoutRouteBuilder (CoreLocation) or CMAltimeter. Keep read()'s shape. */
const Sensors={
  geoId:null, alt:null, altAcc:null, demo:null,
  start(L){
    this.stop();
    if(DB.demoSensors&&window.StrataDemo)this.demo=window.StrataDemo.create(L);
    if(CARDIO_ACTS[L.act].out&&navigator.geolocation){
      this.geoId=navigator.geolocation.watchPosition(p=>{const c=p.coords;
        if(c.altitude!=null&&(c.altitudeAccuracy==null||c.altitudeAccuracy<=WCFG.elevMaxAccuracyM)){this.alt=c.altitude;this.altAcc=c.altitudeAccuracy}},
        ()=>{},{enableHighAccuracy:true,maximumAge:5000});
    }
  },
  stop(){ if(this.geoId!=null&&navigator.geolocation)navigator.geolocation.clearWatch(this.geoId); this.geoId=null; this.alt=null; this.demo=null; },
  read(t){ const d=this.demo?this.demo.read(t):{}; return {hr:d.hr!=null?d.hr:null, alt:this.alt!=null?this.alt:(d.alt!=null?d.alt:null)}; },
  hrSource(){ return this.demo?'demo':null; }   // IOS: 'watch' when the watch session is streaming
};
/* ---------- Apple Health adapter ----------
   Web has no HealthKit, so both calls say so and the UI tells the truth.
   IOS: startWatch = HKHealthStore.startWatchApp(with: HKWorkoutConfiguration);
        saveWorkout = builder.endCollection + finishWorkout() on the watch. */
const Health={
  available:false,
  async startWatch(cfg){ return {started:false}; },
  async saveWorkout(entry){ return {saved:false}; }
};

/* readings are stored on the live session, so stats survive reloads and are computed, never invented */
function takeSample(){
  const L=DB.live; if(!L)return;
  const el=liveEl(L), S=L.samples=L.samples||[], last=S[S.length-1];
  if(last&&el-last.t<WCFG.sampleEverySec)return;
  const r=Sensors.read(el); S.push({t:el,hr:r.hr,alt:r.alt}); save();
}
function cardioStats(L,el){
  const S=L.samples||[], M=hrMax(), z=[0,0,0,0,0,0];
  let wsum=0,wt=0,mx=0,gain=0,ref=null;
  S.forEach((s,i)=>{
    const nx=S[i+1], dt=Math.max(0,Math.min((nx?nx.t:el)-s.t,WCFG.maxSampleGapSec));
    if(s.hr!=null){ if(M)z[zoneOf(s.hr,M)]+=dt; wsum+=s.hr*dt; wt+=dt; mx=Math.max(mx,s.hr); }
    if(s.alt!=null){ if(ref==null)ref=s.alt; else{const d=s.alt-ref; if(Math.abs(d)>=WCFG.elevNoiseM){ if(d>0)gain+=d; ref=s.alt; }} }
  });
  const cur=[...S].reverse().find(s=>s.hr!=null);
  return {z,avg:wt?Math.round(wsum/wt):null,max:mx||null,hr:cur&&el-cur.t<=WCFG.maxSampleGapSec?cur.hr:null,
          elev:S.some(s=>s.alt!=null)?Math.round(gain):null,zonesOK:!!M&&wt>0};
}
const liveEl=L=>Math.max(0,Math.floor((Date.now()-L.started)/1000));   /* timestamp based: keeps counting in the background */
function phaseAt(t,L){
  const ph=rcPhases(L.n||4); let s=0;
  for(let i=0;i<ph.length;i++){ if(t<s+ph[i].sec)return {i,p:ph[i],into:t-s,left:s+ph[i].sec-t,ph}; s+=ph[i].sec; }
  return {i:ph.length-1,p:ph[ph.length-1],into:0,left:0,ph,over:1};
}
function hardDone(L,el){ let s=0,n=0; rcPhases(L.n).forEach(p=>{ if(p.k==='hard'&&el-s>=p.sec*WCFG.intervalCreditFrac)n++; s+=p.sec; }); return n; }

/* ---------- countdown + watch start ---------- */
function countdown(label,done,cfg){
  const o=document.createElement('div'); o.className='cd'; document.body.appendChild(o);
  let n=WCFG.countdownSec;
  const step=async()=>{
    if(n===0){o.remove(); cue(); done&&done();
      const r=await Health.startWatch(cfg||{}); if(r.started)toast(`Apple Watch · ${label} started`);
      return}
    o.innerHTML=`<div class="cdl">${esc(label)}</div><div class="cdn">${n}</div><div class="cdl" style="opacity:.6">Get ready</div>`;
    n--; setTimeout(step,1000);
  };
  step();
}

/* ===================== 1 · PICK A CARDIO ACTIVITY ===================== */
let pickAct=null;
function pickView(){
  const P=cardioPlan(), sel=pickAct||P.act;
  const recent=[]; [...(DB.cardio||[])].reverse().forEach(c=>{ if(c.act&&CARDIO_ACTS[c.act]&&!recent.some(r=>r.act===c.act)&&recent.length<2)recent.push(c) });
  const ago=d=>{const n=dayDiff(d,today());return n===0?'Today':n===1?'Yesterday':fmtD(d,{weekday:'short'})};
  const recRow=c=>`<button class="wrec ${sel===c.act?'on':''}" data-wo="act" data-i="${c.act}"><span class="wic c">${WIC[c.act]}</span>
      <span class="grow"><span class="name" style="display:block">${CARDIO_ACTS[c.act].n}${c.type==='4x4'?' · 4×4':c.type==='z2'?' · Zone 2':''}</span><span class="meta">${ago(c.date)} · ${c.min||0} min</span></span>${I.chev}</button>`;
  return `<div class="wo">
    <div class="wtop">${backBtn('woPickBack')}<div class="brand">${I.logo}Strata</div><span style="width:44px"></span></div>
    <div class="weye" style="color:var(--coral)">Cardio</div><h1 class="wh1">Choose your workout</h1>
    <button class="wfeat ${sel===P.act&&!pickAct?'on':''}" data-wo="act" data-i="${P.act}"><span class="wic c lg">${WIC[P.act]}</span>
      <span class="grow"><span class="wft">Recommended today:<br>${P.title}</span><span class="meta" style="font-size:14px">${P.sub}</span></span></button>
    ${recent.length?`<div class="wsec">Recent</div>${recent.map(recRow).join('')}`:''}
    <div class="wsec">All</div>
    <div class="wgrid">${GRID_ACTS.map(k=>`<button class="wtile ${sel===k&&pickAct?'on':''}" data-wo="act" data-i="${k}"><span class="wic c">${WIC[k]}</span><span>${CARDIO_ACTS[k].n}</span></button>`).join('')}</div>
  </div>
  <div class="dock"><button class="btn coral" data-wo="go">Start · ${CARDIO_ACTS[sel].n}${P.mode!=='free'?` · ${modeLbl(P.mode)}`:''}</button></div>`;
}
function startCardio(){
  const P=cardioPlan(), act=pickAct||P.act;
  countdown(`${CARDIO_ACTS[act].n}${P.mode!=='free'?' · '+modeLbl(P.mode):''}`,()=>{
    DB.live={act,mode:P.mode,n:P.n,slot:P.slot,started:Date.now(),date:today(),samples:[]};
    pickAct=null; Sensors.start(DB.live); takeSample(); save(); lockScreen(true); go('cardio');
  },{activity:CARDIO_ACTS[act].hk});
}

/* ===================== 2 · CARDIO IN PROGRESS (full screen) ===================== */
let lastPhase=-1;
function cardioView(){
  const L=DB.live; if(!L){scr='today';return todayView()}
  const el=liveEl(L), s=cardioStats(L,el), M=hrMax(), A=CARDIO_ACTS[L.act], src=Sensors.hrSource();
  const zc=s.hr!=null&&M?zoneOf(s.hr,M):null;
  const tot=s.z.slice(1).reduce((a,b)=>a+b,0);
  let phase='';
  if(L.mode==='4x4'){
    const a=phaseAt(el,L), hard=a.p.k==='hard';
    if(lastPhase!==-1&&a.i!==lastPhase)cue(); lastPhase=a.i;
    const lbl=a.over?'Done · cool down as long as you like':hard?a.p.label.replace(/Interval (\d+) of (\d+) · hard/,'Hard · $1 of $2'):a.p.label.replace(/ · easy/,'');
    phase=`<div class="wcard" style="${hard?'border-color:rgba(255,107,74,.55);background:rgba(255,107,74,.1)':''}"><div class="rowh"><span class="label" style="color:${hard?'var(--coral)':'var(--muted)'}">${lbl}</span><b style="font-size:24px;font-variant-numeric:tabular-nums">${a.over?'':mmss(Math.ceil(a.left))}</b></div>
      ${rcHR()&&(hard||/^Recover/.test(a.p.label))?`<div class="small" style="margin-top:4px">${hard?`Target ${rcHR().hard[0]}–${rcHR().hard[1]} bpm`:`Recover under ${rcHR().z2[1]} bpm`}</div>`:''}
      <div class="segs" style="margin-top:10px">${a.ph.map((p,i)=>`<i class="${p.k} ${i<a.i?'done':''}" style="flex:${p.sec}">${i===a.i?`<em style="width:${Math.min(100,a.into/p.sec*100)}%"></em>`:''}</i>`).join('')}</div></div>`;
  }
  const z2=L.mode==='z2'&&M?`<div class="small" style="margin-top:6px">Target: stay in Z2 · ${zoneRange(2,M).join('–')} bpm</div>`:'';
  const hrBlock=s.hr!=null
    ?`<div><b class="whrn">${s.hr}</b><span class="whru">bpm</span></div>
      ${zc?`<div style="display:flex;align-items:center;gap:10px"><span class="wz">Z${zc}</span><span class="meta" style="border-left:1px solid var(--line);padding-left:10px">${ZNAME[zc]} zone</span></div>`:`<div class="meta">Add your age in Settings to see zones</div>`}${z2}`
    :`<div><b class="whrn" style="color:var(--dim)">—</b><span class="whru">bpm</span></div>
      <div class="meta">No heart-rate source on the web. The Apple Watch connects in the iOS app.</div>`;
  const zones=s.zonesOK&&tot>0
    ?`<div class="rowh" style="margin-top:4px"><span class="name" style="font-size:18px">Time in zones</span><span class="meta">Total ${mmss(el)}</span></div>
      <div class="zbar">${[1,2,3,4,5].map(z=>`<i style="flex:${Math.max(.0001,s.z[z]/tot)};background:${z===zc?'var(--coral)':ZCOL[z]}"></i>`).join('')}</div>
      <div class="zlbl">${[1,2,3,4,5].map(z=>`<span style="${z===zc?'color:var(--coral)':''}">Z${z}<b>${mmss(s.z[z])}</b></span>`).join('')}</div>`:'';
  const second=A.out
    ?`<div class="wcard wstat"><span class="wic c">${WIC.mount}</span><div><div class="meta">Elevation</div><b>${s.elev!=null?`+${s.elev} m`:'—'}</b>${s.elev==null?`<div class="small">${navigator.geolocation?'Waiting for GPS':'No GPS'}</div>`:''}</div></div>`
    :`<div class="wcard wstat"><span class="wic c">${I.heart}</span><div><div class="meta">Avg heart rate</div><b>${s.avg!=null?s.avg:'—'}</b></div></div>`;
  const srcChip=src==='demo'
    ?`<span class="wwatch" style="border-color:rgba(245,181,68,.6);color:var(--amber)">${WIC.watch}DEMO heart-rate data · <button class="link" data-wo="demo" style="padding:0;color:inherit">turn off</button></span>`
    :`<span class="wwatch">${WIC.watch}Apple Watch: iOS app only${window.StrataDemo?` · <button class="link" data-wo="demo" style="padding:0">use demo data</button>`:''}</span>`;
  return `<div class="wo">
    <div class="wtop"><div class="brand">${I.logo}Strata</div></div>
    <div class="weye" style="color:var(--coral)">Cardio${L.mode!=='free'?' · '+modeLbl(L.mode):''}</div><h1 class="wh1">${A.n}</h1>
    <span class="wlive"><i></i>Workout in progress</span>
    <div class="whr"><span class="wic c lg">${WIC[L.act]}</span><div class="grow"><div class="meta" style="font-size:15px">Heart rate</div>${hrBlock}</div></div>
    ${phase}${zones}
    <div class="grid2"><div class="wcard wstat"><span class="wic c">${WIC.stop}</span><div><div class="meta">Elapsed</div><b>${mmss(el)}</b></div></div>${second}</div>
    <div style="text-align:center">${srcChip}</div>
  </div>
  <div class="dock"><button class="btn" data-wo="cdiscard">Discard</button><button class="btn coral w2" data-wo="cdone">Complete</button></div>`;
}
async function completeCardio(){
  takeSample();
  const L=DB.live, el=liveEl(L), s=cardioStats(L,el), min=Math.max(1,Math.round(el/60));
  /* Counts as the day's planned heart work on a heart day; otherwise it's a generic cardio block. */
  const type=L.mode==='4x4'?'4x4':L.mode==='z2'?'z2':L.slot==='walk'?'walk':'cardio';
  const extra={min,act:L.act};
  if(s.avg!=null){extra.avgHR=s.avg; extra.maxHR=s.max;}
  if(s.zonesOK)extra.zones=s.z.slice(1);
  if(s.elev!=null)extra.elev=s.elev;
  if(type==='4x4')extra.intervals=hardDone(L,el);
  logCardio(type,extra,L.date);
  const h=await Health.saveWorkout({...extra,type,start:L.started,end:Date.now(),samples:L.samples});
  W_last={...extra,type,date:L.date,health:!!h.saved};
  DB.live=null; lastPhase=-1; Sensors.stop(); save(); lockScreen(false); go('cdone'); blockSheet();
}
let W_last=null;

/* ===================== 3 · BETWEEN BLOCKS ===================== */
function blockSheet(){
  const v=W_last; if(!v)return;
  const lifted=liftedOn(today()), nd=nextDay();
  openSheet(`<div style="display:flex;align-items:center;gap:14px;margin:4px 0 6px"><span class="wic c lg">${WIC[v.act]}</span><div class="title2" style="font-size:24px;margin:0">${CARDIO_ACTS[v.act].n} · ${v.min} min done</div></div>
    ${lifted?'':`<button class="wnext" data-wo="addlift"><span class="wic v lg">${I.dumbbell}</span><span class="grow"><span class="wbadge">Recommended</span><span class="wft" style="display:block;margin-top:6px">Add block:<br>Strength · ${PLAN[nd].name}</span></span>${I.chev}</button>`}
    <button class="opt" data-wo="endsess" style="padding:14px"><span class="wic">${WIC.flag}</span><span class="grow name">End session</span>${I.chev}</button>`);
}
function cDoneView(){
  const v=W_last; if(!v){scr='today';return todayView()}
  const tot=v.zones?Math.max(1,v.zones.reduce((a,b)=>a+b,0)):0, st=weekStats(mondayOf(v.date));
  return hero({cls:'tall',left:'',eyebrow:`${CARDIO_ACTS[v.act].n}${v.type==='4x4'?' · 4×4':v.type==='z2'?' · Zone 2':''} · ${fmtD(v.date)}`,title:'Session complete',
    sub:st.closed[1]?'Heart ring closed for the week.':'Heart work logged.',
    badge:`<div style="width:64px;height:64px;border-radius:32px;flex:none;background:linear-gradient(160deg,#FF9A80,#F0583A);display:flex;align-items:center;justify-content:center;color:#fff"><span style="width:30px;height:30px;display:block">${I.check}</span></div>`})
   +`<main class="wrap"><section class="card stats"><div><span class="big">${v.min}</span><span class="small">Minutes</span></div><div><span class="big">${v.avgHR!=null?v.avgHR:'—'}</span><span class="small">Avg bpm</span></div><div><span class="big">${v.type==='4x4'?v.intervals:v.elev!=null?'+'+v.elev:(v.maxHR!=null?v.maxHR:'—')}</span><span class="small">${v.type==='4x4'?'Hard intervals':v.elev!=null?'m climbed':'Max bpm'}</span></div></section>
    ${v.zones?`<section class="card"><span class="label">Time in zones</span><div class="zbar" style="margin-top:10px">${v.zones.map((s,i)=>`<i style="flex:${Math.max(.0001,s/tot)};background:${ZCOL[i+1]}"></i>`).join('')}</div>
      <div class="zlbl">${v.zones.map((s,i)=>`<span>Z${i+1}<b>${mmss(s)}</b></span>`).join('')}</div></section>`:''}
    <div style="text-align:center"><span class="wwatch">${I.heart}${v.health?'Saved to Apple Health':'Saved in Strata · Apple Health sync comes with the iOS app'}</span></div>
    ${ringsCard(st,ringsLine(st))}</main>
    <div class="dock"><button class="btn" data-wo="more">Add block</button><button class="btn primary w2" id="doneBtn">Done</button></div>`;
}

/* ===================== 4 · STRENGTH: OVERVIEW (full screen) ===================== */
const blockKind=t=>/^warm/i.test(t)?'Warm-up':/^basics/i.test(t)?'Basics':/^compound/i.test(t)?'Compound':'Isolation';
function woBlocks(){
  const A=DB.active, L=liftList();
  return PLAN[A.day].blocks.filter(b=>!/^warm/i.test(b.t)).map(b=>({t:b.t,kind:blockKind(b.t),opt:isOptionalBlock(b.t),items:b.items.filter(x=>L.includes(x))})).filter(b=>b.items.length);
}
const setsOf=ex=>(DB.active.lowEnergy?2:(ex.sets||3))+((DB.active.extra||{})[shownEx(ex).id]||0);
function progOf(ex){const A=DB.active, s=shownEx(ex), e=A.entries[s.id]; return A.prog[s.id]||(e?{w:e.w,reps:[...e.reps]}:null)}
function exState(ex){const p=progOf(ex), n=p?p.reps.length:0, need=setsOf(ex); return isLogged(ex)&&n>=need?'done':n>0?'live':'todo'}
function nextUp(){ /* first unfinished lift in order, skipping ones marked busy for 3 min */
  const A=DB.active, L=liftList(), busy=A.busy||{}, now=Date.now();
  return L.find(x=>exState(x)!=='done'&&!(busy[x.id]&&now-busy[x.id]<WCFG.busyMin*60000))||L.find(x=>exState(x)!=='done');
}
function restBanner(){
  if(!(rest&&(rest.endAt-Date.now())>-1000))return '';
  const rem=Math.max(0,(rest.endAt-Date.now())/1000);
  return `<div class="wcard" style="display:flex;align-items:center;gap:12px;border-color:rgba(156,140,255,.45)">
    <div class="grow"><div class="label" id="restLbl" style="color:${rem>0?'var(--violet)':'var(--mint)'}">${rem>0?'Rest':'Go'}</div><b id="restClock" style="font-size:30px;font-variant-numeric:tabular-nums">${mmss(Math.ceil(rem))}</b>
    ${rest.next?`<div class="meta">${esc(rest.next)}</div>`:''}</div><button class="btn sm" id="rest30" style="width:auto;padding:0 14px">+30 s</button><button class="btn sm" id="restSkip" style="width:auto;padding:0 14px">Skip</button></div>`;
}
function overviewView(){
  const A=DB.active, L=liftList(), req=requiredItems(A.day), done=req.filter(x=>exState(x)==='done').length, nx=nextUp();
  const el=Math.floor((Date.now()-(A.started||Date.now()))/1000), legs=isLegs(A.day), jumps=cardioOn(A.date,'jumps');
  const row=ex=>{const s=shownEx(ex), st=exState(ex), p=progOf(ex), n=setsOf(ex), w=p?p.w:(A.lowEnergy?loEnergyW(s,wOf(s)):wOf(s)), im=imgOf(s.id), busy=(A.busy||{})[ex.id]&&Date.now()-A.busy[ex.id]<WCFG.busyMin*60000&&st!=='done';
    return `<button class="wrow ${st} ${nx===ex&&st!=='done'?'next':''}" data-wo="open" data-i="${L.indexOf(ex)}">${im?`<img class="thumb" src="${im}" alt="">`:'<div class="thumb"></div>'}
      <span class="grow"><span class="name" style="display:block">${esc(cleanN(s.n))}</span><span class="meta">${n} × ${repLbl(s,ex.r)}${perLeg(s)} · ${wLbl(s,w)}${s!==ex?' · swapped':''}</span></span>
      ${st==='done'?`<span class="wck">${I.check}</span>`:st==='live'?`<span class="chip n" style="margin:0">${p.reps.length}/${n}</span>`:busy?`<span class="chip hold" style="margin:0">Busy</span>`:nx===ex?`<span class="chip" style="margin:0;background:rgba(156,140,255,.18);color:var(--violet)">Next</span>`:I.chev}</button>`};
  return `<div class="wo">
    <div class="wtop"><span style="width:44px"></span><div style="text-align:center"><div class="name">${PLAN[A.day].name}</div><div class="small" id="elapsed">${mmss(el)} elapsed</div></div>
      <button class="gbtn" id="liftMenu" aria-label="Workout options"><span style="font-weight:800;letter-spacing:2px">···</span></button></div>
    <div class="weye" style="color:var(--violet)">Strength${legs?' + Bone':''}${A.lowEnergy?' · lighter day':''}</div><h1 class="wh1">${PLAN[A.day].name}</h1>
    <div class="wprog"><i style="width:${req.length?done/req.length*100:0}%"></i></div><div class="meta" style="margin-top:-6px">${done} of ${req.length} main lifts done</div>
    ${restBanner()}
    ${legs?`<div class="wsec">Warm-up · Bone</div><button class="wrow ${jumps?'done':''}" id="woJumps"><img class="thumb" src="img/pogo.jpg" alt=""><span class="grow"><span class="name" style="display:block">Jumps warm-up</span><span class="meta">Pogo hops 3 × 10 · Box jumps 3 × 5</span></span>${jumps?`<span class="wck" style="background:var(--mint)">${I.check}</span>`:I.chev}</button>`:''}
    ${woBlocks().map(b=>{const d=b.items.filter(x=>exState(x)==='done').length;
      return `<div class="wsec" style="display:flex;justify-content:space-between"><span>${b.kind}${b.opt?' · if time':''}</span><span class="meta" style="font-weight:600">${d} of ${b.items.length}</span></div>${b.items.map(row).join('')}`}).join('')}
  </div>
  <div class="dock"><button class="btn" data-wo="sdiscard">Discard</button><button class="btn violet w2" id="endBtn">Complete</button></div>`;
}

/* ===================== 5 · STRENGTH: ONE EXERCISE IN FOCUS ===================== */
function trendOf(id){
  const ex=exById(id), hs=DB.history.filter(h=>h.entries[id]).slice(-4).map(h=>h.entries[id]);
  if(!hs.length)return {t:'First time',c:'n',i:WIC.flat};
  if(DB.holds&&DB.holds[id])return {t:'On hold',c:'hold',i:WIC.flat};
  const last=hs[hs.length-1], hit=last.reps.every(r=>r!=null&&r>=(ex?ex.r:0));
  if(hs.length>=3&&hs.slice(-3).every(e=>e.w===last.w)&&!hit)return {t:'Stalled',c:'bad',i:WIC.flat};
  if(hs.length>=2&&last.w>hs[hs.length-2].w)return {t:'Progressing',c:'up',i:WIC.trend};
  if(hit)return {t:'On track',c:'up',i:WIC.trend};
  return {t:'Behind',c:'hold',i:WIC.flat};
}
let woReps=null;
function focusView(){
  const A=DB.active, L=liftList(), idx=curIdx(), orig=L[idx], ex=shownEx(orig);
  const blk=woBlocks().find(b=>b.items.includes(orig)), pos=blk?blk.items.indexOf(orig)+1:1;
  const n=setsOf(orig), p=progOf(orig), baseW=A.lowEnergy?loEnergyW(ex,wOf(ex)):wOf(ex), w=p?p.w:baseW, reps=p?p.reps:[];
  const last=lastOf(ex.id), tr=trendOf(ex.id), im=imgOf(ex.id);
  const exT=((A.exT||{})[ex.id])||Date.now();
  const plate=ex.bar?plateTxt(ex,w):ex.each?`${w} lb in each hand`:ex.plates?'Load evenly on both sides':ex.bw&&!w?'Bodyweight':'';
  const cur=reps.length, rv=woReps!=null?woReps:(reps[cur-1]!=null?reps[cur-1]:orig.r);
  const warm=(A.warm||{})[ex.id]||[];
  const setRow=i=>{
    if(i<cur)return `<div class="wset done"><button class="wck" data-wo="undo" data-i="${i}" aria-label="Undo set ${i+1}" ${i===cur-1?'':'disabled'}>${I.check}</button><div class="grow"><div class="name">Set ${i+1}</div><div class="meta">${w} lb × ${repLbl(ex,reps[i])}</div></div><span class="chip n" style="margin:0">Done</span></div>`;
    if(i===cur)return `<div class="wset cur"><div class="grow"><div class="name">Set ${i+1}${i>=(A.lowEnergy?2:(orig.sets||3))?' · extra':''}</div><div class="meta">${w} lb × ${repLbl(ex,orig.r)} target</div></div>
      <div class="wstep"><button data-wo="rep" data-i="-1" aria-label="Fewer">−</button><b>${rv}</b><button data-wo="rep" data-i="1" aria-label="More">+</button></div>
      <button class="wlog" data-wo="log">Log</button></div>`;
    return `<div class="wset todo"><span class="wdot"></span><div class="grow"><div class="name">Set ${i+1}</div><div class="meta">${w} lb × ${repLbl(ex,orig.r)}</div></div></div>`;
  };
  return `<div class="wfocus">
    <div class="wfimg" style="${im?`background-image:url(${im})`:''}"><div class="wtop" style="padding:0">${backBtn('woList','Back to the list')}<div class="brand">${I.logo}Strata</div>
      <span class="wtimer">${WIC.stop}<b id="woExT">${mmss(Math.floor((Date.now()-exT)/1000))}</b></span></div></div>
    <div class="wo" style="padding-top:0;margin-top:-56px;position:relative">
    <span class="wtag">${blk?blk.kind:'Exercise'} ${pos} of ${blk?blk.items.length:1}</span>
    <h1 class="wh1" style="font-size:30px;margin-top:8px">${esc(cleanN(ex.n))}</h1>
    <div class="meta" style="margin-top:-8px">${n} sets × ${repLbl(ex,orig.r)}${perLeg(ex)}${ex!==orig?' · swapped':''}</div>
    ${orig.injured?`<div class="warnbox">On hold for your injury flag. Go light or swap it.</div>`:''}
    <div class="wcard" style="display:flex;align-items:center;gap:10px"><div class="grow"><div class="meta">Last time</div><b style="font-size:20px">${last?`${last.w} × ${last.reps.map(r=>r==null?'–':r).join('/')}`:'No history yet'}</b></div>
      <span class="wtrend ${tr.c}">${tr.i}${tr.t}</span></div>
    ${restBanner()}
    <div class="wcard" style="display:flex;align-items:center;gap:10px"><div class="grow"><div class="meta">Today's weight</div><div><b class="wbig">${w}</b><span class="whru" style="font-size:20px">lb</span></div>${plate?`<div class="meta">${plate}</div>`:''}</div>
      <button class="wpm" data-wo="w" data-i="-1" aria-label="Less weight">${WIC.minus}</button><button class="wpm v" data-wo="w" data-i="1" aria-label="More weight">${WIC.plus}</button></div>
    ${warm.map((s,i)=>`<div class="wset ${s.done?'done':'todo'}" style="border-style:dashed"><button class="wck ${s.done?'':'off'}" data-wo="wu" data-i="${i}" aria-label="Warm-up set done">${s.done?I.check:''}</button><div class="grow"><div class="name">Warm-up ${i+1}</div><div class="meta">${s.w} lb × ${s.r}${ex.bar?' · '+plateTxt(ex,s.w):''}</div></div><button class="link" data-wo="wudel" data-i="${i}" style="padding:4px">Remove</button></div>`).join('')}
    ${[...Array(n).keys()].map(setRow).join('')}
    <div class="grid2"><button class="btn sm" data-wo="addset">${WIC.plus}Set</button><button class="btn sm" data-wo="warm">${WIC.plus}Warm-up</button></div>
    <div class="grid2"><button class="btn sm" data-yt="${ex.id}">${I.play.replace('<svg','<svg width="14" height="14"')}Form video</button>${(ALT_OF[orig.id]||[]).length?`<button class="btn sm" id="swapBtn">${I.swap.replace('<svg','<svg width="16" height="16"')}Swap</button>`:'<span></span>'}</div>
    <button class="btn violet" data-wo="busy" style="background:rgba(156,140,255,.85)">${WIC.busy}Machine busy</button>
    </div></div>
  <div class="dock"><button class="btn" data-wo="sdiscard">Discard</button><button class="btn violet w2" data-wo="exdone">Complete</button></div>`;
}
/* Strength screens replace the old one-at-a-time lift view. Same data (DB.active), new layout. */
function liftView(){ return DB.active&&DB.active.view==='focus'?focusView():overviewView(); }
function openEx(i){
  const A=DB.active, L=liftList(), ex=L[i]; if(!ex)return;
  /* order guidance: finish a block before the next one (unless something was busy) */
  const bl=woBlocks(), bi=bl.findIndex(b=>b.items.includes(ex));
  const earlier=bl.slice(0,bi).find(b=>!b.opt&&b.items.some(x=>exState(x)!=='done'&&!((A.busy||{})[x.id])));
  if(earlier&&exState(ex)==='todo')toast(`Tip: finish ${earlier.kind} before ${bl[bi].kind}`);
  A.idx=i; A.view='focus'; A.exT=A.exT||{}; const id=shownEx(ex).id; if(!A.exT[id])A.exT[id]=Date.now();
  woReps=null; save(); render(); window.scrollTo({top:0});
}
function logWoSet(){
  const A=DB.active, L=liftList(), idx=curIdx(), orig=L[idx], ex=shownEx(orig), n=setsOf(orig);
  const p=progOf(orig)||{w:A.lowEnergy?loEnergyW(ex,wOf(ex)):wOf(ex),reps:[]};
  const r=woReps!=null?woReps:(p.reps[p.reps.length-1]!=null?p.reps[p.reps.length-1]:orig.r);
  p.reps.push(r); A.prog[ex.id]=p; woReps=null;
  if(p.reps.length>=n){
    A.entries[ex.id]={w:p.w,reps:p.reps.slice(0,n)};
    const nx=nextUp();
    if(nx){startRest(restFor(orig),`Next: ${cleanN(shownEx(nx).n)}`,'Logged');}
    A.view='list'; save(); render(); window.scrollTo({top:0});
    toast(`${cleanN(ex.n)} done${nx?` · next: ${cleanN(shownEx(nx).n)}`:' · all lifts done'}`); return;
  }
  startRest(restFor(orig),`Set ${p.reps.length+1} of ${n}`);
  save(); render();
}
function warmSheet(){
  const A=DB.active, L=liftList(), orig=L[curIdx()], ex=shownEx(orig), p=progOf(orig), w=p?p.w:(A.lowEnergy?loEnergyW(ex,wOf(ex)):wOf(ex));
  const opts=[]; if(ex.bar)opts.push([ex.bar,WCFG.emptyBarReps,'Empty bar']);
  WCFG.warmupSteps.forEach(([f,r])=>{const v=round5(w*f); if(v>0&&v<w&&!opts.some(o=>o[0]===v))opts.push([v,r,`${Math.round(f*100)}% of today`])});
  openSheet(`<div class="label">${esc(cleanN(ex.n))}</div><div class="title2" style="font-size:20px">Add a warm-up set</div>
    <p class="note">Warm-up sets don't count toward progression.</p>
    ${opts.length?opts.map(([v,r,t])=>`<button class="opt" data-wwu="${v}|${r}"><div class="grow"><div class="name">${v} lb × ${r}</div><div class="meta">${t}${ex.bar?' · '+plateTxt(ex,v):''}</div></div>${I.plus||''}</button>`).join(''):'<p class="p">Bodyweight lift: do a slow first set of 5 instead.</p>'}`);
}

/* ===================== LOCK + WIRING ===================== */
/* While a workout runs, the app only shows the workout. The only ways out are
   Complete or Discard. IOS: hide the TabView and present the workout as a
   .fullScreenCover with interactiveDismissDisabled(true). */
const W_SCREENS=new Set(['lift','jumps','cardio','cdone','done','vo2done','pick','timer','vo2']);
const _render=render;
render=function(){
  if(!onboard){
    if(DB.live&&scr!=='cardio')scr='cardio';
    else if(DB.active&&!['lift','jumps'].includes(scr))scr=(!DB.active.jumpsSeen&&isLegs(DB.active.day))?'jumps':'lift';
  }
  const V0=scr;
  if(V0==='pick'||V0==='cardio'||V0==='cdone'){
    document.body.classList.add('no-tabs'); $('#tabs').hidden=true;
    $('#app').innerHTML=V0==='pick'?pickView():V0==='cardio'?cardioView():cDoneView(); renderRest(); return;
  }
  _render();
  if(DB.active&&['lift','jumps'].includes(scr)&&!DB.active.cd){
    DB.active.cd=1; save(); countdown(`Strength · ${PLAN[DB.active.day].name}`,null,{activity:'.traditionalStrengthTraining'});
  }
};
if(DB.live)Sensors.start(DB.live);   /* reopened mid-workout: sensors restart, readings continue */
setInterval(()=>{
  if(DB.live)takeSample();
  if(scr==='cardio'&&DB.live&&!$('#sheet').innerHTML&&!document.querySelector('.cd'))render();
  if(scr==='lift'&&DB.active){const e=$('#woExT'), A=DB.active, ex=shownEx(liftList()[curIdx()]); if(e&&A.exT&&A.exT[ex.id])e.textContent=mmss(Math.floor((Date.now()-A.exT[ex.id])/1000))}
},1000);
document.addEventListener('visibilitychange',()=>{ if(!document.hidden&&DB.live){lockScreen(true);render()} });

document.addEventListener('click',e=>{
  if(e.target.closest('#sheet')||e.target.closest('#tabs'))return;
  const b=e.target.closest('button'); if(!b)return;
  const k=b.dataset.wo, i=b.dataset.i;
  if(b.id==='woPickBack'){pickAct=null;go(prevScr&&prevScr!=='pick'?prevScr:'today');return}
  if(b.id==='woList'){DB.active.view='list';woReps=null;save();render();window.scrollTo({top:0});return}
  if(b.id==='jumpBack'&&DB.active){DB.active.jumpsSeen=1;save();go('lift');return}
  if(b.id==='woJumps'){jumpSets={};DB.active.jumpsSeen=0;save();go('jumps');return}
  if(!k)return;
  const A=DB.active;
  if(k==='pick'){pickAct=null;go('pick');return}
  if(k==='act'){pickAct=i;render();return}
  if(k==='go'){startCardio();return}
  if(k==='cdiscard'){if(confirm('Discard this cardio session? Nothing will be saved.')){DB.live=null;Sensors.stop();lastPhase=-1;save();lockScreen(false);go('today')}return}
  if(k==='cdone'){completeCardio();return}
  if(k==='demo'){DB.demoSensors=!DB.demoSensors; save(); if(DB.live)Sensors.start(DB.live); render(); return}
  if(k==='more'){blockSheet();return}
  if(k==='open'){openEx(+i);return}
  if(k==='sdiscard'){if(confirm('Discard this workout? Nothing will be saved.')){DB.active=null;rest=null;save();go('today')}return}
  if(k==='rep'){const L=liftList(),orig=L[curIdx()],ex=shownEx(orig),p=progOf(orig);const base=woReps!=null?woReps:(p&&p.reps.length?p.reps[p.reps.length-1]:orig.r);woReps=Math.max(0,base+(+i)*(isSec(ex)?5:1));render();return}
  if(k==='log'){logWoSet();return}
  if(k==='undo'){const L=liftList(),orig=L[curIdx()],ex=shownEx(orig),p=progOf(orig);if(!p)return;p.reps.pop();A.prog[ex.id]=p;delete A.entries[ex.id];save();render();return}
  if(k==='w'){const L=liftList(),orig=L[curIdx()],ex=shownEx(orig);const p=progOf(orig)||{w:A.lowEnergy?loEnergyW(ex,wOf(ex)):wOf(ex),reps:[]};
    p.w=Math.max(0,p.w+(+i)*(ex.inc||5));A.prog[ex.id]=p;if(A.entries[ex.id])A.entries[ex.id].w=p.w;save();render();return}
  if(k==='addset'){const ex=shownEx(liftList()[curIdx()]);A.extra=A.extra||{};A.extra[ex.id]=(A.extra[ex.id]||0)+1;save();render();toast('Extra set added');return}
  if(k==='warm'){warmSheet();return}
  if(k==='wu'){const ex=shownEx(liftList()[curIdx()]),s=A.warm[ex.id][+i];s.done=!s.done;save();render();return}
  if(k==='wudel'){const ex=shownEx(liftList()[curIdx()]);A.warm[ex.id].splice(+i,1);save();render();return}
  if(k==='busy'){const L=liftList(),orig=L[curIdx()],blk=woBlocks().find(b=>b.items.includes(orig));
    A.busy=A.busy||{};A.busy[orig.id]=Date.now();
    const alt=blk&&blk.items.find(x=>x!==orig&&exState(x)!=='done');
    if(alt){toast(`Switched to ${cleanN(shownEx(alt).n)}. ${cleanN(shownEx(orig).n)} comes back up in ${WCFG.busyMin} min.`);openEx(L.indexOf(alt));return}
    save(); if((ALT_OF[orig.id]||[]).length){toast('Nothing else left in this block. Swap to free equipment?');swapSheet();}else toast('Nothing else left in this block. Wait a minute, it frees up.');return}
  if(k==='exdone'){const L=liftList(),orig=L[curIdx()],ex=shownEx(orig),p=progOf(orig),n=setsOf(orig);
    if(p&&p.reps.length&&p.reps.length<n){if(!confirm(`${n-p.reps.length} set${n-p.reps.length>1?'s':''} not logged. Mark this exercise done anyway?`))return;A.entries[ex.id]={w:p.w,reps:p.reps.slice()}}
    A.view='list';woReps=null;save();render();window.scrollTo({top:0});return}
});
$('#sheet').addEventListener('click',e=>{
  const b=e.target.closest('button'); if(!b)return;
  if(b.dataset.wo==='addlift'){closeSheet(); const d=nextDay(); begin(d); jumpSets={}; go(isLegs(d)?'jumps':'lift'); return}
  if(b.dataset.wo==='endsess'){closeSheet(); toast('Session saved'); return}
  if(b.dataset.wwu){const [w,r]=b.dataset.wwu.split('|').map(Number), A=DB.active, ex=shownEx(liftList()[curIdx()]);
    A.warm=A.warm||{}; (A.warm[ex.id]=A.warm[ex.id]||[]).push({w,r,done:false}); save(); closeSheet(); render(); return}
});
