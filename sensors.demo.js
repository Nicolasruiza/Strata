/* =====================================================================
   DEMO SENSOR — testing only. NOT part of the product logic.
   The web can't read an Apple Watch, so this file can feed believable
   heart-rate (and, indoors on a desktop, altitude) readings into the real
   Sensors adapter in workout.js, so the screens can be tested end to end.
   It only runs when the user turns on "use demo data", and the screen is
   always labelled DEMO while it runs.
   IOS: do NOT port this file. The watch's HKLiveWorkoutBuilder replaces it.
   ===================================================================== */
window.StrataDemo={
  create(L){
    const age=+DB.age||40, M=Math.round(208-.7*age);
    let hr=Math.round(M*.5), alt=L&&CARDIO_ACTS[L.act]&&CARDIO_ACTS[L.act].out?150:null;
    const target=t=>{
      if(L.mode==='4x4'){const a=phaseAt(t,L); return a.p.k==='hard'?M*.9:/Warm/.test(a.p.label)?M*.65:M*.7;}
      return M*(L.mode==='z2'?.66:.7);
    };
    return {read(t){
      hr+=(target(t)-hr)*.12+(Math.random()-.5)*3;   // heart rate drifts toward the effort, with noise
      if(alt!=null)alt+=(Math.random()-.42)*1.6;       // rolling terrain, slightly uphill
      return {hr:Math.round(hr),alt};
    }};
  }
};
