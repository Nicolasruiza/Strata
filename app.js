/* ===================== STRATA =====================
   UI layer. Training logic (plans, progression, swaps, injuries, low energy,
   4x4 phases) lives in core.js, carried over unchanged from Lift Log. */

let wakeLock=null, scr='today', prevScr='today', previewDay=null, detailIdx=null, selDay=null,
    timer=null, timerTick=null, rest=null, restTick=null, vo2Done=null,
    progLift=null, progRange=8, vo2N=null, editSet=null, onboard=null;

/* ---------- icons ---------- */
const I={
 dumbbell:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M6.5 6.5v11M17.5 6.5v11M6.5 12h11M3.5 9v6M20.5 9v6"/></svg>',
 heart:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linejoin="round"><path d="M12 20s-7.5-4.6-7.5-10A4.3 4.3 0 0 1 12 7.4 4.3 4.3 0 0 1 19.5 10c0 5.4-7.5 10-7.5 10z"/></svg>',
 bone:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 16l8-8M7.2 17.8a2.2 2.2 0 1 1-2.6-2.9 2.2 2.2 0 1 1 3.4-1.9M16.8 6.2a2.2 2.2 0 1 1 2.6 2.9 2.2 2.2 0 1 1-3.4 1.9"/></svg>',
 walk:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="13" cy="4.5" r="1.8"/><path d="M10 21l2.5-6 2.5 2v4M8 12l2-4.5 3.5 1.5 2 3.5 2.5 1M11 8.5l-1.5 6.5"/></svg>',
 bolt:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linejoin="round"><path d="M13 3L5 13.5h6L10 21l8-10.5h-6z"/></svg>',
 home:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M4 11l8-6.5 8 6.5V20h-5.5v-5.5h-5V20H4z"/></svg>',
 chart:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M5 20V12M10 20V6M15 20v-9M20 20V9"/></svg>',
 cal:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3.5" y="5" width="17" height="15.5" rx="3"/><path d="M3.5 10h17M8 3v4M16 3v4M8 14h2M13 14h2M8 17h2"/></svg>',
 gear:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-1.8-.3 1.6 1.6 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.6 1.6 0 0 0-1-1.5 1.6 1.6 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.6 1.6 0 0 0 .3-1.8 1.6 1.6 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.6 1.6 0 0 0 1.5-1 1.6 1.6 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.6 1.6 0 0 0 1.8.3H9a1.6 1.6 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.6 1.6 0 0 0 1 1.5 1.6 1.6 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0-.3 1.8V9a1.6 1.6 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.6 1.6 0 0 0-1.5 1z"/></svg>',
 back:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"/></svg>',
 close:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg>',
 check:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>',
 play:'<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>',
 swap:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 4L3 8l4 4M3 8h14M17 20l4-4-4-4M21 16H7"/></svg>',
 up:'<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 19V5M6 11l6-6 6 6"/></svg>',
 chev:'<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#A9AEBD" stroke-width="2.4" stroke-linecap="round"><path d="M9 5l7 7-7 7"/></svg>',
 dl:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 4v11M7 10l5 5 5-5M5 20h14"/></svg>',
 ul:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 15V4M7 9l5-5 5 5M5 20h14"/></svg>',
 star:'<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z"/></svg>',
 logo:'<svg viewBox="0 0 26 22" fill="none"><path d="M1 21L11 3l10 18" stroke="#fff" stroke-width="2.6" stroke-linejoin="round"/><path d="M8 21l7-12 10 12" stroke="#fff" stroke-opacity=".55" stroke-width="2.6" stroke-linejoin="round"/></svg>'
};
const KC={m:'#9C8CFF',h:'#FF6B4A',b:'#4ADE80'};

/* ---------- exercise images + cues ---------- */
const IMG={bb_press:'bench_press',lat_pull:'lat_pulldown',db_ohp:'db_shoulder_press',cbl_row:'cable_row',db_curl:'db_curl',cbl_tri:'cable_tri',
 leg_raise:'leg_raise',gob_squat:'goblet_squat',hip_thrust:'hip_thrust',split_squat:'split_squat',sb_squat:'box_squat',hip_abd:'hip_abduction',
 pallof:'pallof',db_incl:'incline_db',pullup:'pullup',db_row:'db_row',lat_raise:'lat_raise',hammer:'hammer',skull:'skull',cbl_crunch:'cable_crunch',
 rdl:'rdl',sl_rdl:'sl_rdl',step_up:'step_up',leg_press:'leg_press',farmer:'farmer',ham_curl:'lying_ham',
 sa_db_bench:'db_bench',sa_lat_pull:'lat_pulldown',sa_db_ohp:'db_shoulder_press',sa_cbl_row:'cable_row',sa_db_curl:'db_curl',sa_cbl_tri:'cable_tri',
 sa_gob_squat:'goblet_squat',sa_hip_thrust:'hip_thrust',sa_split_squat:'split_squat',sa_sb_squat:'box_squat',sa_hip_abd:'hip_abduction',sa_pallof:'pallof',
 sa_db_incl:'incline_db',sa_pulldown2:'assisted_pullup',sa_cs_row:'cs_row',sa_lat_raise:'lat_raise',sa_hammer:'hammer',sa_rope_tri:'rope_tri',
 sa_sl_rdl:'sl_rdl',sa_rdl:'db_rdl',sa_step_up:'step_up',sa_leg_press:'leg_press',sa_farmer:'farmer',sa_ham_curl:'lying_ham',sa_glute_bridge:'glute_bridge',
 alt_db_bench:'db_bench',alt_neutral_pulldown:'neutral_pulldown',alt_assist_pullup:'assisted_pullup',alt_assist_pullup2:'assisted_pullup',alt_cs_row:'cs_row',
 alt_rope_tri:'rope_tri',alt_cable_curl:'cable_curl',alt_hack_squat:'hack_squat',alt_hack_squat2:'hack_squat',alt_split_squat:'bss',alt_bss:'bss',
 alt_single_leg_press:'sl_leg_press',alt_db_rdl:'db_rdl',alt_glute_bridge:'glute_bridge',alt_seated_ham:'seated_ham',alt_abductor:'hip_abduction',
 fx_seated_ham:'seated_ham',fx_hip_thrust:'hip_thrust',fx_cs_row:'cs_row',fx_m_fly2:null,
 rc_pogo:'pogo',rc_box:'box_jump',rc_4x4:'treadmill'};
const CIMG={bench:'bench_press',incline:'incline_db',ohp:'db_shoulder_press',side_delt:'lat_raise',pulldown:'lat_pulldown',pullup:'pullup',row:'db_row',
 tri:'cable_tri',curl:'db_curl',squat:'goblet_squat',legpress:'leg_press',hinge:'rdl',hipthrust:'hip_thrust',hamcurl:'lying_ham',single_leg:'split_squat',
 abduction:'hip_abduction',sl_hinge:'sl_rdl',carry:'farmer',core_flex:'leg_raise',core_antirot:'pallof',glute_iso:'glute_bridge'};
function conceptKey(id){const c=CONCEPT_OF[id]; if(c)return c;
  return Object.keys(CONCEPT).find(k=>CONCEPT[k].alts.some(a=>a.id===id))||null}
const imgOf=id=>{const s=(id in IMG)?IMG[id]:CIMG[conceptKey(id)]; return s?`img/${s}.jpg`:null};
const CUE={bench:'Shoulder blades pinned, feet planted. Lower to mid-chest, press up and slightly back.',
 incline:'Bench at 30°. Elbows about 45° from your body, lower until the dumbbells reach your chest line.',
 ohp:'Ribs down, glutes tight. Press straight up and finish with biceps by your ears.',
 side_delt:'Lead with the elbows, stop at shoulder height. Light weight, no swinging.',
 pulldown:'Chest up, pull the bar to your upper chest, elbows down and back.',
 pullup:'Start from a dead hang, pull your chest toward the bar, lower under control.',
 row:'Flat back, pull the elbow toward your hip and squeeze the shoulder blade back.',
 tri:'Elbows pinned to your sides, only the forearms move. Full lockout.',
 curl:'Elbows still, no swinging. Lower slowly, about 3 seconds down.',
 squat:'Weight on mid-foot, chest up, knees track over toes. Hips just below the knees.',
 legpress:'Feet shoulder-width, lower until knees reach about 90°. Never lock the knees hard.',
 hinge:'Hips back, soft knees, bar close. Stop when your back wants to round.',
 hipthrust:'Chin tucked, ribs down. Drive through the heels and squeeze the glutes at the top.',
 hamcurl:'Hips stay down on the pad. Curl fast, lower slowly.',
 single_leg:'Front foot does the work. Torso tall, push through the whole foot.',
 abduction:'Sit tall, push the knees out against the pads, pause one second at the widest point.',
 sl_hinge:'Hinge on one leg, the free leg reaches back. Hips square. Touch something if you wobble.',
 carry:'Stand tall, shoulders down, short quick steps. Breathe and keep walking.',
 core_flex:'Curl the pelvis up, not just the legs. No swinging.',
 core_antiext:'Lower back pressed into the floor the whole time.',
 core_antirot:'Arms straight out, resist the cable pulling you sideways. Hips square.',
 core_antilat:'Straight line from head to feet, hips high.',
 glute_iso:'Squeeze the glutes, not the lower back.',fly:'Slight bend in the elbows, open wide, squeeze together.',
 rear_delt:'Pull toward your face, elbows high, squeeze between the shoulder blades.',legext:'Pause one second at the top.',calf:'Full stretch at the bottom, pause at the top.'};
const cueOf=id=>CUE[conceptKey(id)]||'Controlled reps, stop 1–2 reps before failure.';

/* ---------- small helpers ---------- */
const $=s=>document.querySelector(s);
const esc=s=>String(s==null?'':s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const cleanN=n=>String(n||'').replace(/\s*\(.*?\)\s*/g,' ').trim();
const isSec=ex=>/second/i.test(ex.n||'');
const perLeg=ex=>/per leg/i.test(ex.n||'')?' / leg':/per side/i.test(ex.n||'')?' / side':'';
const wLbl=(ex,w)=>(ex.bw&&!w)?'bodyweight':`${w} lb${ex.each?(/farmer|carry/i.test(ex.n)?' / hand':' each'):''}`;
const repLbl=(ex,r)=>isSec(ex)?`${r} s`:`${r}`;
const fmtD=(ds,o)=>new Date(ds+'T00:00:00').toLocaleDateString('en-CA',o||{weekday:'short',month:'short',day:'numeric'});
const WD_ORDER=[1,2,3,4,5,6,0], WD_S={1:'Mon',2:'Tue',3:'Wed',4:'Thu',5:'Fri',6:'Sat',0:'Sun'},
      WD_L={1:'Monday',2:'Tuesday',3:'Wednesday',4:'Thursday',5:'Friday',6:'Saturday',0:'Sunday'};
const wdOf=ds=>new Date(ds+'T00:00:00').getDay();
const mondayOf=ds=>addDays(ds,-((wdOf(ds)+6)%7));
const weekDates=mon=>WD_ORDER.map((w,i)=>addDays(mon,i));
const nf=n=>Math.round(n).toLocaleString('en-US');

/* ---------- week plan ---------- */
function officeDays(){
  if(Array.isArray(DB.officeDays))return DB.officeDays;
  const on=!!DB.rcOffice;
  return on?[2,4]:[];
}
function weekPlan(){
  const w={1:'lift',2:'z2',3:'lift',4:'vo2',5:'lift',6:'lift',0:'walk'}, off=officeDays();
  if(off.length){
    let moved=false;
    off.forEach(d=>{ if(w[d]==='lift')return; if(w[d]==='vo2')moved=true; w[d]='office'; });
    Object.keys(w).forEach(d=>{ if(w[d]==='z2')w[d]='rest'; });
    if(moved) w[0]='vo2';
  }
  return w;
}
const HEART=new Set(['office','z2','vo2','walk']);
const SLOT_NAME={lift:'Lift',office:'Office day',z2:'Zone 2 walk',vo2:'4×4 intervals',walk:'Long walk',rest:'Rest'};
const CTYPE={office:'office',z2:'z2',vo2:'4x4',walk:'walk'};
const cardioOn=(date,type)=>(DB.cardio||[]).find(c=>c.date===date&&c.type===type);
const liftedOn=date=>DB.history.find(h=>h.date===date);
const isLegs=d=>/^legs/i.test((PLAN[d]&&PLAN[d].name)||'');

/* ---------- can't train: skip a day, keep momentum at home ---------- */
const skipOn=date=>(DB.skips||{})[date];
const SKIP_WHY=[['time','Short on time','Busy day, but I have 15–20 minutes'],['away','Can\'t get to the gym','Travel, family, gym closed'],['sick','Sick or run down','Rest is the right call']];
/* home plans: no equipment beyond a backpack; ~15–20 min */
const HOME={
  legs:{name:'Home legs + bone',min:18,ring:'b',moves:[
    ['Pogo hops','3 × 10','Bone. Quick, light bounces on the balls of your feet.'],
    ['Glute bridges','3 × 15','Squeeze at the top for 2 s. Glutes, not lower back.'],
    ['Split squats','3 × 10 / leg','Hold a loaded backpack to make it harder.'],
    ['Wall sit','3 × 30 s','Thighs parallel, back flat on the wall.'],
    ['Side plank','2 × 30 s / side','Hips high, straight line head to heel.']]},
  upper:{name:'Home upper',min:15,ring:'m',moves:[
    ['Push-ups','3 × 2 short of failure','Knees down once form breaks.'],
    ['Pike push-ups','3 × 8','Hips high, head toward the floor between your hands.'],
    ['Backpack rows','3 × 12','Hinge forward, pull the bag to your hip.'],
    ['Backpack curls','2 × 12','Slow on the way down.'],
    ['Plank','3 × 30 s','Ribs down, squeeze glutes.']]},
  vo2:{name:'Stairs or hill 4×4',min:28,ring:'h',moves:[
    ['Warm-up walk','5 min','Easy pace.'],
    ['Stairs or hill, hard','4 × 4 min','Breathing hard, can only say a few words.'],
    ['Easy walk between','3 × 3 min','Let your breathing settle.']]},
  walk:{name:'Brisk walk',min:30,ring:'h',moves:[
    ['Brisk walk outside','30 min','Pace where you can talk but not sing. Split into 3 × 10 min if the day is packed.']]}
};
const homeKey=(slot,date)=>{
  if(slot==='lift'){const sk=skipOn(date); const d=sk&&sk.day||nextDay(); return isLegs(d)?'legs':'upper'}
  return slot==='vo2'?'vo2':'walk';
};

function weekStats(mon){
  const ds=weekDates(mon), wp=weekPlan();
  const mt=WD_ORDER.filter(w=>wp[w]==='lift').length;
  const ht=WD_ORDER.filter(w=>HEART.has(wp[w])).length;
  const bt=2;
  const m=Math.min(mt,new Set(DB.history.filter(h=>ds.includes(h.date)).map(h=>h.date)).size);
  const hk=new Set((DB.cardio||[]).filter(c=>ds.includes(c.date)&&c.type!=='jumps'&&c.type!=='home'&&!(c.type==='cardio'&&(c.min||0)<20)).map(c=>c.date+c.type));
  const h=Math.min(ht,hk.size);
  const b=Math.min(bt,new Set((DB.cardio||[]).filter(c=>ds.includes(c.date)&&c.type==='jumps').map(c=>c.date)).size);
  return {m,mt,h,ht,b,bt,closed:[m>=mt,h>=ht,b>=bt],all:m>=mt&&h>=ht&&b>=bt};
}
function streak(){
  let n=0, mon=addDays(mondayOf(today()),-7);
  const first=[...DB.history.map(h=>h.date),...(DB.cardio||[]).map(c=>c.date)].sort()[0];
  while(first&&mon>=mondayOf(first)){ if(weekStats(mon).all){n++; mon=addDays(mon,-7);} else break; }
  return n;
}
/* each lift slot this week gets its own workout: past = what was logged, future continues the rotation */
function liftSlots(mon){
  const ds=weekDates(mon), wp=weekPlan(), t=today(), n=DAYS().length, out={}; let next=nextDay();
  WD_ORDER.forEach((w,i)=>{
    if(wp[w]!=='lift')return;
    const d=ds[i], h=liftedOn(d);
    if(h&&PLAN[h.day]){out[w]={day:h.day,status:'done'};return}
    if(skipOn(d)){out[w]={day:null,status:'skipped'};return}  /* rotation waits: the skipped workout moves to the next lift day */
    if(d<t){out[w]={day:null,status:'missed'};return}
    if(d===t&&DB.active){out[w]={day:DB.active.day,status:'live'};next=(DB.active.day%n)+1;return}
    out[w]={day:next,status:'planned'}; next=(next%n)+1;
  });
  return out;
}
function slotDone(slot,date,mon){
  if(slot==='lift')return !!liftedOn(date);
  if(slot==='office')return !!cardioOn(date,'office');
  if(slot==='rest')return false;
  const t=CTYPE[slot]; return weekDates(mon).some(d=>!!cardioOn(d,t));
}
const minutesFor=day=>Math.round(requiredItems(day).length*MIN_PER_LIFT/5)*5;

/* ---------- rings ---------- */
function ringSVG(k,done,target,size){
  const s=size||84, r=s/2-7, c=2*Math.PI*r, f=Math.min(1,target?done/target:0), col=KC[k], closed=f>=1;
  const icon={m:I.dumbbell,h:I.heart,b:I.bone}[k];
  return `<div style="position:relative;width:${s}px;height:${s}px;color:${col};${closed?`filter:drop-shadow(0 0 10px ${col}88)`:''}">
    <svg width="${s}" height="${s}" viewBox="0 0 ${s} ${s}" aria-hidden="true"><circle cx="${s/2}" cy="${s/2}" r="${r}" fill="none" stroke="${col}" stroke-opacity=".2" stroke-width="9"/>
    ${f>0?`<circle cx="${s/2}" cy="${s/2}" r="${r}" fill="none" stroke="${col}" stroke-width="9" stroke-linecap="round" stroke-dasharray="${(c*f).toFixed(1)} ${c.toFixed(1)}" transform="rotate(-90 ${s/2} ${s/2})"/>`:''}</svg>
    <span style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center"><span style="width:${s*.34}px;height:${s*.34}px;display:block">${icon}</span></span></div>`;
}
function ringsCard(st,headline){
  const n=st.closed.filter(Boolean).length;
  const cell=(k,lbl,d,t)=>`<div class="ring" role="img" aria-label="${lbl} ${d} of ${t}">${ringSVG(k,d,t)}<span>${lbl}</span><b>${d}/${t}</b></div>`;
  return `<section class="card"><div class="rowh"><span class="label">This week</span><span style="font-size:13px;font-weight:600;color:${n===3?'var(--mint)':'var(--muted)'}">${n===3?'All 3 rings closed':`${n} of 3 rings closed`}</span></div>
    <div class="rings">${cell('m','Muscle',st.m,st.mt)}${cell('h','Heart',st.h,st.ht)}${cell('b','Bone',st.b,st.bt)}</div>
    ${headline?`<div class="p" style="margin-top:0">${headline}</div>`:''}</section>`;
}
const rdots=st=>`<span class="rdots" aria-label="Muscle ${st.closed[0]?'closed':'open'}, Heart ${st.closed[1]?'closed':'open'}, Bone ${st.closed[2]?'closed':'open'}">${['m','h','b'].map((k,i)=>`<i style="${st.closed[i]?`background:${KC[k]}`:''}"></i>`).join('')}</span>`;

/* ---------- shell ---------- */
const TABS=[['today','Today',I.home],['progress','Progress',I.chart],['history','History',I.cal],['settings','Settings',I.gear]];
function go(s){ prevScr=scr; scr=s; editSet=null; render(); window.scrollTo({top:0}); }
function hero(o){
  return `<header class="hero ${o.cls||''}" ${o.img?`style="background-image:url(${o.img})"`:''}>
    <div class="topbar">${o.left||`<div class="brand">${I.logo}Strata</div>`}${o.right||''}</div>
    <div class="htext"><div>${o.eyebrow?`<div class="eyebrow">${o.eyebrow}</div>`:''}<h1>${o.title}</h1>${o.sub?`<div class="sub">${o.sub}</div>`:''}</div>${o.badge||''}</div></header>`;
}
const backBtn=(id,label)=>`<button class="gbtn" id="${id||'back'}" aria-label="${label||'Back'}">${I.back}</button>`;

function render(){
  const A=$('#app'), tabbed=TABS.some(t=>t[0]===scr)&&!onboard;
  document.body.classList.toggle('no-tabs',!tabbed);
  const T=$('#tabs'); T.hidden=!tabbed;
  if(tabbed)T.innerHTML=TABS.map(([k,l,ic])=>`<button data-tab="${k}" class="${scr===k?'on':''}" aria-current="${scr===k?'page':'false'}">${ic}<span>${l}</span></button>`).join('');
  if(onboard){A.innerHTML=onboardView();wireOnboard();return}
  const V={today:todayView,progress:progressView,history:historyView,settings:settingsView,preview:previewView,jumps:jumpsView,
    lift:liftView,done:doneView,vo2:vo2View,timer:timerView,vo2done:vo2DoneView,detail:detailView}[scr]||todayView;
  A.innerHTML=V();
  renderRest();
}

/* ===================== TODAY ===================== */
function todayView(){
  const t=today(), mon=mondayOf(t), wp=weekPlan(), slots=liftSlots(mon), ds=weekDates(mon), st=weekStats(mon);
  const sel=selDay==null?wdOf(t):selDay, selDate=ds[WD_ORDER.indexOf(sel)], slot=wp[sel], isToday=selDate===t;
  const strip=WD_ORDER.map((w,i)=>{
    const s=wp[w], d=ds[i], sk=skipOn(d);
    const gymDone=s==='lift'?!!liftedOn(d):s==='office'?!!cardioOn(d,'office'):!!cardioOn(d,CTYPE[s]);
    if(sk&&!gymDone){
      const hc=sk.why==='sick'?'#6E7385':KC[HOME[sk.key].ring];
      return `<button class="wd skip ${d===t?'today':''} ${w===sel?'sel':''} ${sk.done?'done':''}" data-wd="${w}" aria-label="${WD_L[w]}: couldn't train${sk.done?', home session done':''}">
        ${WD_S[w].slice(0,1)}<i style="color:${hc};${sk.done?`background:${hc};color:#0E1018`:''}">${sk.done?I.check:''}</i><b>${sk.why==='sick'?'Rest':'Home'}</b></button>`;
    }
    const realDone=gymDone;
    const col=s==='lift'?KC.m:HEART.has(s)?KC.h:'#6E7385';
    const lp=slots[w], lab=s==='lift'?(lp&&lp.day?PLAN[lp.day].name.replace('Upper','Up').replace('Legs','Leg'):'—'):({office:'Office',z2:'Z2',vo2:'4×4',walk:'Walk',rest:'Rest'}[s]);
    return `<button class="wd ${d===t?'today':''} ${w===sel?'sel':''} ${realDone?'done':''}" data-wd="${w}" aria-label="${WD_L[w]}: ${s==='lift'&&lp&&lp.day?PLAN[lp.day].name:SLOT_NAME[s]}${realDone?', done':''}">
      ${WD_S[w].slice(0,1)}<i style="color:${col};${realDone?`background:${col};color:#0E1018`:''}">${realDone?I.check:''}</i><b>${lab}</b></button>`;
  }).join('');
  const hname=profile.name;
  let main='';
  if(DB.active){
    const A=DB.active, req=requiredItems(A.day), n=req.filter(ex=>isLogged(ex)).length;
    main=`<section class="card" style="border-color:rgba(156,140,255,.45)"><div class="label" style="color:var(--violet)">In progress</div>
      <div class="title2">${PLAN[A.day].name}</div><div class="meta">${n} of ${req.length} main lifts logged</div>
      <div style="margin-top:14px"><button class="btn violet" id="resume">Resume workout</button></div></section>`;
  } else main=skipOn(selDate)&&!slotDone(slot,selDate,mon)?homeCard(selDate,isToday):slotCard(slot,selDate,isToday,slots[sel],st)+(isToday&&slot!=='rest'&&!slotDone(slot,selDate,mon)?`<button class="link" id="cantTrain" style="display:block;margin:-6px auto 0">Can't train today?</button>`:'');
  const others=isToday&&!DB.active?otherOptions(slot):'';
  const lpSel=slots[sel], mainIsNext=slot==='lift'&&lpSel&&lpSel.status==='planned';
  const nd=nextDay(), nextCardHTML=!DB.active&&!mainIsNext?`<section class="card tight" style="display:flex;align-items:center;gap:12px;padding:12px 14px">
     <span class="ico v">${I.dumbbell}</span><div class="grow"><div class="label">Next lift in your rotation</div><div class="name" style="margin-top:2px">${PLAN[nd].name}</div>
     <div class="meta">${requiredItems(nd).length} main lifts · ~${minutesFor(nd)} min${isLegs(nd)?' · jumps first':''}</div></div>
     <button class="btn sm" data-preview="${nd}" style="width:auto;padding:0 16px">${liftedOn(t)?'Preview':'Open'}</button></section>`:'';
  const hl=st.all?'Full week done. Every layer got its dose.'
    :`${st.mt-st.m>0?`${st.mt-st.m} lift${st.mt-st.m>1?'s':''}`:''}${st.ht-st.h>0?`${st.mt-st.m>0?', ':''}${st.ht-st.h} heart session${st.ht-st.h>1?'s':''}`:''}${st.bt-st.b>0?`${(st.mt-st.m>0||st.ht-st.h>0)?', ':''}${st.bt-st.b} jump day${st.bt-st.b>1?'s':''}`:''} left this week.`;
  const sk=streak();
  return hero({title:`${greet()}, ${esc(hname)}`,eyebrow:fmtD(t,{weekday:'long',month:'long',day:'numeric'}),sub:sk?`${sk}-week streak. Keep the layers stacking.`:'Build it in layers: muscle, heart, bone.'})
   +`<main class="wrap">${main}${nextCardHTML}${others}${ringsCard(st,hl)}
     <section class="card tight"><div class="rowh" style="padding:2px 4px"><span class="label">This week</span><span class="small">Tap a day</span></div><div class="week">${strip}</div></section></main>`;
}
function gateFor(d){view=d;return gate()}
function greet(){const h=new Date().getHours();return h<12?'Good morning':h<18?'Good afternoon':'Good evening'}
function isLogged(ex){const A=DB.active;return !!A.entries[(A.swaps&&A.swaps[ex.id])||ex.id]}

function slotCard(slot,date,isToday,lp,st){
  const when=isToday?'Today':fmtD(date,{weekday:'long'});
  if(slot==='lift'){
    if(!lp||lp.status==='missed')return `<section class="card"><div class="label">${when} · Muscle</div><div class="title2">Missed lift</div>
      <p class="p">Nothing logged that day. The rotation just continues: next up is <b>${PLAN[nextDay()].name}</b>.</p></section>`;
    const d=lp.day, h=lp.status==='done'?liftedOn(date):null;
    if(h){
      const jumps=cardioOn(date,'jumps');
      return `<section class="card"><div class="label" style="color:var(--violet)">${when} · Done</div><div class="title2">${PLAN[d].name}</div>
        <div class="meta">${exCount(h)} exercises${h.min?` · ${h.min} min`:''}${jumps?' · jumps done':''}</div>
        <div style="margin-top:14px"><button class="btn sm" data-detail="${DB.history.indexOf(h)}">View session</button></div></section>`;
    }
    const req=requiredItems(d), g=isToday?gateFor(d):null;
    return `<section class="card"><div class="label" style="color:var(--violet)">${when} · Muscle${isLegs(d)?' + Bone':''}</div>
      <div class="title2">${PLAN[d].name}</div><div class="meta">${req.length} main lifts · ~${minutesFor(d)} min${isLegs(d)?' · jumps first':''}</div>
      <div style="display:flex;gap:6px;margin-top:12px">${req.map(ex=>{const s=imgOf(ex.id);return s?`<img class="thumb sm" src="${s}" alt="${esc(cleanN(ex.n))}">`:''}).join('')}</div>
      ${g&&!g.ok?`<div class="warnbox" style="margin-top:12px">${g.msg}</div>`:''}
      <div style="margin-top:14px"><button class="btn ${isToday?'violet':''}" data-preview="${d}">${isToday?'See workout':'Preview'}</button></div></section>`;
  }
  if(slot==='office'){
    const c=cardioOn(date,'office');
    return `<section class="card"><div class="label" style="color:var(--coral)">${when} · Heart</div><div class="title2">Office day</div>
      <p class="p">Your walks to and from work are today's cardio. Aim for <b>10,000 steps</b> at a pace where you could talk but not sing.</p>
      ${c?`<div class="rowh" style="margin-top:14px"><span class="name" style="color:var(--coral)">${nf(c.steps||0)} steps logged</span><button class="link" data-editc="${date}|office">Edit</button></div>`
        :(isToday||date<today()?stepsInput(date):'')}</section>`;
  }
  if(slot==='vo2'){
    const c=weekDates(mondayOf(date)).map(d=>cardioOn(d,'4x4')).find(Boolean);
    const hr=rcHR();
    return `<section class="card"><div class="label" style="color:var(--coral)">${when} · Heart</div><div class="title2">4×4 intervals</div>
      ${c?`<p class="p">Done this week: <b>${c.intervals||4} intervals</b>${c.min?` in ${c.min} min`:''} on ${fmtD(c.date,{weekday:'long'})}.</p>`
      :`<p class="p">Treadmill. 4 minutes hard, 3 minutes easy, repeated. ${hr?`Hard target <b>${hr.hard[0]}–${hr.hard[1]} bpm</b>.`:'Set your age in Settings for heart-rate targets.'}</p>
      <div style="margin-top:14px">${isToday?`<button class="btn coral" data-wo="pick">Start 4×4</button><button class="link" id="openVo2" style="display:block;margin:6px auto 0">How the 4×4 works</button>`:`<button class="btn" id="openVo2">Preview</button>`}</div>`}</section>`;
  }
  if(slot==='z2'||slot==='walk'){
    const t=CTYPE[slot], c=weekDates(mondayOf(date)).map(d=>cardioOn(d,t)).find(Boolean), hr=rcHR();
    return `<section class="card"><div class="label" style="color:var(--coral)">${when} · Heart</div><div class="title2">${SLOT_NAME[slot]}</div>
      <p class="p">${slot==='z2'?`<b>45–60 min</b> at a pace where you can talk in full sentences. Treadmill 5.5 km/h at 8% incline.${hr?` Target <b>${hr.z2[0]}–${hr.z2[1]} bpm</b>.`:''}`:'Easy pace outside, <b>45–90 min</b>. Or full rest if you feel beaten up.'}</p>
      ${c?`<div class="name" style="margin-top:12px;color:var(--coral)">Done · ${c.min} min on ${fmtD(c.date,{weekday:'long'})}</div>`
        :(isToday?`<button class="btn coral" data-wo="pick" style="margin-top:14px">Start</button><div class="small" style="margin-top:10px">Already did it? Log the minutes:</div>${minutesInput(slot)}`:'')}</section>`;
  }
  return `<section class="card"><div class="label">${when}</div><div class="title2">Rest</div><p class="p">Recovery is where the adaptation happens.</p></section>`;
}
function stepsInput(date){
  return `<div style="display:flex;gap:10px;margin-top:14px;align-items:stretch">
    <label class="step" style="flex:1"><span class="sr">Steps</span><input id="stepsIn" type="number" inputmode="numeric" placeholder="10,000" aria-label="Steps" style="width:100%"></label>
    <button class="btn coral" style="width:auto;padding:0 22px;height:auto" data-logsteps="${date}">Log steps</button></div>`;
}
function minutesInput(slot){
  return `<div style="display:flex;gap:10px;margin-top:14px;align-items:stretch">
    <label class="step" style="flex:1"><span class="sr">Minutes</span><input id="minIn" type="number" inputmode="numeric" value="${slot==='z2'?50:60}" aria-label="Minutes" style="width:100%"></label>
    <button class="btn coral" style="width:auto;padding:0 22px;height:auto" data-logmin="${slot}">Log ${slot==='z2'?'Zone 2':'walk'}</button></div>`;
}
function homeCard(date,isToday){
  const sk=skipOn(date), when=isToday?'Today':fmtD(date,{weekday:'long'});
  const undo=`<button class="link" id="undoSkip" data-d="${date}" style="display:block;margin:4px auto 0">Undo · I can train after all</button>`;
  if(sk.why==='sick')return `<section class="card"><div class="label">${when} · Rest</div><div class="title2">Recover first</div>
    <p class="p">No workout today. Sleep, fluids, an easy walk only if you feel like it. Your rotation waits: <b>${PLAN[nextDay()].name}</b> is still next.</p></section>${isToday?undo:''}`;
  const H=HOME[sk.key], col=KC[H.ring], lbl={m:'Muscle',h:'Heart',b:'Bone + Muscle'}[H.ring];
  const lift=sk.slot==='lift', nd=PLAN[nextDay()].name;
  return `<section class="card" style="border-color:${col}55"><div class="label" style="color:${col}">${when} · At home · ${lbl}</div>
    <div class="title2">${H.name}</div><div class="meta">~${H.min} min · no gym needed${lift?` · ${nd} moves to your next lift day`:''}</div>
    <div style="margin-top:8px">${H.moves.map(([n,dose,how])=>`<div class="row"><div class="grow"><div class="name">${n}</div><div class="meta">${dose} · ${how}</div></div></div>`).join('')}</div>
    ${sk.done?`<div class="name" style="margin-top:12px;color:${col}">Done · momentum kept</div>`
      :isToday?`<div style="margin-top:14px"><button class="btn" id="homeDone" data-d="${date}" style="background:${col};color:#0E1018;border:0">Mark done</button></div>`:''}</section>
    ${isToday&&!sk.done?undo:''}`;
}
function cantTrainSheet(){
  openSheet(`<div class="label">Today</div><div class="title2" style="font-size:20px">Can't train today?</div>
    <p class="p" style="margin-top:4px">No problem. Nothing is lost: the rotation just waits.</p>
    ${SKIP_WHY.map(([k,n,m])=>`<button class="opt" data-why="${k}"><div class="grow"><div class="name">${n}</div><div class="meta">${m}</div></div>${I.chev}</button>`).join('')}`);
}
function otherOptions(slot){
  const opts=[];
  if(slot!=='vo2'&&slot!=='z2'&&slot!=='walk')opts.push(`<button class="btn sm" data-wo="pick">${slot==='lift'?'Cardio first':'Start cardio'}</button>`);
  if(slot!=='office'&&slot!=='z2'&&slot!=='walk')opts.push(`<button class="btn sm" data-sheet="walk">Log a walk</button>`);
  return opts.length?`<div style="display:flex;gap:8px">${opts.join('')}</div>`:'';
}

/* ===================== WORKOUT PREVIEW ===================== */
let preLow=false;
function previewView(){
  const d=previewDay, legs=isLegs(d), low=preLow;
  const blocks=PLAN[d].blocks, warm=blocks.filter(b=>/^warm-up/i.test(b.t)).flatMap(b=>b.items);
  const req=requiredItems(d), bonus=blocks.filter(b=>/^bonus/i.test(b.t)).flatMap(b=>b.items);
  const row=(ex,i)=>{const w=low?loEnergyW(ex,wOf(ex)):wOf(ex), sets=low?2:(ex.sets||3), s=imgOf(ex.id);
    return `<div class="row">${s?`<img class="thumb" src="${s}" alt="">`:`<div class="thumb"></div>`}<div class="grow"><div class="name">${esc(cleanN(ex.n))}</div>
      <div class="meta">${sets} × ${repLbl(ex,ex.r)}${perLeg(ex)} · <b style="color:#fff">${wLbl(ex,w)}</b>${i===0?' · heavy':''}${ex.injured?' · <span style="color:var(--amber)">on hold</span>':''}</div>
      ${(()=>{const l=lastOf(ex.id), pl=ex.bar&&w?plateTxt(ex,w):'';const parts=[];if(l)parts.push(`Last: ${l.w} × ${l.reps.map(r=>r==null?'–':r).join('/')}`);if(pl)parts.push(pl);return parts.length?`<div class="meta" style="font-size:12px">${parts.join(' · ')}</div>`:''})()}</div>
      <button class="gbtn" data-yt="${ex.id}" aria-label="Watch ${esc(cleanN(ex.n))} form" style="min-width:40px;height:40px;padding:0">${I.play.replace('<svg','<svg width="14" height="14"')}</button></div>`};
  const landings=legs?(3*10+3*5):0;
  const g=gateFor(d);
  return hero({left:backBtn(),title:PLAN[d].name,eyebrow:`${fmtD(today(),{weekday:'short',month:'short',day:'numeric'})}`,cls:'short',
      sub:`${legs?'Glutes, legs and bone':'Chest, back, shoulders, arms'}`})
   +`<main class="wrap"><div class="pills" style="margin-top:0"><span class="pill">~${low?Math.round(minutesFor(d)*.75/5)*5:minutesFor(d)} min</span><span class="pill">${req.length} main lifts</span>${legs?`<span class="pill m">${landings} landings</span>`:''}</div>
    ${!g.ok&&!DB.active?`<div class="warnbox">${g.msg}</div>`:''}
    ${legs||warm.length?`<section class="card" style="border-color:rgba(74,222,128,.35)"><div class="rowh"><span class="label" style="color:var(--mint)">Warm-up · Bone · 5 min</span><span class="small">Do first</span></div>
      ${legs?`<div class="row"><img class="thumb sm" src="img/pogo.jpg" alt=""><div class="grow"><div class="name">Pogo hops</div><div class="meta">3 × 10</div></div><button class="gbtn" data-yt="rc_pogo" aria-label="Watch pogo hops form" style="min-width:40px;height:40px;padding:0">${I.play.replace('<svg','<svg width="14" height="14"')}</button></div>
      <div class="row"><img class="thumb sm" src="img/box_jump.jpg" alt=""><div class="grow"><div class="name">Box jumps</div><div class="meta">3 × 5 · step down</div></div><button class="gbtn" data-yt="rc_box" aria-label="Watch box jump form" style="min-width:40px;height:40px;padding:0">${I.play.replace('<svg','<svg width="14" height="14"')}</button></div>`:''}
      ${warm.map(ex=>`<div class="row"><img class="thumb sm" src="${imgOf(ex.id)}" alt=""><div class="grow"><div class="name">${esc(cleanN(ex.n))}</div><div class="meta">2 × ${ex.r}${perLeg(ex)} · balance</div></div><button class="gbtn" data-yt="${ex.id}" aria-label="Watch form" style="min-width:40px;height:40px;padding:0">${I.play.replace('<svg','<svg width="14" height="14"')}</button></div>`).join('')}</section>`:''}
    <section class="card"><span class="label">Main lifts</span><div style="margin-top:4px">${req.map(row).join('')}</div></section>
    ${bonus.length&&!low?`<section class="card" style="border-style:dashed"><div class="rowh"><span class="label">Bonus · if time</span><span class="small">+${bonus.length*6} min</span></div>
      <div class="meta" style="margin-top:6px">${bonus.map(b=>esc(cleanN(b.n))).join(' · ')}</div></section>`:''}
    <section class="card tight"><div class="tg" style="padding:4px"><div class="grow"><div class="name">Feeling flat?</div><div class="meta">Lighter version: 85% weight, 2 sets, no bonus. Weights don't go up.</div></div>
      <button class="sw ${low?'on':''}" id="lowTg" role="switch" aria-checked="${low}" aria-label="Lighter version"></button></div></section></main>
    <div class="dock"><button class="btn violet" id="beginBtn">${legs?'Start with jumps':'Start workout'}</button></div>`;
}
function begin(day){
  celebration=null;
  DB.active={day,date:today(),started:Date.now(),entries:{},lowEnergy:preLow,swaps:{},prog:{},idx:0};
  preLow=false; save();
}

/* ===================== JUMPS ===================== */
let jumpSets={};
function jumpsView(){
  const A=DB.active, warm=PLAN[A.day].blocks.filter(b=>/^warm-up/i.test(b.t)).flatMap(b=>b.items);
  const items=[{k:'pogo',n:'Pogo hops',img:'img/pogo.jpg',sets:3,reps:'10',how:'Bounce on the balls of your feet, knees almost straight, quick and light. 30 s rest between sets.',yt:'rc_pogo'},
               {k:'box',n:'Box jumps',img:'img/box_jump.jpg',sets:3,reps:'5',how:'Low box, 30–40 cm. Jump up, land soft, stand tall, then step down. 60 s rest.',yt:'rc_box'}]
    .concat(warm.map(ex=>({k:ex.id,n:cleanN(ex.n),img:imgOf(ex.id),sets:2,reps:ex.r+perLeg(ex),how:cueOf(ex.id),yt:ex.id,ex})));
  const card=it=>{const done=jumpSets[it.k]||0;
    return `<section class="card"><div style="display:flex;gap:12px;align-items:center"><img class="thumb" src="${it.img}" alt="">
      <div class="grow"><div class="name">${it.n}</div><div class="meta">${it.sets} × ${it.reps}</div></div>
      <button class="gbtn" data-yt="${it.yt}" aria-label="Watch ${esc(it.n)}">${I.play}</button></div>
      <p class="p">${it.how}</p>
      <div style="display:flex;gap:8px;margin-top:12px">${[...Array(it.sets).keys()].map(i=>`<button class="btn sm ${i<done?'mint':''}" data-jset="${it.k}|${i}" aria-pressed="${i<done}">${i<done?I.check.replace('<svg','<svg width="16" height="16"'):`Set ${i+1}`}</button>`).join('')}</div></section>`};
  const allDone=items.every(it=>(jumpSets[it.k]||0)>=it.sets);
  return hero({left:backBtn('jumpBack'),title:'Jumps warm-up',eyebrow:`Bone · ${PLAN[A.day].name}`,cls:'short',sub:'Impact for bone density. Short, sharp, done before you lift.'})
   +`<main class="wrap">${items.map(card).join('')}</main>
    <div class="dock"><button class="btn" id="skipJumps">Skip</button><button class="btn ${allDone?'mint':''} w2" id="jumpsDone">${allDone?'Done · start lifting':'Mark done · start lifting'}</button></div>`;
}

/* ===================== LIFT IN PROGRESS ===================== */
function liftList(){
  const A=DB.active, all=sessionItems(A.day,A.lowEnergy).filter(ex=>!PLAN[A.day].blocks.some(b=>/^warm-up/i.test(b.t)&&b.items.includes(ex)));
  return all;
}
const shownEx=ex=>{const A=DB.active,to=A.swaps&&A.swaps[ex.id];return to?(ALL.find(x=>x.id===to)||ex):ex};
function curIdx(){
  const A=DB.active, L=liftList();
  if(A.idx!=null&&L[A.idx])return A.idx;
  const req=new Set(requiredItems(A.day).map(x=>x.id));
  let i=L.findIndex(ex=>req.has(ex.id)&&!isLogged(ex)); if(i<0)i=L.findIndex(ex=>!isLogged(ex)); return i<0?0:i;
}
function liftView(){
  const A=DB.active, L=liftList(), idx=curIdx(), orig=L[idx], ex=shownEx(orig);
  const reqIds=new Set(requiredItems(A.day).map(x=>x.id)), isBonus=!reqIds.has(orig.id);
  const reqL=L.filter(x=>reqIds.has(x.id)), pos=isBonus?L.filter(x=>!reqIds.has(x.id)).indexOf(orig)+1:reqL.indexOf(orig)+1;
  const setCount=A.lowEnergy?2:(orig.sets||3);
  const entry=A.entries[ex.id], prog=A.prog[ex.id]||(entry?{w:entry.w,reps:[...entry.reps]}:null);
  const baseW=A.lowEnergy?loEnergyW(ex,wOf(ex)):wOf(ex);
  const w=prog?prog.w:baseW, reps=prog?prog.reps:[];
  const exDone=reps.length>=setCount;
  const cur=editSet!=null?editSet:Math.min(reps.length,setCount-1);
  const rv=editSet!=null?reps[editSet]:(exDone?reps[setCount-1]:(reps[reps.length-1]!=null?reps[reps.length-1]:orig.r));
  const reqDone=reqL.every(isLogged), allDone=L.every(isLogged);
  const segs=L.map((x,i)=>`<button class="${isLogged(x)?'done':''} ${i===idx?'cur':''} ${reqIds.has(x.id)?'':'bonus'}" data-goto="${i}" aria-label="${esc(cleanN(shownEx(x).n))}${isLogged(x)?', done':''}"></button>`).join('');
  /* progression: computed from real history, never invented */
  const last=lastOf(ex.id), held=(DB.holds&&DB.holds[ex.id])||A.lowEnergy, canUp=ex.inc&&!held;
  const nextW=canUp?progressedWeight(ex,baseW):baseW;
  const lastTxt=last?`${last.w} × ${last.reps.map(r=>r==null?'–':r).join('/')}`:'None yet';
  const progCard=`<section class="card tight" style="display:flex;gap:10px;align-items:stretch;padding:12px 14px">
    <div class="grow"><div class="label">Last time</div><div class="name" style="margin-top:4px">${lastTxt}</div></div>
    <div class="grow" style="border-left:1px solid var(--line);padding-left:12px"><div class="label">Today</div><div class="name" style="margin-top:4px">${wLbl(ex,baseW)}</div></div>
    <div style="flex:1.3;border-radius:14px;padding:8px 10px;background:${canUp?'rgba(156,140,255,.12)':'rgba(245,181,68,.1)'};border:1px solid ${canUp?'rgba(156,140,255,.4)':'rgba(245,181,68,.35)'}">
      <div class="label" style="color:${canUp?'var(--violet)':'var(--amber)'}">${canUp?'Hit all sets':A.lowEnergy?'Lighter day':'On hold'}</div>
      <div class="name" style="margin-top:4px">${canUp?`${nextW} lb next`:'Weight stays'}</div></div></section>`;
  /* media slot: same size in every state */
  const resting=rest&&(rest.endAt-Date.now())>-1000;
  const s=imgOf(ex.id), plate=ex.bar?plateTxt(ex,w):(ex.each?`${w} lb in each hand`:ex.plates?'Load evenly on both sides':'');
  let media;
  if(resting){
    const rem=Math.max(0,(rest.endAt-Date.now())/1000), C=2*Math.PI*62;
    media=`<div style="display:flex;align-items:center;gap:16px;height:100%">
      <div style="position:relative;width:124px;height:124px;flex:none"><svg width="124" height="124" viewBox="0 0 140 140" aria-hidden="true"><circle cx="70" cy="70" r="62" fill="none" stroke="rgba(255,255,255,.1)" stroke-width="9"/>
        <circle id="restArc" cx="70" cy="70" r="62" fill="none" stroke="${rem>0?'#9C8CFF':'#4ADE80'}" stroke-width="9" stroke-linecap="round" stroke-dasharray="${(C*rem/rest.total).toFixed(1)} ${C.toFixed(1)}" transform="rotate(-90 70 70)"/></svg>
        <div style="position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center"><span class="label" id="restLbl" style="color:${rem>0?'var(--violet)':'var(--mint)'}">${rem>0?'Rest':'Go'}</span><span id="restClock" style="font-size:36px;font-weight:800;font-variant-numeric:tabular-nums">${mmss(Math.ceil(rem))}</span></div></div>
      <div class="grow" style="display:flex;flex-direction:column;gap:8px">${rest.next?`<div><div class="label" style="${rest.lbl==='Logged'?'color:var(--mint)':''}">${rest.lbl}</div><div class="name" style="margin-top:3px">${esc(rest.next)}</div></div>`:''}
        <div style="display:flex;gap:8px"><button class="btn sm" id="rest30">+30 s</button><button class="btn sm" id="restSkip">Skip</button></div></div></div>`;
  } else {
    media=`<div style="display:flex;gap:14px;height:100%">${s?`<img src="${s}" alt="${esc(cleanN(ex.n))}" style="width:112px;height:100%;object-fit:cover;border-radius:16px;flex:none;background:#1b1e28">`:''}
      <div class="grow" style="display:flex;flex-direction:column;gap:6px;min-width:0"><div class="label">Form focus</div><div style="font-size:14px;line-height:1.4;color:#E6E8EE">${cueOf(ex.id)}</div>
      ${plate?`<div style="margin-top:auto;border-top:1px solid var(--line);padding-top:8px"><div class="label">Plate math</div><div class="name" style="font-size:14px;margin-top:3px">${plate}</div></div>`:''}</div></div>`;
  }
  const dots=[...Array(setCount).keys()].map(i=>{const d=i<reps.length, c=i===cur&&!exDone||editSet===i;
    return `<button data-eset="${i}" ${d?'':'disabled'} style="background:none;border:0;display:flex;flex-direction:column;align-items:center;gap:4px;flex:1;color:${c?'#fff':'var(--muted)'};opacity:1">
      <span style="width:30px;height:30px;border-radius:15px;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:13px;${d&&!c?'background:var(--violet);color:#0E1018':c?'border:2px solid var(--violet)':'border:2px solid rgba(255,255,255,.2)'}">${d&&!c?`<span style="width:15px;height:15px;display:block">${I.check}</span>`:i+1}</span>
      <span class="small" style="color:inherit">${d?`${w} × ${repLbl(ex,reps[i])}`:`${w} × ${repLbl(ex,orig.r)}`}</span></button>`}).join('');
  const el=Math.floor((Date.now()-(A.started||Date.now()))/1000);
  return `<header class="hero short" style="height:calc(118px + var(--safeT))"><div class="topbar">${backBtn('liftBack','Back to Today')}
      <div style="text-align:center"><div class="name">${PLAN[A.day].name}</div><div class="small" id="elapsed">${mmss(el)} elapsed</div></div>
      <button class="gbtn" id="liftMenu" aria-label="Workout options"><span style="font-weight:800;letter-spacing:2px">···</span></button></div>
      <div class="htext" style="flex-direction:column;align-items:stretch;gap:8px"><div class="eyebrow">${isBonus?`Bonus ${pos}`:`Lift ${pos} of ${reqL.length}`}${A.lowEnergy?' · lighter day':''}</div><div class="dots">${segs}</div></div></header>
   <main class="wrap" style="gap:10px;margin-top:10px">
    <div><div style="font-size:26px;font-weight:800;letter-spacing:-.02em;line-height:1.1">${esc(cleanN(ex.n))}</div>
      <div class="meta" style="font-size:14px">${setCount} sets × ${repLbl(ex,orig.r)}${perLeg(ex)}${idx===0&&!isBonus?' · heavy first':''}${ex!==orig?' · swapped':''}</div></div>
    ${progCard}
    ${orig.injured?`<div class="warnbox">On hold for your injury flag. Go light or swap it.</div>`:''}
    <section class="card tight" style="height:148px">${media}</section>
    <div style="display:grid;grid-template-columns:1fr 1.4fr;gap:8px"><button class="btn sm" data-yt="${ex.id}">${I.play.replace('<svg','<svg width="14" height="14"')}Form video</button>
      ${(ALT_OF[orig.id]||[]).length?`<button class="btn sm" id="swapBtn">${I.swap.replace('<svg','<svg width="16" height="16"')}Swap exercise</button>`:'<span></span>'}</div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-top:2px"><span class="label">${exDone&&editSet==null?'All sets logged':`Set ${cur+1} of ${setCount}`}${editSet!=null?' · editing':''}</span>
      ${reqDone&&!allDone?`<button class="link" id="finishLink" style="padding:0;color:var(--mint)">Main lifts done · Finish</button>`:''}</div>
    <div style="display:flex;margin-top:-4px">${dots}</div>
    <div class="grid2">
      <div class="card tight" style="padding:10px"><div class="label" style="text-align:center">Weight · lb</div><div style="display:flex;align-items:center;justify-content:space-between;margin-top:4px">
        <button class="stp" data-st="w|-1" aria-label="Less weight">−</button><b id="vW" class="bignum">${w}</b><button class="stp" data-st="w|1" aria-label="More weight">+</button></div></div>
      <div class="card tight" style="padding:10px"><div class="label" style="text-align:center">${isSec(ex)?'Seconds':'Reps'}</div><div style="display:flex;align-items:center;justify-content:space-between;margin-top:4px">
        <button class="stp" data-st="r|-1" aria-label="Fewer">−</button><b id="vR" class="bignum">${rv}</b><button class="stp" data-st="r|1" aria-label="More">+</button></div></div></div>
   </main>
   <div class="dock">${allDone||(exDone&&editSet==null&&reqDone&&!L.some(x=>!isLogged(x)))
      ?`<button class="btn violet" id="endBtn">Finish workout</button>`
      :exDone&&editSet==null?`<button class="btn violet" id="nextLift">${nextLabel(L,idx,reqDone)}</button>`
      :`<button class="btn violet" id="logSet">${editSet!=null?`Save set ${editSet+1}`:`Log set ${cur+1}`}</button>`}</div>`;
}
function nextLabel(L,idx,reqDone){
  const n=L.findIndex((x,i)=>i>idx&&!isLogged(x)), any=L.findIndex(x=>!isLogged(x));
  const t=n>=0?n:any;
  if(t>=0)return `Next: ${esc(cleanN(shownEx(L[t]).n))}`;
  return 'Finish workout';
}
function plateTxt(ex,total){
  if(total<=ex.bar)return `${ex.bar} lb bar only`;
  let side=(total-ex.bar)/2,out=[];
  PLATES.forEach(p=>{while(side>=p-.001){out.push(p);side=+(side-p).toFixed(2)}});
  return `${ex.bar} lb bar + ${out.join(' + ')} / side`;
}
function logSet(){
  const A=DB.active, L=liftList(), idx=curIdx(), orig=L[idx], ex=shownEx(orig);
  const setCount=A.lowEnergy?2:(orig.sets||3);
  const r=+$('#vR').textContent, w=+$('#vW').textContent;
  const entry=A.entries[ex.id];
  const p=A.prog[ex.id]||(entry?{w:entry.w,reps:[...entry.reps]}:{w,reps:[]});
  p.w=w;
  const wasEdit=editSet!=null;
  if(wasEdit){p.reps[editSet]=r; editSet=null;} else p.reps.push(r);
  A.prog[ex.id]=p;
  if(p.reps.length>=setCount){
    A.entries[ex.id]={w:p.w,reps:p.reps.slice(0,setCount)};
    if(!wasEdit){
      const n=L.findIndex((x,i)=>i>idx&&!isLogged(x)), next=n>=0?L[n]:L.find(x=>!isLogged(x));
      const reqDone=requiredItems(A.day).every(isLogged);
      if(next&&!(reqDone&&!requiredItems(A.day).some(x=>x.id===next.id)&&false)){
        startRest(restFor(orig),`${cleanN(ex.n)} · ${p.reps.map(r=>repLbl(ex,r)).join('/')}`,'Logged');
        A.idx=L.indexOf(next);
      }
    }
  } else if(!wasEdit) startRest(restFor(orig),`Set ${p.reps.length+1} of ${setCount}`);
  save(); render();
}
const restFor=ex=>ex.key?120:isOptionalBlock((PLAN[DB.active.day].blocks.find(b=>b.items.includes(ex))||{}).t)?60:90;
function startRest(sec,next,lbl){
  rest={endAt:Date.now()+sec*1000,total:sec,next,lbl:lbl||'Up next',beeped:false};
  ensureLiftTick();
}
function renderRest(){ const R=$('#restbar'); if(R)R.hidden=true; if(scr==='lift')ensureLiftTick(); }
let liftTick=null;
function ensureLiftTick(){ if(!liftTick)liftTick=setInterval(tickLift,500); }
function tickLift(){
  if(scr!=='lift'||!DB.active){clearInterval(liftTick);liftTick=null;return}
  const e=$('#elapsed'); if(e)e.textContent=mmss(Math.floor((Date.now()-(DB.active.started||Date.now()))/1000))+' elapsed';
  if(!rest)return;
  const rem=(rest.endAt-Date.now())/1000;
  if(rem<=0&&!rest.beeped){rest.beeped=true;cue();render();return}
  if(rem<-15){rest=null;render();return}
  const c=$('#restClock'); if(c)c.textContent=mmss(Math.ceil(Math.max(0,rem)));
  const a=$('#restArc'); if(a&&rem>0){const C=2*Math.PI*62;a.setAttribute('stroke-dasharray',`${(C*rem/rest.total).toFixed(1)} ${C.toFixed(1)}`)}
}
function liftMenu(){
  const A=DB.active;
  openSheet(`<div class="title2" style="font-size:20px">${PLAN[A.day].name}</div>
    <button class="opt" data-menu="finish"><span class="grow name">Finish workout</span>${I.chev}</button>
    <button class="opt" data-menu="low"><span class="grow"><span class="name" style="display:block">Lighter day ${A.lowEnergy?'· on':''}</span><span class="meta">85% weight, 2 sets, weights don't go up</span></span>${I.chev}</button>
    <button class="opt" data-menu="discard" style="color:#FF8A70"><span class="grow name">Discard workout</span></button>`);
}
function swapSheet(){
  const A=DB.active, L=liftList(), idx=curIdx(), orig=L[idx], reqIds=requiredItems(A.day).map(x=>x.id);
  const pos=reqIds.indexOf(orig.id);
  const opts=[orig].concat(ALT_OF[orig.id]||[]), cur=(A.swaps[orig.id])||orig.id;
  openSheet(`<div class="label">${pos>=0?`Lift ${pos+1} of ${reqIds.length}`:'Bonus'} · Swap</div><div class="title2" style="font-size:20px">Machine busy?</div>
    <p class="note">Same movement, different equipment. Each option keeps its own weight history.</p>
    ${opts.map(o=>{const w=A.lowEnergy?loEnergyW(o,wOf(o)):wOf(o), s=imgOf(o.id);
      return `<button class="opt ${cur===o.id?'on':''}" data-swapto="${o.id===orig.id?'':o.id}">${s?`<img class="thumb" src="${s}" alt="">`:'<div class="thumb"></div>'}
      <div class="grow"><div class="name">${esc(cleanN(o.n))}</div><div class="meta">${o.id===orig.id?'Planned · ':''}${wLbl(o,w)}</div></div>${cur===o.id?`<span style="color:var(--violet);width:22px">${I.check}</span>`:''}</button>`}).join('')}`);
}
function endSession(){
  const A=DB.active, ids=Object.keys(A.entries);
  if(!ids.length){ if(confirm('Nothing logged yet. Discard this workout?')){DB.active=null;rest=null;save();go('today')} return }
  const req=requiredItems(A.day), missing=req.filter(x=>!isLogged(x)).length;
  if(missing&&!confirm(`${missing} main lift${missing>1?'s':''} not logged. Finish anyway?`))return;
  const ups=[], holds=[], prevW={};
  ids.forEach(id=>{
    const ex=exById(id), e=A.entries[id]; if(!ex)return;
    prevW[id]=e.w;
    const hit=e.reps.length>0&&e.reps.every(r=>r>=ex.r);
    const held=(DB.holds&&DB.holds[id])||A.lowEnergy;
    DB.next[id]=(hit&&ex.inc&&!held)?progressedWeight(ex,e.w):e.w;
    if(hit&&ex.inc&&!held)ups.push(id); else holds.push(id);
  });
  let vol=0; ids.forEach(id=>{vol+=volOf(id,A.entries[id].w,A.entries[id].reps)});
  const min=Math.max(1,Math.round((Date.now()-(A.started||Date.now()))/60000));
  const sess={date:A.date,day:A.day,vol:Math.round(vol),entries:A.entries,lowEnergy:!!A.lowEnergy,min,swaps:A.swaps};
  DB.history.push(sess);
  celebration={idx:DB.history.length-1,ups,holds,low:!!A.lowEnergy};
  DB.active=null; rest=null; clearInterval(restTick);
  save(); go('done');
}

/* ===================== WORKOUT COMPLETE ===================== */
function doneView(){
  const c=celebration, s=DB.history[c.idx]; if(!s){scr='today';return todayView()}
  const req=requiredItems(s.day), reqIds=new Set(req.map(x=>x.id));
  const sw=s.swaps||{}, origOf=id=>Object.keys(sw).find(k=>sw[k]===id)||id;
  const wi=warmIds(s.day), mainN=Object.keys(s.entries).filter(id=>reqIds.has(origOf(id))).length, bonusN=Object.keys(s.entries).filter(id=>!wi.has(id)).length-mainN;
  const st=weekStats(mondayOf(s.date));
  const prev=[...DB.history].slice(0,c.idx).reverse().find(h=>h.day===s.day);
  const rows=Object.keys(s.entries).filter(id=>{const e=exById(id);return e&&!e.bw||s.entries[id].w}).map(id=>{
    const ex=exById(id)||{n:id}, e=s.entries[id], up=c.ups.includes(id), nx=DB.next[id], im=imgOf(id);
    const need=!up&&ex.r?e.reps.reduce((a,r)=>a+Math.max(0,ex.r-r),0):0;
    return `<div class="row">${im?`<img class="thumb" src="${im}" alt="">`:'<div class="thumb"></div>'}<div class="grow"><div class="name">${esc(cleanN(ex.n))}</div>
      <div class="meta">${e.reps.map(r=>repLbl(ex,r)).join(' · ')} at ${e.w} lb</div>
      ${!up&&!c.low&&need>0&&ex.inc?`<div style="font-size:13px;color:var(--amber);margin-top:3px">${need} more rep${need>1?'s':''} unlocks ${progressedWeight(ex,e.w)}</div>`:''}</div>
      ${up?`<span class="chip up">${I.up}${nx} lb</span>`:`<span class="chip hold">Hold ${e.w}</span>`}</div>`}).join('');
  let cmp='';
  if(prev){
    const ids=Object.keys(s.entries).filter(id=>prev.entries[id]);
    if(ids.length){
      const v=id=>volOf(id,s.entries[id].w,s.entries[id].reps), pv=id=>volOf(id,prev.entries[id].w,prev.entries[id].reps);
      const tot=ids.reduce((a,id)=>a+v(id),0), ptot=ids.reduce((a,id)=>a+pv(id),0), pct=ptot?Math.round((tot-ptot)/ptot*100):0;
      const mx=Math.max(...ids.map(id=>Math.max(v(id),pv(id))))||1;
      cmp=`<section class="card"><div class="rowh"><span class="label">vs last ${PLAN[s.day].name} · ${fmtD(prev.date,{month:'short',day:'numeric'})}</span><span style="font-size:22px;font-weight:800;color:${pct>=0?'var(--mint)':'var(--amber)'}">${pct>=0?'+':''}${pct}%</span></div>
       <div style="display:flex;flex-direction:column;gap:12px;margin-top:12px">${ids.map(id=>{const a=v(id),b=pv(id),p=b?Math.round((a-b)/b*100):0;
        return `<div><div class="rowh" style="font-size:14px"><span>${esc(cleanN(exById(id).n))}</span><span class="muted">${nf(a)} lb · ${p>=0?'+':''}${p}%</span></div>
        <div style="height:10px;border-radius:5px;background:rgba(255,255,255,.08);position:relative;overflow:hidden;margin-top:6px"><i style="position:absolute;left:0;top:0;bottom:0;border-radius:5px;width:${a/mx*100}%;background:var(--violet)"></i><i style="position:absolute;left:0;top:0;bottom:0;border-radius:5px;width:${b/mx*100}%;background:rgba(255,255,255,.28)"></i></div></div>`}).join('')}</div>
       <div class="small" style="margin-top:12px;display:flex;gap:14px"><span><i style="display:inline-block;width:10px;height:10px;border-radius:3px;background:rgba(255,255,255,.28);margin-right:6px"></i>Last time</span><span><i style="display:inline-block;width:10px;height:10px;border-radius:3px;background:var(--violet);margin-right:6px"></i>Today</span></div></section>`;
    }
  }
  const jumps=cardioOn(s.date,'jumps');
  const bone=jumps?`<section class="card" style="display:flex;align-items:center;gap:14px"><div style="display:flex;flex:none"><img class="thumb" src="img/pogo.jpg" alt="" style="width:48px;height:48px;border:2px solid var(--bg)"><img class="thumb" src="img/box_jump.jpg" alt="" style="width:48px;height:48px;margin-left:-14px;border:2px solid var(--bg)"></div>
    <div class="grow"><div class="label" style="color:var(--mint)">Bone · impact</div><div class="name" style="margin-top:3px">${st.b*45} landings this week</div><div class="meta">${st.b>=st.bt?'Both jump days done. Full weekly dose.':`${st.bt-st.b} more jump day to go.`}</div></div></section>`:'';
  const lifts=c.ups.length;
  return hero({cls:'tall',right:'',left:'',eyebrow:`${PLAN[s.day].name} · ${fmtD(s.date)}`,title:'Workout complete',
      sub:c.low?'Lighter day logged. Weights stay put.':lifts?`Nice work, ${esc(profile.name)}. ${lifts} lift${lifts>1?'s':''} go up next time.`:`Logged, ${esc(profile.name)}. Same weights next time.`,
      badge:`<div style="width:64px;height:64px;border-radius:32px;flex:none;background:linear-gradient(160deg,#B3A6FF,#7C6CF0);box-shadow:0 0 0 6px rgba(156,140,255,.18),0 10px 30px rgba(124,108,240,.55);display:flex;align-items:center;justify-content:center;color:#fff"><span style="width:30px;height:30px;display:block">${I.check}</span></div>`})
   +`<main class="wrap"><section class="card stats"><div><span class="big">${s.min||'—'}</span><span class="small">Minutes</span></div>
     <div><span class="big">${mainN}/${req.length}${bonusN?` <span style="font-size:15px;color:var(--violet)">+${bonusN}</span>`:''}</span><span class="small">Lifts${bonusN?' · bonus':''}</span></div>
     <div><span class="big">${nf(s.vol||0)}</span><span class="small">lb moved</span></div></section>
    ${ringsCard(st,ringsLine(st))}
    ${rows?`<section class="card"><span class="label">Next time</span><div style="margin-top:6px">${rows}</div></section>`:''}
    ${cmp}${bone}${nextCard(s.date)}</main>
    <div class="dock"><button class="btn" data-wo="pick">Add cardio</button><button class="btn primary w2" id="doneBtn">Done</button></div>`;
}
function ringsLine(st){
  if(st.all)return 'All three layers done for the week.';
  const left=[];
  if(!st.closed[0])left.push(`${st.mt-st.m} more lift${st.mt-st.m>1?'s':''}`);
  if(!st.closed[1])left.push(`${st.ht-st.h} heart session${st.ht-st.h>1?'s':''}`);
  if(!st.closed[2])left.push(`${st.bt-st.b} jump day`);
  return `Still to go: ${left.join(', ')}.`;
}
function nextCard(fromDate){
  const t=fromDate, mon=mondayOf(t), wp=weekPlan(), slots=liftSlots(mon);
  for(let i=1;i<=7;i++){
    const d=addDays(t,i), w=wdOf(d), s=wp[w]; if(s==='rest')continue;
    let name, sub, col;
    if(s==='lift'){const sl=d<addDays(mon,7)?slots[w]:null, day=sl&&sl.day?sl.day:nextDay(); name=PLAN[day].name; sub=`${requiredItems(day).length} main lifts · ~${minutesFor(day)} min`; col='m'}
    else {if(s!=='office'&&weekDates(mondayOf(d)).some(x=>cardioOn(x,CTYPE[s])))continue; name=SLOT_NAME[s]; sub=s==='office'?'10,000 steps':s==='vo2'?`~${rcMinutes(4)} min on the treadmill`:'Easy pace'; col='h'}
    const C=KC[col];
    return `<section class="card" style="display:flex;align-items:center;gap:14px;border-color:${C}55;background:linear-gradient(135deg,${C}26,${C}0d)">
      <div class="ico" style="width:52px;height:52px;border-radius:16px;background:${C}33;color:${C}">${col==='m'?I.dumbbell:I.heart}</div>
      <div class="grow"><div class="label" style="color:${C}">Next · ${i===1?'Tomorrow':WD_L[w]}</div><div class="name" style="margin-top:3px">${name}</div><div class="meta">${sub}</div></div></section>`;
  }
  return '';
}

/* ===================== 4x4 ===================== */
function vo2View(){
  const n=vo2N||rcDefaultIntervals(), c=(DB.cardio||[]).filter(x=>x.type==='4x4').length, hr=rcHR();
  const ramp=c<3?`Ramp-up session ${c+1} of 3: 3 intervals at the low end of the range.`:'Full 4×4. Add speed or incline when the last interval feels easier than the first.';
  const step=(t,a,b)=>`<div class="row"><div class="chip n" style="margin:0;min-width:64px;justify-content:center">${t}</div><div class="grow"><div class="name">${a}</div><div class="meta">${b}</div></div></div>`;
  return hero({left:backBtn(),title:'4×4 intervals',eyebrow:'Heart · VO2 max',cls:'ex',img:'img/treadmill.jpg',sub:ramp})
   +`<main class="wrap"><section class="card">${step('10 min','Warm-up','Treadmill 5 km/h at 5% incline.')}
     ${step('4 min','Hard','Fast walk at 10–12% incline, or jog 9–10 km/h. By minute 2 you can only say a few words.')}
     ${step('3 min','Easy','Drop to 5 km/h, 0–3% incline. Breathe.')}
     ${step(`${n} ×`,'Repeat hard + easy','The timer beeps at every change.')}
     ${step('5 min','Cool-down','Slow walk.')}</section>
    <section class="card tight">${hr?`<div class="rowh" style="padding:4px"><span class="name">Hard target</span><span class="name" style="color:var(--coral)">${hr.hard[0]}–${hr.hard[1]} bpm</span></div><div class="note" style="padding:0 4px">Check it on your watch. Easy phases: under ${hr.z2[1]} bpm.</div>`
      :`<div class="note" style="padding:4px">Set your age in Settings to see heart-rate targets.</div>`}</section>
    <div class="seg" role="group" aria-label="Intervals"><button data-n="3" class="${n===3?'on':''}">3 intervals · ${rcMinutes(3)} min</button><button data-n="4" class="${n===4?'on':''}">4 intervals · ${rcMinutes(4)} min</button></div>
    <button class="link" id="logVo2">Already did it? Log without the timer</button></main>
    <div class="dock"><button class="btn coral" id="startTimer">Start timer</button></div>`;
}
function timerView(){
  if(!timer)return vo2View();
  const ph=timer.phases[timer.idx], rem=timer.paused?timer.remain:(timer.endAt-Date.now())/1000, nxt=timer.phases[timer.idx+1], hr=rcHR();
  const hard=ph.k==='hard', elapsed=(Date.now()-timer.started-(timer.pausedMs||0))/1000;
  const label=hard?ph.label.replace(/Interval (\d+) of (\d+) · hard/,'Hard · $1 of $2'):ph.label.replace(/ · easy/,'');
  const set=hard?'10–12% incline · fast walk or 9–10 km/h':/Warm/.test(ph.label)?'5 km/h · 5% incline':/Cool/.test(ph.label)?'Slow walk':'5 km/h · 0–3% incline';
  const segs=timer.phases.map((p,i)=>`<i class="${p.k} ${i<timer.idx?'done':''}" style="flex:${p.sec}">${i===timer.idx?`<em id="tmrFill" style="width:${Math.min(100,(1-rem/p.sec)*100)}%"></em>`:''}</i>`).join('');
  return `<div class="tmr ${hard?'hard':''}" id="tmr">
    <div class="rowh"><span class="label" style="color:${hard?'var(--coral)':'var(--muted)'}">Heart · 4×4</span><span class="label" id="tmrEl">${mmss(elapsed)} elapsed</span></div>
    <img src="img/treadmill.jpg" alt="" style="width:100%;height:150px;object-fit:cover;object-position:50% 30%;border-radius:22px;opacity:${hard?1:.6}">
    <div><div style="font-size:34px;font-weight:800;letter-spacing:-.02em;color:${hard?'var(--coral)':'#fff'}">${label}</div>
      <div class="p" style="margin-top:4px">${hard?'You should only manage a few words.':'Easy. Breathe and recover.'}</div></div>
    <div class="tclock" id="tmrClock" style="text-align:center;margin:10px 0">${mmss(Math.ceil(rem))}</div>
    <div class="grid2"><div class="card tight"><div class="label">Treadmill</div><div class="name" style="margin-top:4px">${set}</div></div>
      <div class="card tight"><div class="label">Target</div><div class="name" style="margin-top:4px;color:${hard?'var(--coral)':'#fff'}">${hr?(hard?`${hr.hard[0]}–${hr.hard[1]} bpm`:`under ${hr.z2[1]} bpm`):'Set age in Settings'}</div></div></div>
    <div class="segs">${segs}</div>
    <div class="small">${nxt?`Next: ${nxt.label.replace(/ · easy| · hard/,'')} · ${mmss(nxt.sec)}`:'Last part'}</div>
    <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px;margin-top:auto">
      <button class="btn" id="tmrPause">${timer.paused?'Resume':'Pause'}</button><button class="btn" id="tmrSkip">Skip</button><button class="btn ${hard?'coral':''}" id="tmrStop">End</button></div></div>`;
}
function startTimer(n){
  timer={n,phases:rcPhases(n),idx:0,started:Date.now(),paused:false,pausedMs:0};
  timer.endAt=Date.now()+timer.phases[0].sec*1000;
  cue(); lockScreen(true); clearInterval(timerTick); timerTick=setInterval(tickTimer,250); go('timer');
}
function finishTimer(completed){
  clearInterval(timerTick); timerTick=null; lockScreen(false);
  const t=timer; timer=null;
  if(completed){ cue(); const min=Math.round((Date.now()-t.started-(t.pausedMs||0))/60000);
    logCardio('4x4',{intervals:t.n,min}); vo2Done={intervals:t.n,min,date:today()}; go('vo2done'); }
  else go('today');
}
function tickTimer(){
  if(!timer||timer.paused)return;
  let changed=false;
  while(timer&&Date.now()>=timer.endAt){
    if(timer.idx>=timer.phases.length-1){finishTimer(true);return}
    timer.idx++; timer.endAt+=timer.phases[timer.idx].sec*1000; changed=true;
  }
  if(scr!=='timer')return;
  if(changed){cue();render();return}
  const ph=timer.phases[timer.idx], rem=(timer.endAt-Date.now())/1000;
  const c=$('#tmrClock'); if(c)c.textContent=mmss(Math.ceil(rem));
  const f=$('#tmrFill'); if(f)f.style.width=Math.min(100,(1-rem/ph.sec)*100)+'%';
  const e=$('#tmrEl'); if(e)e.textContent=mmss((Date.now()-timer.started-(timer.pausedMs||0))/1000)+' elapsed';
}
document.addEventListener('visibilitychange',()=>{ if(!document.hidden&&timer&&!timer.paused){lockScreen(true);tickTimer()} });
function vo2DoneView(){
  const v=vo2Done||{intervals:4,min:rcMinutes(4),date:today()}, st=weekStats(mondayOf(v.date));
  return hero({cls:'tall',left:'',eyebrow:`4×4 intervals · ${fmtD(v.date)}`,title:'Session complete',sub:st.all?'All 3 rings closed this week.':st.closed[1]?'Heart ring closed for the week.':'Heart work logged.',
    badge:`<div style="width:64px;height:64px;border-radius:32px;flex:none;background:linear-gradient(160deg,#FF9A80,#F0583A);box-shadow:0 0 0 6px rgba(255,107,74,.18),0 10px 30px rgba(240,88,58,.5);display:flex;align-items:center;justify-content:center;color:#fff"><span style="width:30px;height:30px;display:block">${I.check}</span></div>`})
   +`<main class="wrap"><section class="card stats"><div><span class="big">${v.min}</span><span class="small">Minutes</span></div><div><span class="big">${v.intervals}</span><span class="small">Hard intervals</span></div><div><span class="big">${v.intervals*4}</span><span class="small">Hard minutes</span></div></section>
    ${ringsCard(st,st.all?'Muscle, heart and bone: the full week is in.':ringsLine(st))}
    <section class="card"><p class="p" style="margin:0">${(DB.cardio||[]).filter(x=>x.type==='4x4').length<3?'Ramp-up phase: keep it at 3 intervals until you have 3 sessions in.':'Next time, add a little speed or incline if the last interval felt easier than the first.'}</p></section>
    ${nextCard(v.date)}</main><div class="dock"><button class="btn primary" id="doneBtn">Done</button></div>`;
}

/* ===================== CARDIO LOGGING ===================== */
function logCardio(type,extra,date){
  date=date||today();
  DB.cardio=(DB.cardio||[]).filter(c=>!(c.date===date&&c.type===type));
  DB.cardio.push(Object.assign({date,type},extra||{}));
  DB.cardio.sort((a,b)=>a.date<b.date?-1:a.date>b.date?1:0);
  save();
}

/* ===================== PROGRESS ===================== */
function topSets(id,weeks){
  const from=addDays(mondayOf(today()),-7*(weeks-1));
  return DB.history.filter(h=>h.date>=from&&h.entries[id]).map(h=>({d:h.date,v:h.entries[id].w}));
}
function lineSVG(pts,col,opt){
  opt=opt||{}; const W=340,H=150,pl=34,pr=12,pt=22,pb=24;
  if(!pts.length)return `<div class="empty">No data yet.</div>`;
  const ys=pts.map(p=>p.y), lo=Math.min(...ys), hi=Math.max(...ys), pad=Math.max(5,(hi-lo)*.2);
  const y0=Math.floor((lo-pad)/5)*5, y1=Math.ceil((hi+pad)/5)*5, n=pts.length;
  const X=i=>pl+(n===1?(W-pl-pr)/2:i*(W-pl-pr)/(n-1)), Y=v=>pt+(1-(v-y0)/(y1-y0||1))*(H-pt-pb);
  const ticks=[y0,Math.round((y0+y1)/2),y1];
  const path=pts.map((p,i)=>`${i?'L':'M'}${X(i).toFixed(1)} ${Y(p.y).toFixed(1)}`).join(' ');
  const area=`${path} L${X(n-1).toFixed(1)} ${H-pb} L${X(0).toFixed(1)} ${H-pb} Z`;
  const lblEvery=Math.ceil(n/6);
  return `<svg viewBox="0 0 ${W} ${H}" width="100%" role="img" aria-label="${opt.aria||''}" style="margin-top:8px;overflow:visible">
   ${ticks.map(t=>`<line x1="${pl}" x2="${W-pr}" y1="${Y(t)}" y2="${Y(t)}" stroke="rgba(255,255,255,.08)"/><text x="${pl-6}" y="${Y(t)+4}" fill="#A9AEBD" font-size="11" text-anchor="end">${t}</text>`).join('')}
   <path d="${area}" fill="${col}" fill-opacity=".14"/><path d="${path}" fill="none" stroke="${col}" stroke-width="2.5" stroke-linejoin="round"/>
   ${pts.map((p,i)=>`<circle cx="${X(i)}" cy="${Y(p.y)}" r="${i===n-1?5:3.5}" fill="${col}"/>${(i%lblEvery===0||i===n-1)?`<text x="${X(i)}" y="${H-6}" fill="#A9AEBD" font-size="10.5" text-anchor="middle">${p.l}</text>`:''}`).join('')}
   <text x="${X(0)}" y="${Y(pts[0].y)-9}" fill="#fff" font-size="12" font-weight="700" text-anchor="middle">${pts[0].y}</text>
   ${n>1?`<text x="${X(n-1)}" y="${Y(pts[n-1].y)-10}" fill="#fff" font-size="13" font-weight="800" text-anchor="middle">${pts[n-1].y}</text>`:''}</svg>`;
}
function barSVG(vals,labels,col,fmt,cur){
  const W=160,H=110,pb=18,pt=16, mx=Math.max(1,...vals), n=vals.length, bw=(W/n)*.62;
  return `<svg viewBox="0 0 ${W} ${H}" width="100%" style="margin-top:8px;overflow:visible" role="img">
   ${vals.map((v,i)=>{const x=i*W/n+(W/n-bw)/2, h=v/mx*(H-pb-pt);return `<rect x="${x}" y="${H-pb-h}" width="${bw}" height="${Math.max(h,v?2:0)}" rx="3" fill="${col}" fill-opacity="${i===cur?.45:1}"/>
     ${v?`<text x="${x+bw/2}" y="${H-pb-h-4}" fill="#fff" font-size="9.5" font-weight="700" text-anchor="middle">${fmt(v)}</text>`:''}
     <text x="${x+bw/2}" y="${H-5}" fill="#A9AEBD" font-size="8.5" text-anchor="middle">${labels[i]}</text>`}).join('')}</svg>`;
}
function progressView(){
  const keys=DAYS().flatMap(d=>requiredItems(d)).filter(x=>x.key&&!x.bw);
  if(!progLift||!keys.some(k=>k.id===progLift))progLift=(keys.find(k=>/rdl/.test(k.id))||keys[0]||{}).id;
  const weeks=progRange, ts=topSets(progLift,weeks);
  const byWeek={}; ts.forEach(p=>{const m=mondayOf(p.d); byWeek[m]=Math.max(byWeek[m]||0,p.v)});
  const pts=weeks<=8?Object.keys(byWeek).sort().map(m=>({l:'W'+(Math.round(dayDiff(addDays(mondayOf(today()),-7*(weeks-1)),m)/7)+1),y:byWeek[m]}))
    :Object.keys(byWeek).sort().map(m=>({l:fmtD(m,{month:'short'}),y:byWeek[m]}));
  const ex=exById(progLift)||{n:''}, first=pts[0], last=pts[pts.length-1], pct=first&&last&&first.y?Math.round((last.y-first.y)/first.y*100):0;
  const mon=mondayOf(today()), W8=[...Array(8).keys()].map(i=>addDays(mon,-7*(7-i)));
  const stats=W8.map(m=>weekStats(m));
  const cardio=W8.map(m=>{const ds=weekDates(m);return (DB.cardio||[]).filter(c=>ds.includes(c.date)&&c.type!=='jumps').length});
  const steps=W8.map(m=>{const ds=weekDates(m), s=(DB.cardio||[]).filter(c=>ds.includes(c.date)&&c.type==='office'&&c.steps);return s.length?Math.round(s.reduce((a,c)=>a+c.steps,0)/s.length):0});
  const lastSteps=[...steps].reverse().find(Boolean)||0;
  const wl=['W1','W2','W3','W4','W5','W6','W7','W8'];
  const waist=(DB.waist||[]).slice(-8);
  const sk=streak();
  return hero({title:'Progress',sub:'What the last weeks added up to.'})
   +`<main class="wrap">
    <section class="card"><div class="rowh"><div><div class="name">${esc(cleanN(ex.n))}</div><div class="meta">Top set, lb</div></div>
      ${pts.length>1?`<div style="text-align:right"><div class="big" style="color:var(--violet)">${pct>=0?'+':''}${pct}%</div><div class="small">${first.y} → ${last.y} lb</div></div>`:''}</div>
      <div style="display:flex;gap:6px;overflow-x:auto;margin-top:10px;padding-bottom:2px">${keys.map(k=>`<button class="pill" data-plift="${k.id}" style="border:0;white-space:nowrap;${k.id===progLift?'background:#F4F5F8;color:#0E1018':''}">${esc(cleanN(k.n))}</button>`).join('')}</div>
      ${lineSVG(pts,KC.m,{aria:'Top set trend'})}
      <div class="seg" style="margin-top:8px">${[[8,'8W'],[26,'6M'],[52,'1Y']].map(([w,l])=>`<button data-range="${w}" class="${progRange===w?'on':''}">${l}</button>`).join('')}</div></section>
    <section class="card"><div class="rowh"><div><div class="name">Weekly rings</div><div class="meta">Muscle, Heart, Bone</div></div></div>
      <div style="display:grid;grid-template-columns:repeat(8,1fr);gap:4px;margin-top:14px;text-align:center">${stats.map((s,i)=>`<div><div style="display:flex;flex-direction:column;align-items:center;gap:4px">${['m','h','b'].map((k,j)=>`<i style="width:12px;height:12px;border-radius:6px;display:block;background:${s.closed[j]?KC[k]:'rgba(255,255,255,.12)'}"></i>`).join('')}</div><div class="small" style="margin-top:6px;${i===7?'color:#fff;font-weight:700':''}">${i===7?'Now':wl[i]}</div></div>`).join('')}</div></section>
    <div class="grid2"><section class="card tight"><div class="name" style="font-size:15px">Cardio</div><div class="meta">sessions / week</div>${barSVG(cardio,wl.map(x=>x.slice(1)),KC.h,v=>v,7)}</section>
      <section class="card tight"><div class="rowh"><div><div class="name" style="font-size:15px">Steps</div><div class="meta">avg / office day</div></div></div>
      <div class="big" style="font-size:20px;margin-top:4px">${lastSteps?nf(lastSteps):'—'}</div>${barSVG(steps,wl.map(x=>x.slice(1)),KC.h,v=>(v/1000).toFixed(1)+'k',7)}</section></div>
    <section class="card"><div class="rowh"><div><div class="name">Waist</div><div class="meta">cm · the honest recomp number</div></div>
      ${waist.length?`<div class="big">${waist[waist.length-1].cm}</div>`:''}</div>
      ${waist.length>1?lineSVG(waist.map(w=>({l:fmtD(w.date,{month:'short',day:'numeric'}),y:w.cm})),'#C9CED8',{aria:'Waist trend'}):`<p class="note" style="margin:10px 0 0">Measure at the belly button, relaxed, same time of day. Every 2 weeks is enough.</p>`}
      <div style="display:flex;gap:8px;margin-top:12px"><label class="step" style="flex:1;padding:4px 10px"><span class="sr">Waist in cm</span><input id="waistIn" type="number" inputmode="decimal" step="0.5" placeholder="cm" style="width:100%;font-size:20px"></label>
      <button class="btn sm" id="addWaist" style="width:auto;padding:0 18px;height:auto">Add measurement</button></div></section>
    <section class="card"><div class="rowh"><div><div class="name">Current streak</div><div class="meta">Weeks with all 3 rings closed</div></div><div class="big">${sk} week${sk===1?'':'s'}</div></div>
      <div style="display:flex;justify-content:space-between;margin-top:14px">${stats.map((s,i)=>i===7?`<span title="In progress" style="width:26px;height:26px;border-radius:13px;border:2px dashed rgba(255,255,255,.4)"></span>`
        :`<span style="width:26px;height:26px;border-radius:13px;display:flex;align-items:center;justify-content:center;${s.all?'background:#F4F5F8;color:#0E1018':'border:2px solid rgba(255,255,255,.15)'}">${s.all?`<span style="width:14px;height:14px;display:block">${I.check}</span>`:''}</span>`).join('')}</div>
      <div class="small" style="display:flex;justify-content:space-between;margin-top:6px">${wl.map((w,i)=>`<span style="width:26px;text-align:center">${i===7?'Now':w}</span>`).join('')}</div></section></main>`;
}

/* ===================== HISTORY ===================== */
const warmIds=day=>PLAN[day]?new Set(PLAN[day].blocks.filter(b=>/^warm-up/i.test(b.t)).flatMap(b=>b.items.map(x=>x.id))):new Set();
const exCount=h=>{const w=warmIds(h.day);return Object.keys(h.entries).filter(id=>!w.has(id)).length};
function historyItems(){
  const out=[];
  DB.history.forEach((h,i)=>out.push({date:h.date,kind:'lift',i,h}));
  (DB.cardio||[]).forEach(c=>{if(c.type!=='jumps')out.push({date:c.date,kind:c.type,c})});
  return out.sort((a,b)=>a.date<b.date?1:a.date>b.date?-1:(a.kind==='lift'?-1:1));
}
function historyView(){
  const items=historyItems();
  if(!items.length)return hero({title:'History',sub:'Your sessions, week by week.'})+`<main class="wrap"><div class="card empty">Nothing logged yet. Your first workout will show up here.</div></main>`;
  const weeks={}; items.forEach(it=>{const m=mondayOf(it.date);(weeks[m]=weeks[m]||[]).push(it)});
  const curMon=mondayOf(today()), wp=weekPlan(), planned=WD_ORDER.filter(w=>wp[w]!=='rest').length;
  const html=Object.keys(weeks).sort().reverse().map(m=>{
    const list=weeks[m], st=weekStats(m), big=m===curMon;
    return `<section class="card tight"><div class="rowh" style="padding:4px 4px 8px"><span class="name">${fmtD(m,{month:'short',day:'numeric'})} – ${fmtD(addDays(m,6),{month:'short',day:'numeric'})}</span>
      <span class="small">${rdots(st)} &nbsp;${m===curMon?`${list.length} of ${planned}`:`${list.length} session${list.length>1?'s':''}`}</span></div>
      ${list.map(it=>histRow(it,big)).join('')}</section>`;
  }).join('');
  return hero({title:'History',sub:'Your sessions, week by week.'})+`<main class="wrap">${html}</main>`;
}
function histRow(it,big){
  const d=`<div class="hd">${fmtD(it.date,{weekday:'short'})}<br>${fmtD(it.date,{month:'short',day:'numeric'})}</div>`;
  if(it.kind==='lift'){
    const h=it.h, nm=PLAN[h.day]?PLAN[h.day].name:'Workout', j=cardioOn(h.date,'jumps');
    return `<button class="hrow" data-detail="${it.i}">${d}<span class="ico v">${I.dumbbell}</span><span class="grow"><span class="name" style="display:block">${nm}</span>
      <span class="meta">${exCount(h)} exercises${j?' · <span style="color:var(--mint)">jumps</span>':''}${h.lowEnergy?' · lighter':''}</span></span>
      <span class="name" style="font-size:15px">${h.min?h.min+' min':nf(h.vol||0)+' lb'}</span>${I.chev}</button>`;
  }
  const c=it.c, nm=(c.act&&typeof CARDIO_ACTS!=='undefined'&&CARDIO_ACTS[c.act]?CARDIO_ACTS[c.act].n+(c.type==='4x4'?' · 4×4':c.type==='z2'?' · Zone 2':''):null)||{office:'Office day','4x4':'4×4 intervals',z2:'Zone 2 walk',walk:'Walk',cardio:'Cardio',home:c.focus==='legs'?'Home legs + bone':'Home upper'}[c.type]||c.type;
  const right=c.type==='office'?`${nf(c.steps||0)} steps`:c.type==='4x4'?`${c.intervals||4} × 4 min`:`${c.min||0} min`;
  const sub=c.avgHR?`Avg ${c.avgHR} bpm${c.elev?` · +${c.elev} m`:''}`:c.home?'At home':c.type==='home'?'At home · bodyweight':c.type==='office'?'Walk to and from work':c.type==='4x4'?(c.min?`${c.min} min total`:'Intervals'):'Easy pace';
  return `<button class="hrow" data-editc="${c.date}|${c.type}">${d}<span class="ico ${c.type==='home'?'v':'c'}">${c.type==='home'?I.home:c.type==='4x4'?I.heart:I.walk}</span><span class="grow"><span class="name" style="display:block">${nm}</span><span class="meta">${sub}</span></span>
    <span class="name" style="font-size:15px">${right}</span>${I.chev}</button>`;
}
function detailView(){
  const s=DB.history[detailIdx]; if(!s){scr='history';return historyView()}
  const nm=PLAN[s.day]?PLAN[s.day].name:'Workout', j=cardioOn(s.date,'jumps');
  const req=PLAN[s.day]?new Set(requiredItems(s.day).map(x=>x.id)):new Set();
  const sw=s.swaps||{}, origOf=id=>Object.keys(sw).find(k=>sw[k]===id)||id;
  const wi=warmIds(s.day), ids=Object.keys(s.entries).filter(id=>!wi.has(id)), main=ids.filter(id=>req.has(origOf(id))||!PLAN[s.day]), extra=ids.filter(id=>!main.includes(id));
  const bonusPlan=PLAN[s.day]?PLAN[s.day].blocks.filter(b=>/^bonus/i.test(b.t)).flatMap(b=>b.items):[];
  const row=id=>{const ex=exById(id)||{n:id}, e=s.entries[id];
    return `<div class="row" style="flex-wrap:wrap"><span class="ck" style="width:26px;height:26px;border-radius:13px;background:var(--violet);color:#0E1018;display:flex;align-items:center;justify-content:center;flex:none"><span style="width:14px;height:14px;display:block">${I.check}</span></span>
      <div class="grow"><div class="name">${esc(cleanN(ex.n))}</div><div class="meta">${isSec(ex)?'seconds':'reps'}${perLeg(ex)}</div></div>
      ${ex.bw&&!e.w?'<span class="small">bodyweight</span>':`<label style="display:flex;align-items:center;gap:4px" class="small"><input class="ein w" type="number" inputmode="decimal" value="${e.w}" data-dw="${id}" aria-label="Weight">lb</label>`}
      <div style="display:flex;gap:6px;width:100%;padding-left:38px;margin-top:6px">${e.reps.map((r,k)=>`<input class="ein" type="number" inputmode="numeric" value="${r==null?'':r}" data-dr="${id}|${k}" aria-label="Set ${k+1}">`).join('')}<span class="small" style="align-self:center">${isSec(ex)?'s':''}</span></div></div>`};
  return hero({left:backBtn('detBack'),cls:'short',eyebrow:fmtD(s.date,{weekday:'long',month:'short',day:'numeric',year:'numeric'}),title:nm,sub:`${s.min?s.min+' min · ':''}${nf(s.vol||0)} lb moved${s.lowEnergy?' · lighter day':''}`})
   +`<main class="wrap">
    ${isLegs(s.day)||j?`<section class="card tight"><div class="tg" style="padding:4px"><span class="ico m">${I.bone}</span><div class="grow"><div class="name">Jumps warm-up</div><div class="meta">Pogo hops 3 × 10 · Box jumps 3 × 5</div></div>
      <button class="sw ${j?'on':''}" id="detJumps" role="switch" aria-checked="${!!j}" aria-label="Jumps done"></button></div></section>`:''}
    <section class="card"><div class="rowh"><span class="label">Main lifts</span><span class="small">Tap a number to edit</span></div><div style="margin-top:4px">${main.map(row).join('')||'<div class="empty">None</div>'}</div></section>
    ${extra.length?`<section class="card"><span class="label">Bonus & extras</span><div style="margin-top:4px">${extra.map(row).join('')}</div></section>`
      :bonusPlan.length?`<section class="card tight" style="border-style:dashed"><div class="tg" style="padding:4px"><span class="ico g">${I.star}</span><div class="grow"><div class="name">Bonus</div><div class="meta">${bonusPlan.map(b=>esc(cleanN(b.n))).join(' · ')}</div></div><span class="chip n">Skipped</span></div></section>`:''}
    <button class="link" id="delSess" style="color:#FF8A70">Delete this session</button></main>`;
}

/* ===================== SETTINGS ===================== */
const INJ_SHOW=[['shoulder','Shoulder'],['knee','Knee'],['lowback','Lower back'],['elbow','Elbow / wrist']];
function settingsView(){
  const hr=rcHR(), off=officeDays(), on=k=>(DB.injuries||[]).some(i=>i.key===k);
  return hero({title:'Settings',sub:'Profile, injuries, schedule and data.'})
   +`<main class="wrap">
    <section class="card"><span class="label">You</span>
      <label class="step" style="margin-top:10px;padding:6px 14px"><span class="name">Name</span><input id="nameIn" type="text" value="${esc(profile.name)}" autocomplete="given-name" style="text-align:right;font-size:17px;font-weight:600;width:60%"></label>
      <div class="seg" style="margin-top:10px">${[['male','Male'],['female','Female']].map(([k,l])=>`<button data-gender="${k}" class="${profile.gender===k?'on':''}">${l}</button>`).join('')}</div>
      <p class="note" style="margin:10px 0 0">Gender sets the plan template and starting loads. Your history and weights stay when you change it.</p></section>
    <section class="card"><span class="label">Injury flags</span><p class="note" style="margin:6px 0 4px">Flagging one holds every lift that loads it and adds safer substitutes.</p>
      ${INJ_SHOW.map(([k,l])=>`<div class="tg"><div class="grow"><div class="name" style="font-size:15px">${l}</div>${on(k)?`<div class="meta">Since ${fmtD(DB.injuries.find(i=>i.key===k).since,{month:'short',day:'numeric'})} · ${DB.injuries.find(i=>i.key===k).ids.length} lifts on hold</div>`:''}</div>
        <button class="sw ${on(k)?'on':''}" data-inj="${k}" role="switch" aria-checked="${on(k)}" aria-label="${l}"></button></div>`).join('')}</section>
    <section class="card"><span class="label">Office days</span><p class="note" style="margin:6px 0 10px">Walking to work is your easy cardio on these days. With 2 office days the 4×4 moves to Sunday.</p>
      <div class="daychips">${[1,2,3,4,5].map(d=>`<button data-off="${d}" class="${off.includes(d)?'on':''}" aria-pressed="${off.includes(d)}" aria-label="${WD_L[d]}">${WD_S[d][0]}</button>`).join('')}</div>
      <p class="note" style="margin:10px 0 0">Lift days are Mon, Wed, Fri, Sat. An office day on a lift day keeps the lift.</p></section>
    <section class="card"><span class="label">Heart zones</span>
      <div class="tg"><div class="grow name" style="font-size:15px">Age</div>
        <div class="step" style="padding:4px;gap:10px"><button data-age="-1" aria-label="Younger" style="width:40px;height:40px">−</button><div class="v"><b style="font-size:22px">${DB.age||'—'}</b></div><button data-age="1" aria-label="Older" style="width:40px;height:40px">+</button></div></div>
      ${hr?`<div class="tg"><span class="grow">Zone 2 (easy)</span><b>${hr.z2[0]}–${hr.z2[1]} bpm</b></div><div class="tg"><span class="grow">4×4 hard</span><b style="color:var(--coral)">${hr.hard[0]}–${hr.hard[1]} bpm</b></div><div class="note">Estimated max ${hr.max} bpm.</div>`:''}</section>
    <section class="card"><span class="label">Data</span>
      <button class="hrow" id="exportBtn"><span class="ico g">${I.dl}</span><span class="grow name" style="font-size:15px">Export data</span>${I.chev}</button>
      <button class="hrow" id="importBtn"><span class="ico g">${I.ul}</span><span class="grow name" style="font-size:15px">Import (Strata or Lift Log file)</span>${I.chev}</button>
      ${liftLogLocal()?`<button class="hrow" id="llLocal"><span class="ico g">${I.ul}</span><span class="grow"><span class="name" style="font-size:15px;display:block">Import from Lift Log on this device</span><span class="meta">${liftLogLocal().n} sessions found</span></span>${I.chev}</button>`:''}
      <button class="hrow" id="resetBtn" style="color:#FF8A70"><span class="ico g" style="color:#FF8A70">${I.close}</span><span class="grow name" style="font-size:15px">Reset ${esc(profile.name)}</span></button></section>
    <p class="note" style="text-align:center">Strata · data stays on this phone. Export it now and then as a backup.</p></main>`;
}

/* ===================== FIRST LAUNCH ===================== */
function onboardView(){
  const o=onboard, ll=o.gender?liftLogLocal(o.gender==='female'?'sa':'nr'):null, ready=o.name.trim()&&o.gender;
  return `<header class="hero tall"><div class="topbar"><div class="brand">${I.logo}Strata</div></div>
    <div class="htext"><div><h1 style="font-size:36px">Build it in layers:<br><span style="color:var(--violet)">muscle</span>, <span style="color:var(--coral)">heart</span>, <span style="color:var(--mint)">bone</span></h1>
    <div class="sub">4 lifts, 2–3 heart sessions and 2 jump warm-ups a week. Each one closes a ring.</div></div></div></header>
   <main class="wrap">
    <section class="card"><span class="label">About you</span>
      <label class="step" style="margin-top:10px;padding:6px 14px"><span class="name">Name</span><input id="obName" type="text" value="${esc(o.name)}" placeholder="Your name" autocomplete="given-name" style="text-align:right;font-size:17px;font-weight:600;width:60%"></label>
      <div class="seg" style="margin-top:10px" role="group" aria-label="Gender">${[['male','Male'],['female','Female']].map(([k,l])=>`<button data-ogender="${k}" class="${o.gender===k?'on':''}" aria-pressed="${o.gender===k}">${l}</button>`).join('')}</div>
      <p class="note" style="margin:8px 0 0">Sets your plan template and starting loads.</p></section>
    ${o.gender?`<section class="card"><span class="label">Bring your history</span>
      ${o.imported?`<div class="name" style="margin-top:10px;color:var(--mint)">${o.imported} sessions imported</div>`
      :`${ll?`<button class="btn sm" id="obLocal" style="margin-top:10px">Import ${ll.n} Lift Log sessions from this device</button>`:''}
      <button class="btn sm" id="obFile" style="margin-top:10px">Import a Lift Log export file</button>
      <p class="note" style="margin:8px 0 0">Optional. In Lift Log: More → Export data, then pick that file here. Weights carry over, so nothing restarts.</p>`}</section>`:''}
    <section class="card"><div class="tg" style="padding:0"><div class="grow"><div class="name">Age</div><div class="meta">For heart-rate targets</div></div>
      <label class="step" style="padding:4px 12px"><span class="sr">Age</span><input id="obAge" type="number" inputmode="numeric" min="14" max="99" value="${o.age||''}" placeholder="—" style="width:70px;font-size:22px"></label></div></section>
    <section class="card"><span class="label">Office days</span><p class="note" style="margin:6px 0 10px">Days you walk to work. Optional.</p><div class="daychips">${[1,2,3,4,5].map(d=>`<button data-ooff="${d}" class="${o.off.includes(d)?'on':''}" aria-pressed="${o.off.includes(d)}" aria-label="${WD_L[d]}">${WD_S[d][0]}</button>`).join('')}</div></section></main>
   <div class="dock"><button class="btn primary" id="obGo" ${ready?'':'disabled'}>${ready?'Get started':'Add your name and gender'}</button></div>`;
}
function newProfile(name,gender){
  const f=gender==='female';
  return {id:'me',name:name||'',initials:(name||'?').slice(0,2).toUpperCase(),gender,plan:f?'sa':'nr',bw:f?132:194,exp:f?'new':'trained'};
}
async function startOnboard(){
  onboard={name:'',gender:null,age:null,off:[],imported:0}; DB=freshDB(); profile=null;
  render();
}
async function setGender(g){
  const keep={...DB};
  profile=Object.assign(profile||newProfile('',g),{gender:g,plan:g==='female'?'sa':'nr',bw:g==='female'?132:194,exp:g==='female'?'new':'trained'});
  profiles=[profile];
  if(!DB||!DB.history)DB=freshDB(); else DB=keep;
  setActivePlan();
}
const freshDB=()=>{const d=defaultDB('x');d.holds={};return d};

/* ===================== LIFT LOG IMPORT ===================== */
function liftLogLocal(planKey){
  try{
    const reg=JSON.parse(localStorage.getItem('liftlog:profiles')||'null'); if(!Array.isArray(reg))return null;
    const p=reg.find(x=>x.plan===(planKey||profile.plan)); if(!p)return null;
    const raw=localStorage.getItem('liftlog:v2:'+p.id); if(!raw)return null;
    const d=JSON.parse(raw); return d&&d.history&&d.history.length?{n:d.history.length,data:d,name:p.name}:null;
  }catch(e){return null}
}
function applyImport(p){
  DB.next=p.next||{}; DB.history=(p.history||[]).slice().sort((a,b)=>a.date<b.date?-1:a.date>b.date?1:0);
  DB.active=null; DB.holds=p.holds||{}; DB.cycleStarts=p.cycleStarts||[];
  DB.focus=p.focus||null; DB.injuries=p.injuries||[]; DB.cycleAnchor=p.cycleAnchor||null;
  DB.cardio=p.cardio||[]; if(p.age)DB.age=p.age; if(p.rcOffice!=null)DB.rcOffice=p.rcOffice;
  if(Array.isArray(p.officeDays))DB.officeDays=p.officeDays; if(Array.isArray(p.waist))DB.waist=p.waist;
  setActivePlan(); save();
}
function importFile(cb,quiet){
  const f=$('#file'); f.value='';
  f.onchange=()=>{const file=f.files[0]; if(!file)return; const rd=new FileReader();
    rd.onload=()=>{try{const p=JSON.parse(rd.result); if(!p||typeof p!=='object'||!Array.isArray(p.history))throw 0;
      const plan=p.planKey||(p.profile==='nr'||p.profile==='sa'?p.profile:null);
      if(!quiet&&plan&&plan!==profile.plan&&!confirm(`This file is from ${p.profileName||plan}. Import it into ${profile.name} anyway? ${profile.name}'s current data will be replaced.`))return;
      if(!quiet&&!plan&&!confirm(`Replace ${profile.name}'s data with this file?`))return;
      applyImport(p); toast(`Imported ${DB.history.length} sessions`); cb&&cb(DB.history.length,p); if(!cb)render();
    }catch(e){toast('That file is not a valid export')}};
    rd.readAsText(file)};
  f.click();
}

/* ===================== PROFILES / STORAGE ===================== */
const ME_KEY='strata:me';
async function saveMe(){ try{await store.set(ME_KEY,JSON.stringify(profile))}catch(e){} }
async function loadMe(){
  let raw=null; try{raw=await store.get(ME_KEY)}catch(e){}
  if(raw){try{profile=JSON.parse(raw)}catch(e){profile=null}}
  if(!profile){
    /* migrate the earlier two-profile build: keep whichever profile was active, with its data key */
    let reg=null, act=null; try{reg=JSON.parse(await store.get(PROFILES_KEY)||'null'); act=await store.get(ACTIVE_KEY)}catch(e){}
    if(Array.isArray(reg)&&reg.length){
      const p=reg.find(x=>x.id===act)||reg[0];
      if(await store.get(keyFor(p.id))){ profile={...p,gender:p.plan==='sa'?'female':'male'}; await saveMe(); }
    }
  }
  if(!profile)return false;
  profiles=[profile];
  let d=null; try{d=await store.get(keyFor(profile.id))}catch(e){}
  DB=freshDB();
  if(d){try{Object.assign(DB,JSON.parse(d))}catch(e){}}
  DB.history=DB.history||[]; DB.cardio=DB.cardio||[]; DB.next=DB.next||{}; DB.holds=DB.holds||{};
  setActivePlan();
  return true;
}

/* ===================== SHEET ===================== */
function openSheet(html){const S=$('#sheet');S.innerHTML=`<div class="sheet" role="dialog" aria-modal="true"><div class="grab"></div>${html}</div>`;S.hidden=false}
function closeSheet(){const S=$('#sheet');S.hidden=true;S.innerHTML=''}
$('#sheet').addEventListener('click',e=>{
  if(e.target.id==='sheet'){closeSheet();return}
  const sw=e.target.closest('[data-swapto]');
  if(sw){const A=DB.active, L=liftList(), orig=L[curIdx()], to=sw.dataset.swapto;
    if(to)A.swaps[orig.id]=to; else delete A.swaps[orig.id];
    A.idx=curIdx(); save(); closeSheet(); render(); toast(to?`Swapped to ${cleanN(exById(to).n)}`:'Back to the planned lift'); return}
  if(e.target.id==='cSave'){const [d,t]=e.target.dataset.c.split('|'), v=+$('#cVal').value||0, c=cardioOn(d,t);
    if(c){ if(t==='office')c.steps=v; else if(t==='4x4')c.intervals=v; else c.min=v; save(); } closeSheet(); render(); return}
  if(e.target.id==='cDel'){const [d,t]=e.target.dataset.c.split('|'); if(!confirm('Delete this entry?'))return;
    DB.cardio=DB.cardio.filter(c=>!(c.date===d&&c.type===t)); save(); closeSheet(); render(); return}
  const mn=e.target.closest('[data-menu]');
  if(mn){const k=mn.dataset.menu; closeSheet();
    if(k==='finish'){endSession();return}
    if(k==='low'){DB.active.lowEnergy=!DB.active.lowEnergy;save();render();toast(DB.active.lowEnergy?'Lighter day on':'Lighter day off');return}
    if(k==='discard'){if(confirm('Discard this workout? Nothing will be saved.')){DB.active=null;rest=null;save();go('today')}return}}
  const wy=e.target.closest('[data-why]');
  if(wy){const t=today(), slot=weekPlan()[wdOf(t)];
    DB.skips=DB.skips||{};
    DB.skips[t]={why:wy.dataset.why,slot,key:homeKey(slot,t),day:slot==='lift'?nextDay():null};
    save(); closeSheet(); selDay=null; render();
    toast(wy.dataset.why==='sick'?'Rest day. The rotation waits.':'Here\'s a home version'); return}
  const wk=e.target.closest('[data-walk]');
  if(wk){const v=+$('#wMin').value||0; if(!v)return; logCardio(wk.dataset.walk,{min:v}); closeSheet(); render(); toast(`Walk logged · ${v} min`); return}
});
function cardioSheet(d,t){
  const c=cardioOn(d,t); if(!c)return;
  const nm={office:'Office day','4x4':'4×4 intervals',z2:'Zone 2 walk',walk:'Walk',cardio:'Cardio',home:'Home session'}[t], f=t==='office'?['steps',c.steps||0]:t==='4x4'?['intervals',c.intervals||4]:['minutes',c.min||0];
  openSheet(`<div class="label">${fmtD(d,{weekday:'long',month:'short',day:'numeric'})}</div><div class="title2" style="font-size:20px">${nm}</div>
    <label class="step" style="margin-top:12px;padding:8px 14px"><span class="name">${f[0]}</span><input id="cVal" type="number" inputmode="numeric" value="${f[1]}" style="text-align:right"></label>
    <div style="display:flex;gap:10px;margin-top:14px"><button class="btn" id="cDel" data-c="${d}|${t}" style="color:#FF8A70">Delete</button><button class="btn primary" id="cSave" data-c="${d}|${t}">Save</button></div>`);
}

/* ===================== EVENTS ===================== */
$('#tabs').addEventListener('click',e=>{const b=e.target.closest('[data-tab]');if(b){selDay=null;go(b.dataset.tab)}});
document.addEventListener('click',e=>{
  if(e.target.closest('#sheet')||e.target.closest('#tabs'))return;
  const t=e.target.closest('button'); if(!t)return;
  const ds=t.dataset, id=t.id;
  if(ds.yt){e.preventDefault();openVid({id:ds.yt,n:''});return}
  if(id==='back'){go(prevScr&&TABS.some(x=>x[0]===prevScr)?prevScr:'today');return}
  if(ds.wd!=null){selDay=+ds.wd===wdOf(today())?null:+ds.wd;render();return}
  if(ds.preview){previewDay=+ds.preview;go('preview');return}
  if(id==='resume'){go(DB.active&&!DB.active.jumpsSeen&&isLegs(DB.active.day)?'jumps':'lift');return}
  if(id==='lowTg'){preLow=!preLow;render();return}
  if(id==='beginBtn'){
    if(DB.active){toast('Finish the open workout first');go('lift');return}
    const g=gateFor(previewDay); if(!g.ok&&!confirm(g.msg.replace(/<[^>]+>/g,'')+'\n\nStart anyway?'))return;
    begin(previewDay); jumpSets={}; go(isLegs(previewDay)?'jumps':'lift'); return}
  if(ds.jset){const [k,i]=ds.jset.split('|'); jumpSets[k]=(jumpSets[k]||0)===+i+1?+i:+i+1; render(); return}
  if(id==='jumpsDone'){const A=DB.active; A.jumpsSeen=1;
    PLAN[A.day].blocks.filter(b=>/^warm-up/i.test(b.t)).flatMap(b=>b.items).forEach(ex=>{if((jumpSets[ex.id]||0)>0)A.entries[ex.id]={w:0,reps:Array(jumpSets[ex.id]).fill(ex.r)}});
    logCardio('jumps',{landings:45}); go('lift'); toast('Jumps logged'); return}
  if(id==='skipJumps'){DB.active.jumpsSeen=1;save();go('lift');return}
  if(id==='jumpBack'||id==='liftBack'){go('today');return}
  if(ds.st){const [k,dir]=ds.st.split('|'), el=$(k==='r'?'#vR':'#vW');
    const L=liftList(), ex=shownEx(L[curIdx()]), stp=k==='r'?(isSec(ex)?5:1):(ex.inc||5);
    el.textContent=Math.max(0,+el.textContent+(+dir)*stp); return}
  if(id==='logSet'){logSet();return}
  if(ds.eset!=null){const A=DB.active,ex=shownEx(liftList()[curIdx()]),p=A.prog[ex.id]||A.entries[ex.id]; if(p&&+ds.eset<p.reps.length){editSet=editSet===+ds.eset?null:+ds.eset;render()}return}
  if(ds.goto!=null){DB.active.idx=+ds.goto;editSet=null;save();render();window.scrollTo({top:0});return}
  if(id==='nextLift'){const L=liftList(), idx=curIdx(), n=L.findIndex((x,i)=>i>idx&&!isLogged(x)), any=L.findIndex(x=>!isLogged(x));
    const reqDone=requiredItems(DB.active.day).every(isLogged);
    if(n>=0){DB.active.idx=n;save();render();window.scrollTo({top:0});return}
    if(any>=0&&!reqDone){DB.active.idx=any;save();render();window.scrollTo({top:0});return}
    endSession();return}
  if(id==='swapBtn'){swapSheet();return}
  if(id==='rest30'){if(rest){rest.endAt=Math.max(rest.endAt,Date.now())+30000;rest.total+=30;rest.beeped=false;render()}return}
  if(id==='restSkip'){rest=null;render();return}
  if(id==='liftMenu'){liftMenu();return}
  if(id==='endBtn'||id==='finishLink'){endSession();return}
  if(id==='doneBtn'){celebration=null;vo2Done=null;selDay=null;go('today');return}
  if(id==='openVo2'||id==='openVo2b'){vo2N=null;go('vo2');return}
  if(ds.n&&scr==='vo2'){vo2N=+ds.n;render();return}
  if(id==='startTimer'){startTimer(vo2N||rcDefaultIntervals());return}
  if(id==='logVo2'){const n=vo2N||rcDefaultIntervals(); logCardio('4x4',{intervals:n,min:rcMinutes(n)}); vo2Done={intervals:n,min:rcMinutes(n),date:today()}; go('vo2done'); return}
  if(id==='tmrPause'){ if(timer.paused){timer.endAt=Date.now()+timer.remain*1000;timer.pausedMs+=Date.now()-timer.pauseAt;timer.paused=false;lockScreen(true)}
    else{timer.remain=(timer.endAt-Date.now())/1000;timer.pauseAt=Date.now();timer.paused=true;lockScreen(false)} render(); return}
  if(id==='tmrSkip'){ if(timer.idx>=timer.phases.length-1){finishTimer(true);return}
    timer.idx++; const sec=timer.phases[timer.idx].sec; if(timer.paused)timer.remain=sec; else timer.endAt=Date.now()+sec*1000; cue(); render(); return}
  if(id==='tmrStop'){const hd=timer.phases.slice(0,timer.idx+1).filter(q=>q.k==='hard').length;
    if(hd>=2&&confirm(`Stop here and log ${hd} intervals?`)){timer.n=hd;finishTimer(true);return}
    if(hd<2&&!confirm('Stop the timer? Nothing will be logged.'))return; finishTimer(false); return}
  if(id==='cantTrain'){cantTrainSheet();return}
  if(id==='undoSkip'){if(DB.skips)delete DB.skips[ds.d]; save(); render(); toast('Back on the plan'); return}
  if(id==='homeDone'){const sk=skipOn(ds.d); if(!sk)return; const H=HOME[sk.key];
    if(sk.key==='legs'){logCardio('home',{min:H.min,focus:'legs'},ds.d); logCardio('jumps',{landings:30,home:1},ds.d)}
    else if(sk.key==='upper')logCardio('home',{min:H.min,focus:'upper'},ds.d);
    else if(sk.key==='vo2')logCardio('4x4',{intervals:4,min:H.min,home:1},ds.d);
    else logCardio(sk.slot==='office'?'walk':(CTYPE[sk.slot]||'walk'),{min:H.min,home:1},ds.d);
    sk.done=1; save(); render(); toast('Home session logged · momentum kept'); return}
  if(ds.logsteps){const v=+String($('#stepsIn').value).replace(/\D/g,''); if(!v){toast('Type your steps first');return}
    logCardio('office',{steps:v},ds.logsteps); render(); toast(`${nf(v)} steps logged`); return}
  if(ds.logmin){const v=+$('#minIn').value||0; if(!v)return; logCardio(CTYPE[ds.logmin],{min:v}); render(); toast(`Logged · ${v} min`); return}
  if(ds.sheet==='walk'){openSheet(`<div class="title2" style="font-size:20px">Log a walk</div><label class="step" style="margin-top:12px;padding:8px 14px"><span class="name">Minutes</span><input id="wMin" type="number" inputmode="numeric" value="45" style="text-align:right"></label>
    <div style="display:flex;gap:10px;margin-top:14px"><button class="btn" data-walk="z2">Zone 2</button><button class="btn primary" data-walk="walk">Easy walk</button></div>`);return}
  if(ds.editc){const [d,t]=ds.editc.split('|');cardioSheet(d,t);return}
  if(ds.detail!=null){detailIdx=+ds.detail;go('detail');return}
  if(id==='detBack'){go('history');return}
  if(id==='detJumps'){const s=DB.history[detailIdx]; if(cardioOn(s.date,'jumps'))DB.cardio=DB.cardio.filter(c=>!(c.date===s.date&&c.type==='jumps')); else logCardio('jumps',{landings:45},s.date); save(); render(); return}
  if(id==='delSess'){if(!confirm('Delete this session permanently?'))return; DB.history.splice(detailIdx,1); save(); go('history'); toast('Session deleted'); return}
  if(ds.plift){progLift=ds.plift;render();return}
  if(ds.range){progRange=+ds.range;render();return}
  if(id==='addWaist'){const v=+$('#waistIn').value; if(!(v>40&&v<200)){toast('Type your waist in cm');return}
    DB.waist=(DB.waist||[]).filter(w=>w.date!==today()); DB.waist.push({date:today(),cm:v}); DB.waist.sort((a,b)=>a.date<b.date?-1:1); save(); render(); toast('Waist saved'); return}
  if(ds.gender){const g=ds.gender; if(g===profile.gender)return;
    if(!confirm(`Switch to the ${g} plan template? Your history and weights stay.`))return;
    setGender(g); saveMe(); save(); render(); toast('Plan template updated'); return}
  if(ds.inj){const k=ds.inj; if((DB.injuries||[]).some(i=>i.key===k)){releaseInjury(k)}
    else{const ids=idsForInjury(k,PLAN), c=costOf(ids);
      const msg=`Flag ${INJURIES[k].label.toLowerCase()}? ${ids.length} lift${ids.length===1?'':'s'} go on hold.${c.drops.length?` ${c.drops.slice(0,3).map(d=>`${d.area} ${fmtSets(d.from)}→${fmtSets(d.to)}`).join(', ')} sets/week.`:''}`;
      if(confirm(msg))applyInjury(k)} return}
  if(ds.off){const d=+ds.off, off=officeDays().slice(); const i=off.indexOf(d); if(i>=0)off.splice(i,1); else off.push(d); DB.officeDays=off.sort(); save(); render(); return}
  if(ds.age){DB.age=Math.min(99,Math.max(14,(DB.age||40)+(+ds.age))); save(); render(); return}
  if(id==='exportBtn'){const payload=Object.assign({app:'strata',profile:profile.id,profileName:profile.name,planKey:profile.plan},DB);
    const b=new Blob([JSON.stringify(payload,null,2)],{type:'application/json'}), a=document.createElement('a');
    a.href=URL.createObjectURL(b); a.download=`strata-${(profile.name||'me').toLowerCase().replace(/[^a-z0-9]+/g,'-')}-${today()}.json`; document.body.appendChild(a); a.click(); a.remove(); return}
  if(id==='importBtn'){importFile();return}
  if(id==='llLocal'){const ll=liftLogLocal(); if(ll&&confirm(`Replace ${profile.name}'s Strata data with ${ll.n} Lift Log sessions?`)){applyImport(ll.data);render();toast(`Imported ${ll.n} sessions`)} return}
  if(id==='resetBtn'){if(!confirm(`Erase all of ${profile.name}'s history and weights? This can't be undone.`))return; DB=freshDB(); setActivePlan(); save(); render(); toast('Reset'); return}
});
/* history detail edits */
document.addEventListener('change',e=>{
  const t=e.target;
  if(t.id==='nameIn'){const n=t.value.trim(); if(n){profile.name=n;profile.initials=n.slice(0,2).toUpperCase();saveMe();toast('Name saved')} else t.value=profile.name; return} if(scr!=='detail'||!t.classList.contains('ein'))return;
  const s=DB.history[detailIdx]; if(!s)return;
  if(t.dataset.dw){s.entries[t.dataset.dw].w=+t.value||0}
  else if(t.dataset.dr){const [id,k]=t.dataset.dr.split('|'); s.entries[id].reps[+k]=t.value===''?null:+t.value}
  let v=0; Object.keys(s.entries).forEach(id=>{v+=volOf(id,s.entries[id].w,s.entries[id].reps)}); s.vol=Math.round(v);
  save();
});
function wireOnboard(){
  const nm=$('#obName'); nm.oninput=()=>{onboard.name=nm.value; const b=$('#obGo'),ok=onboard.name.trim()&&onboard.gender; b.disabled=!ok; b.textContent=ok?'Get started':'Add your name and gender'};
  const ag=$('#obAge'); ag.onchange=()=>{const v=+ag.value; onboard.age=(v>=14&&v<=99)?v:null};
  document.querySelectorAll('[data-ogender]').forEach(b=>b.onclick=async()=>{onboard.gender=b.dataset.ogender; await setGender(onboard.gender); render()});
  document.querySelectorAll('[data-ooff]').forEach(b=>b.onclick=()=>{const d=+b.dataset.ooff,i=onboard.off.indexOf(d);if(i>=0)onboard.off.splice(i,1);else onboard.off.push(d);onboard.off.sort();render()});
  const afterImport=n=>{onboard.imported=n; if(DB.age&&!onboard.age)onboard.age=DB.age; if(Array.isArray(DB.officeDays))onboard.off=DB.officeDays.slice(); else if(DB.rcOffice)onboard.off=[2,4]; render()};
  const l=$('#obLocal'); if(l)l.onclick=()=>{const ll=liftLogLocal(profile.plan); if(ll){applyImport(ll.data,true); if(!onboard.name.trim())onboard.name=ll.name||''; afterImport(ll.n)}};
  const f=$('#obFile'); if(f)f.onclick=()=>{const keep=onboard; importFile((n,p)=>{onboard=keep; if(!onboard.name.trim()&&p&&p.profileName)onboard.name=p.profileName; afterImport(n)},true)};
  $('#obGo').onclick=async()=>{const n=onboard.name.trim(); if(!n||!onboard.gender)return;
    profile.name=n; profile.initials=n.slice(0,2).toUpperCase(); profiles=[profile];
    if(onboard.age)DB.age=onboard.age; DB.officeDays=onboard.off.slice();
    await saveMe(); await save(); onboard=null; scr='today'; render();};
}

/* ===================== BOOT ===================== */
(async()=>{
  const ok=await loadMe();
  if(!ok){await startOnboard();return}
  render();
})();
