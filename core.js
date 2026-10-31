const PLAN_NR={
 1:{name:"Upper A",short:"U-A",blocks:[
  {t:"Basics · free weight",items:[
   {id:"bb_press",n:"Barbell press",r:6,w:135,inc:5,key:1,bar:45,frac:.696},
   {id:"lat_pull",n:"Lat pulldown",r:8,w:75,inc:5,key:1,mult:2,frac:.387}]},
  {t:"Compound",items:[
   {id:"db_ohp",n:"Dumbbell shoulder press",r:8,w:35,inc:5,each:1,frac:.180},
   {id:"cbl_row",n:"Cable row",r:10,w:70,inc:5,frac:.361}]},
  {t:"Bonus · if time",items:[
   {id:"db_curl",n:"Dumbbell bicep curl",r:12,w:30,inc:5,each:1,frac:.155},
   {id:"cbl_tri",n:"Cable triceps extension",r:12,w:60,inc:5,frac:.309},
   {id:"leg_raise",n:"Hanging leg raise",r:10,w:0,inc:0,bw:1,frac:0}]}]},
 2:{name:"Legs A",short:"LEG-A",blocks:[
  {t:"Basics · free weight",items:[
   {id:"gob_squat",n:"Goblet squat",r:8,w:50,inc:5,key:1,frac:.258},
   {id:"hip_thrust",n:"Barbell hip thrust",r:10,w:95,inc:10,key:1,bar:45,frac:.490}]},
  {t:"Compound",items:[
   {id:"split_squat",n:"Dumbbell split squat (per leg)",r:10,w:25,inc:5,each:1,frac:.129},
   {id:"sb_squat",n:"Single-leg box squat (per leg)",r:8,w:0,inc:5,bw:1,frac:0}]},
  {t:"Bonus · if time",items:[
   {id:"hip_abd",n:"Hip abduction",r:15,w:70,inc:10,frac:.361},
   {id:"pallof",n:"Pallof press (per side)",r:12,w:30,inc:5,frac:.155}]}]},
 3:{name:"Upper B",short:"U-B",blocks:[
  {t:"Basics",items:[
   {id:"db_incl",n:"Dumbbell incline bench press",r:8,w:45,inc:5,each:1,key:1,frac:.232},
   {id:"pullup",n:"Pull-ups",r:8,w:0,inc:5,bw:1,key:1,frac:0}]},
  {t:"Compound",items:[
   {id:"db_row",n:"Dumbbell row",r:8,w:50,inc:5,frac:.258},
   {id:"lat_raise",n:"Lateral raise",r:15,w:15,inc:5,each:1,frac:.077}]},
  {t:"Bonus · if time",items:[
   {id:"hammer",n:"Hammer curls",r:12,w:25,inc:5,each:1,frac:.129},
   {id:"skull",n:"Skull crusher",r:12,w:40,inc:5,bar:25,frac:.206},
   {id:"cbl_crunch",n:"Cable crunch",r:15,w:50,inc:5,frac:.258}]}]},
 4:{name:"Legs B",short:"LEG-B",blocks:[
  {t:"Warm-up · balance",items:[{id:"sl_rdl",n:"Single-leg RDL, bodyweight (per leg)",r:10,w:0,inc:0,bw:1,frac:0}]},
  {t:"Basics · free weight",items:[
   {id:"rdl",n:"Romanian deadlift",r:6,w:95,inc:10,key:1,bar:45,frac:.490},
   {id:"step_up",n:"Dumbbell step-up (per leg)",r:10,w:25,inc:5,each:1,key:1,frac:.129}]},
  {t:"Compound",items:[
   {id:"leg_press",n:"Leg press",r:10,w:180,inc:10,plates:1,frac:.928},
   {id:"farmer",n:"Farmer carry (seconds)",r:40,w:50,inc:5,each:1,frac:.258}]},
  {t:"Bonus · if time",items:[
   {id:"ham_curl",n:"Lying hamstring curl",r:12,w:80,inc:10,frac:.412}]}]}
};
/* The previous 3-day plan. Not used for training any more; kept so lifts that left
   the plan (fly, face pull, barbell curl, calf raise) still resolve in history. */
const PLAN_NR3={
 1:{name:"Upper A",short:"U-A",blocks:[
  {t:"Core · do first",items:[
   {id:"leg_raise",n:"Hanging leg raise",r:10,w:0,inc:0,bw:1,frac:0},
   {id:"pallof",n:"Pallof press (per side)",r:12,w:30,inc:5,frac:.155}]},
  {t:"Basics · free weight",items:[
   {id:"bb_press",n:"Barbell press",r:6,w:135,inc:5,key:1,bar:45,frac:.696},
   {id:"lat_pull",n:"Lat pulldown",r:8,w:75,inc:5,key:1,mult:2,frac:.387}]},
  {t:"Compound",items:[
   {id:"db_ohp",n:"Dumbbell shoulder press",r:8,w:35,inc:5,each:1,frac:.180},
   {id:"db_row",n:"Dumbbell row",r:8,w:50,inc:5,frac:.258}]},
  {t:"Isolation",items:[
   {id:"m_fly",n:"Machine fly",r:12,w:145,inc:5,frac:.747},
   {id:"cbl_tri",n:"Cable triceps extension",r:12,w:60,inc:5,frac:.309},
   {id:"db_curl",n:"Dumbbell bicep curl",r:12,w:30,inc:5,each:1,frac:.155},
   {id:"face_pull",n:"Face pull",r:15,w:30,inc:5,frac:.155}]}]},
 2:{name:"Legs",short:"LEG",blocks:[
  {t:"Core · do first",items:[{id:"plank",n:"Plank (seconds)",r:45,w:0,inc:0,bw:1,frac:0}]},
  {t:"Basics · free weight",items:[
   {id:"gob_squat",n:"Goblet squat",r:8,w:50,inc:5,key:1,frac:.258},
   {id:"rdl",n:"Romanian deadlift",r:6,w:95,inc:10,key:1,bar:45,frac:.490}]},
  {t:"Compound",items:[{id:"leg_press",n:"Leg press",r:10,w:180,inc:10,plates:1,frac:.928}]},
  {t:"Isolation",items:[
   {id:"ham_curl",n:"Lying hamstring curl",r:12,w:80,inc:10,frac:.412},
   {id:"leg_ext",n:"Leg extension",r:12,w:100,inc:10,frac:.515},
   {id:"calf",n:"Calf raise",r:15,w:90,inc:10,frac:.464}]}]},
 3:{name:"Upper B",short:"U-B",blocks:[
  {t:"Core · do first",items:[{id:"cbl_crunch",n:"Cable crunch",r:15,w:50,inc:5,frac:.258}]},
  {t:"Basics",items:[
   {id:"db_incl",n:"Dumbbell incline bench press",r:8,w:45,inc:5,each:1,key:1,frac:.232},
   {id:"pullup",n:"Pull-ups",r:8,w:0,inc:5,bw:1,key:1,frac:0}]},
  {t:"Compound",items:[
   {id:"cbl_row",n:"Cable row",r:10,w:70,inc:5,frac:.361},
   {id:"bb_curl",n:"Barbell curl",r:8,w:70,inc:5,bar:25,frac:.361}]},
  {t:"Isolation",items:[
   {id:"lat_raise",n:"Lateral raise",r:15,w:15,inc:5,each:1,frac:.077},
   {id:"skull",n:"Skull crusher",r:12,w:40,inc:5,bar:25,frac:.206},
   {id:"hammer",n:"Hammer curls",r:12,w:25,inc:5,each:1,frac:.129}]}]}
};
/* Sofia's plan, same 4-day Upper / Legs / Upper / Legs shape as Nicolas's, her own loads. */
const PLAN_SA={
 1:{name:"Upper A",short:"U-A",blocks:[
  {t:"Basics · free weight",items:[
   {id:"sa_db_bench",n:"Dumbbell bench press",r:8,w:15,inc:5,key:1,each:1},
   {id:"sa_lat_pull",n:"Lat pulldown",r:10,w:30,inc:5,key:1,mult:2}]},
  {t:"Compound",items:[
   {id:"sa_db_ohp",n:"Dumbbell shoulder press",r:10,w:10,inc:5,each:1},
   {id:"sa_cbl_row",n:"Seated cable row",r:10,w:40,inc:5}]},
  {t:"Bonus · if time",items:[
   {id:"sa_db_curl",n:"Dumbbell bicep curl",r:12,w:10,inc:5,each:1},
   {id:"sa_cbl_tri",n:"Cable triceps extension",r:12,w:20,inc:5},
   {id:"sa_dead_bug",n:"Dead bug",r:10,w:0,inc:0,bw:1}]}]},
 2:{name:"Legs A",short:"LEG-A",blocks:[
  {t:"Basics · free weight",items:[
   {id:"sa_gob_squat",n:"Goblet squat",r:10,w:20,inc:5,key:1},
   {id:"sa_hip_thrust",n:"Hip thrust",r:12,w:65,inc:5,key:1}]},
  {t:"Compound",items:[
   {id:"sa_split_squat",n:"Dumbbell split squat (per leg)",r:10,w:10,inc:5,each:1},
   {id:"sa_sb_squat",n:"Single-leg box squat (per leg)",r:8,w:0,inc:5,bw:1}]},
  {t:"Bonus · if time",items:[
   {id:"sa_hip_abd",n:"Hip abduction",r:15,w:40,inc:5},
   {id:"sa_pallof",n:"Pallof press (per side)",r:12,w:15,inc:5}]}]},
 3:{name:"Upper B",short:"U-B",blocks:[
  {t:"Basics",items:[
   {id:"sa_db_incl",n:"Dumbbell incline press",r:10,w:12,inc:5,key:1,each:1},
   {id:"sa_pulldown2",n:"Assisted pull-up / lat pulldown",r:10,w:35,inc:5,key:1,mult:2}]},
  {t:"Compound",items:[
   {id:"sa_cs_row",n:"Chest-supported row",r:10,w:30,inc:5},
   {id:"sa_lat_raise",n:"Lateral raise",r:15,w:5,inc:5,each:1}]},
  {t:"Bonus · if time",items:[
   {id:"sa_hammer",n:"Hammer curls",r:12,w:10,inc:5,each:1},
   {id:"sa_rope_tri",n:"Rope triceps pushdown",r:15,w:20,inc:5},
   {id:"sa_side_plank",n:"Side plank (seconds per side)",r:20,w:0,inc:0,bw:1}]}]},
 4:{name:"Legs B",short:"LEG-B",blocks:[
  {t:"Warm-up · balance",items:[{id:"sa_sl_rdl",n:"Single-leg RDL, bodyweight (per leg)",r:10,w:0,inc:0,bw:1}]},
  {t:"Basics · free weight",items:[
   {id:"sa_rdl",n:"Dumbbell Romanian deadlift",r:10,w:30,inc:5,key:1},
   {id:"sa_step_up",n:"Dumbbell step-up (per leg)",r:10,w:10,inc:5,each:1,key:1}]},
  {t:"Compound",items:[
   {id:"sa_leg_press",n:"Leg press",r:12,w:90,inc:5,plates:1},
   {id:"sa_farmer",n:"Farmer carry (seconds)",r:30,w:20,inc:5,each:1}]},
  {t:"Bonus · if time",items:[
   {id:"sa_ham_curl",n:"Lying hamstring curl",r:12,w:30,inc:5}]}]}
};
/* Sofia's previous 3-day plan, kept so retired lifts still resolve in history. */
const PLAN_SA3={
 1:{name:"Upper A",short:"U-A",blocks:[
  {t:"Core · do first",items:[
   {id:"sa_dead_bug",n:"Dead bug",r:10,w:0,inc:0,bw:1},
   {id:"sa_pallof",n:"Pallof press (per side)",r:12,w:15,inc:5}]},
  {t:"Basics · free weight",items:[
   {id:"sa_db_bench",n:"Dumbbell bench press",r:8,w:15,inc:5,key:1,each:1},
   {id:"sa_lat_pull",n:"Lat pulldown",r:10,w:30,inc:5,key:1,mult:2}]},
  {t:"Compound",items:[
   {id:"sa_db_ohp",n:"Dumbbell shoulder press",r:10,w:10,inc:5,each:1},
   {id:"sa_cbl_row",n:"Seated cable row",r:10,w:40,inc:5}]},
  {t:"Isolation",items:[
   {id:"sa_m_fly",n:"Machine fly",r:12,w:40,inc:5},
   {id:"sa_cbl_tri",n:"Cable triceps extension",r:12,w:20,inc:5},
   {id:"sa_db_curl",n:"Dumbbell bicep curl",r:12,w:10,inc:5,each:1},
   {id:"sa_face_pull",n:"Face pull",r:15,w:15,inc:5}]}]},
 2:{name:"Legs",short:"LEG",blocks:[
  {t:"Core · do first",items:[{id:"sa_glute_bridge",n:"Glute bridge",r:15,w:0,inc:0,bw:1}]},
  {t:"Basics · free weight",items:[
   {id:"sa_gob_squat",n:"Goblet squat",r:10,w:20,inc:5,key:1},
   {id:"sa_rdl",n:"Dumbbell Romanian deadlift",r:10,w:30,inc:5,key:1}]},
  {t:"Compound",items:[{id:"sa_leg_press",n:"Leg press",r:12,w:90,inc:5,plates:1}]},
  {t:"Isolation",items:[
   {id:"sa_hip_thrust",n:"Hip thrust",r:12,w:65,inc:5},
   {id:"sa_ham_curl",n:"Lying hamstring curl",r:12,w:30,inc:5},
   {id:"sa_leg_ext",n:"Leg extension",r:12,w:40,inc:5},
   {id:"sa_calf",n:"Calf raise",r:15,w:50,inc:5}]}]},
 3:{name:"Upper B",short:"U-B",blocks:[
  {t:"Core · do first",items:[{id:"sa_side_plank",n:"Side plank (seconds per side)",r:20,w:0,inc:0,bw:1}]},
  {t:"Basics",items:[
   {id:"sa_db_incl",n:"Dumbbell incline press",r:10,w:12,inc:5,key:1,each:1},
   {id:"sa_pulldown2",n:"Assisted pull-up / lat pulldown",r:10,w:35,inc:5,key:1,mult:2}]},
  {t:"Compound",items:[
   {id:"sa_cs_row",n:"Chest-supported row",r:10,w:30,inc:5},
   {id:"sa_landmine",n:"Landmine press",r:10,w:20,inc:5}]},
  {t:"Isolation",items:[
   {id:"sa_lat_raise",n:"Lateral raise",r:15,w:5,inc:5,each:1},
   {id:"sa_rope_tri",n:"Rope triceps pushdown",r:15,w:20,inc:5},
   {id:"sa_hammer",n:"Hammer curls",r:12,w:10,inc:5,each:1}]}]}
};
/* Strength standards as a fraction of the profile's OWN bodyweight. */
const STD_FRAC_NR={bb_press:.90,lat_pull:.75,db_ohp:.25,db_row:.30,db_curl:.18,
  rdl:1.25,leg_press:2,db_incl:.33,bb_curl:.38};
const STD_FRAC_SA={sa_db_bench:.55,sa_lat_pull:.55,sa_db_ohp:.20,sa_db_incl:.25,
  sa_pulldown2:.50,sa_rdl:.85,sa_gob_squat:.85,sa_db_curl:.15};
const QMAP_NR={bb_press:"barbell bench press proper form",lat_pull:"lat pulldown proper form",
 db_ohp:"seated dumbbell shoulder press form",db_row:"one arm dumbbell row proper form",
 m_fly:"pec deck machine fly form",cbl_tri:"cable triceps pushdown form",
 db_curl:"dumbbell bicep curl proper form",face_pull:"cable face pull proper form",
 leg_raise:"hanging leg raise proper form",gob_squat:"goblet squat proper form",
 rdl:"romanian deadlift proper form",leg_press:"leg press proper form",
 ham_curl:"lying leg curl machine form",leg_ext:"leg extension machine form",
 calf:"standing calf raise form",plank:"plank proper form common mistakes",
 db_incl:"incline dumbbell bench press form",pullup:"assisted pull up proper form",
 cbl_row:"seated cable row proper form",bb_curl:"barbell curl proper form",
 lat_raise:"dumbbell lateral raise proper form",skull:"skull crusher ez bar proper form",
 hammer:"hammer curl proper form",cbl_crunch:"kneeling cable crunch proper form",
 pallof:"pallof press anti rotation proper form",
 hip_thrust:"barbell hip thrust proper form",split_squat:"dumbbell split squat proper form",
 hip_abd:"hip abduction machine glutes form",step_up:"dumbbell step up proper form",
 farmer:"farmer carry proper form",
 sb_squat:"single leg box squat proper form",sl_rdl:"bodyweight single leg romanian deadlift form"};
const QMAP_SA={sa_dead_bug:"dead bug exercise proper form",sa_db_bench:"dumbbell bench press proper form",
 sa_lat_pull:"lat pulldown proper form",sa_db_ohp:"seated dumbbell shoulder press form",
 sa_cbl_row:"seated cable row proper form",sa_m_fly:"pec deck machine fly form",
 sa_cbl_tri:"cable triceps pushdown form",sa_db_curl:"dumbbell bicep curl proper form",
 sa_face_pull:"cable face pull proper form",sa_glute_bridge:"glute bridge proper form",
 sa_gob_squat:"goblet squat proper form",sa_rdl:"dumbbell romanian deadlift proper form",
 sa_leg_press:"leg press proper form",sa_hip_thrust:"barbell hip thrust proper form",
 sa_ham_curl:"lying leg curl machine form",sa_leg_ext:"leg extension machine form",
 sa_calf:"standing calf raise form",sa_side_plank:"side plank proper form",
 sa_db_incl:"incline dumbbell bench press form",sa_pulldown2:"assisted pull up machine form",
 sa_cs_row:"chest supported row machine form",sa_landmine:"landmine press proper form",
 sa_lat_raise:"dumbbell lateral raise proper form",sa_rope_tri:"rope triceps pushdown form",
 sa_hammer:"hammer curl proper form",sa_pallof:"pallof press anti rotation proper form",
 sa_split_squat:"dumbbell split squat proper form",sa_hip_abd:"hip abduction machine glutes form",
 sa_step_up:"dumbbell step up proper form",sa_farmer:"farmer carry proper form",
 sa_sb_squat:"single leg box squat proper form",sa_sl_rdl:"bodyweight single leg romanian deadlift form"};

/* ================= MOVEMENT METADATA =================
   Keyed by concept so the two plans (and any generated one) share it.
   p = primary areas (full set credit), s = secondary (half credit),
   pat = movement pattern, load = structures an injury would rule out,
   alts = same-pattern substitutes. Alternates carry their OWN id so their
   numbers never fold into the exercise they replaced. */
const AREAS=['chest','back','shoulders','arms','glutes','hamstrings','quads','calves','core'];
const PAT_LABEL={hinge:"hip hinge",squat:"squat pattern","push-h":"horizontal press",
  "push-v":"overhead press","pull-v":"vertical pull","pull-h":"horizontal row",
  core:"trunk flexion","anti-ext":"anti-extension","anti-rot":"anti-rotation",
  "anti-lat":"anti-lateral-flexion",iso:"isolation work",single:"single-leg",carry:"loaded carry"};
const CONCEPT={
 core_flex:{p:['core'],pat:'core',load:['spine'],alts:[
   {id:"alt_hang_knee",n:"Hanging knee raise",frac:0,bw:1,inc:0},
   {id:"alt_lying_raise",n:"Lying leg raise",frac:0,bw:1,inc:0}]},
 core_antiext:{p:['core'],pat:'anti-ext',load:[],alts:[
   {id:"alt_dead_bug",n:"Dead bug",frac:0,bw:1,inc:0},
   {id:"alt_ab_wheel",n:"Ab wheel rollout",frac:0,bw:1,inc:0}]},
 core_antirot:{p:['core'],pat:'anti-rot',load:[],alts:[
   {id:"alt_band_pallof",n:"Band Pallof press",frac:0,bw:1,inc:0},
   {id:"alt_cable_chop",n:"Cable chop",frac:.15,inc:5}]},
 core_antilat:{p:['core'],pat:'anti-lat',load:[],alts:[
   {id:"alt_suitcase",n:"Suitcase carry",frac:.25,inc:5}]},
 bench:{p:['chest'],s:['arms','shoulders'],pat:'push-h',load:['shoulder'],alts:[
   {id:"alt_db_bench",n:"Dumbbell bench press",frac:.13,inc:5,each:1},
   {id:"alt_machine_press",n:"Chest press machine",frac:.60,inc:5}]},
 incline:{p:['chest'],s:['arms','shoulders'],pat:'push-h',load:['shoulder'],alts:[
   {id:"alt_incline_machine",n:"Incline press machine",frac:.50,inc:5},
   {id:"alt_incline_bb",n:"Incline barbell press",frac:.50,inc:5,bar:45}]},
 fly:{p:['chest'],pat:'iso',load:['shoulder'],alts:[
   {id:"alt_cable_fly",n:"Cable fly",frac:.20,inc:5},
   {id:"alt_db_fly",n:"Dumbbell fly",frac:.10,inc:5,each:1}]},
 ohp:{p:['shoulders'],s:['arms'],pat:'push-v',load:['shoulder'],alts:[
   {id:"alt_machine_ohp",n:"Shoulder press machine",frac:.35,inc:5},
   {id:"alt_landmine",n:"Landmine press",frac:.20,inc:5}]},
 side_delt:{p:['shoulders'],pat:'iso',load:['shoulder'],alts:[
   {id:"alt_cable_lat_raise",n:"Cable lateral raise",frac:.06,inc:5},
   {id:"alt_machine_lat_raise",n:"Lateral raise machine",frac:.20,inc:5}]},
 pulldown:{p:['back'],s:['arms'],pat:'pull-v',load:['shoulder','elbow'],alts:[
   {id:"alt_neutral_pulldown",n:"Neutral-grip pulldown",frac:.39,inc:5,mult:2},
   {id:"alt_assist_pullup",n:"Assisted pull-up machine",frac:.30,inc:5}]},
 pullup:{p:['back'],s:['arms'],pat:'pull-v',load:['shoulder','elbow'],alts:[
   {id:"alt_inverted_row",n:"Inverted row",frac:0,bw:1,inc:5},
   {id:"alt_assist_pullup2",n:"Assisted pull-up machine",frac:.30,inc:5}]},
 row:{p:['back'],s:['arms'],pat:'pull-h',load:['lowback'],alts:[
   {id:"alt_cs_row",n:"Chest-supported row",frac:.25,inc:5},
   {id:"alt_row_1arm",n:"Single-arm cable row",frac:.20,inc:5}]},
 rear_delt:{p:['shoulders'],s:['back'],pat:'iso',load:['shoulder'],alts:[
   {id:"alt_rear_delt_fly",n:"Rear delt fly",frac:.10,inc:5,each:1},
   {id:"alt_pull_apart",n:"Band pull-apart",frac:0,bw:1,inc:0}]},
 tri:{p:['arms'],pat:'iso',load:['elbow'],alts:[
   {id:"alt_rope_tri",n:"Rope pushdown",frac:.28,inc:5},
   {id:"alt_oh_tri",n:"Overhead cable extension",frac:.20,inc:5}]},
 curl:{p:['arms'],pat:'iso',load:['elbow'],alts:[
   {id:"alt_cable_curl",n:"Cable curl",frac:.20,inc:5},
   {id:"alt_ez_curl",n:"EZ-bar curl",frac:.25,inc:5,bar:25}]},
 squat:{p:['quads','glutes'],s:['core'],pat:'squat',load:['knee','spine','lowback'],alts:[
   {id:"alt_hack_squat",n:"Hack squat",frac:.50,inc:10},
   {id:"alt_split_squat",n:"Bulgarian split squat",frac:.13,inc:5,each:1}]},
 legpress:{p:['quads','glutes'],pat:'squat',load:['knee'],alts:[
   {id:"alt_hack_squat2",n:"Hack squat",frac:.50,inc:10},
   {id:"alt_single_leg_press",n:"Single-leg press",frac:.35,inc:10}]},
 hinge:{p:['hamstrings','glutes'],s:['back'],pat:'hinge',load:['spine','lowback'],alts:[
   {id:"alt_db_rdl",n:"Dumbbell RDL",frac:.26,inc:5,each:1},
   {id:"alt_back_ext",n:"45° back extension",frac:0,bw:1,inc:5}]},
 hipthrust:{p:['glutes'],s:['hamstrings'],pat:'hinge',load:[],alts:[
   {id:"alt_single_thrust",n:"Single-leg hip thrust",frac:.15,inc:5},
   {id:"alt_glute_bridge",n:"Glute bridge",frac:0,bw:1,inc:5}]},
 hamcurl:{p:['hamstrings'],pat:'iso',load:['knee'],alts:[
   {id:"alt_seated_ham",n:"Seated hamstring curl",frac:.40,inc:5},
   {id:"alt_nordic",n:"Nordic curl (assisted)",frac:0,bw:1,inc:0}]},
 legext:{p:['quads'],pat:'iso',load:['knee'],alts:[
   {id:"alt_sissy",n:"Sissy squat",frac:0,bw:1,inc:0}]},
 calf:{p:['calves'],pat:'iso',load:[],alts:[
   {id:"alt_seated_calf",n:"Seated calf raise",frac:.25,inc:10}]},
 glute_iso:{p:['glutes'],pat:'iso',load:[],alts:[
   {id:"alt_abductor",n:"Hip abductor machine",frac:.30,inc:5}]},
 single_leg:{p:['quads','glutes'],s:['hamstrings'],pat:'single',load:['knee'],alts:[
   {id:"alt_reverse_lunge",n:"Reverse lunge (per leg)",frac:.13,inc:5,each:1},
   {id:"alt_bss",n:"Bulgarian split squat (per leg)",frac:.13,inc:5,each:1}]},
 abduction:{p:['glutes'],pat:'iso',load:[],alts:[
   {id:"alt_cable_abd",n:"Cable hip abduction (per side)",frac:.05,inc:5},
   {id:"alt_band_walk",n:"Banded lateral walk (steps per side)",frac:0,bw:1,inc:0}]},
 sl_hinge:{p:['hamstrings','glutes'],s:['core'],pat:'single',load:[],alts:[
   {id:"alt_sl_rdl_db",n:"Single-leg RDL with dumbbell (per leg)",frac:.10,inc:5},
   {id:"alt_sl_stand",n:"Single-leg stand, eyes closed (seconds per leg)",frac:0,bw:1,inc:0}]},
 carry:{p:['core'],s:['back'],pat:'carry',load:['lowback'],alts:[
   {id:"alt_suitcase_carry",n:"Suitcase carry (seconds per side)",frac:.26,inc:5},
   {id:"alt_dead_hang",n:"Dead hang (seconds)",frac:0,bw:1,inc:0}]}
};
const CONCEPT_OF={
 /* NR */
 leg_raise:'core_flex', cbl_crunch:'core_flex', plank:'core_antiext', pallof:'core_antirot',
 bb_press:'bench', db_incl:'incline', m_fly:'fly', db_ohp:'ohp', lat_raise:'side_delt',
 lat_pull:'pulldown', pullup:'pullup', db_row:'row', cbl_row:'row', face_pull:'rear_delt',
 cbl_tri:'tri', skull:'tri', db_curl:'curl', bb_curl:'curl', hammer:'curl',
 gob_squat:'squat', leg_press:'legpress', rdl:'hinge', ham_curl:'hamcurl',
 leg_ext:'legext', calf:'calf',
 hip_thrust:'hipthrust', split_squat:'single_leg', step_up:'single_leg',
 hip_abd:'abduction', farmer:'carry', sb_squat:'single_leg', sl_rdl:'sl_hinge',
 /* SA */
 sa_dead_bug:'core_antiext', sa_side_plank:'core_antilat', sa_glute_bridge:'glute_iso',
 sa_pallof:'core_antirot',
 sa_db_bench:'bench', sa_db_incl:'incline', sa_m_fly:'fly', sa_db_ohp:'ohp',
 sa_landmine:'ohp', sa_lat_raise:'side_delt', sa_lat_pull:'pulldown', sa_pulldown2:'pulldown',
 sa_cbl_row:'row', sa_cs_row:'row', sa_face_pull:'rear_delt',
 sa_cbl_tri:'tri', sa_rope_tri:'tri', sa_db_curl:'curl', sa_hammer:'curl',
 sa_gob_squat:'squat', sa_leg_press:'legpress', sa_rdl:'hinge', sa_hip_thrust:'hipthrust',
 sa_ham_curl:'hamcurl', sa_leg_ext:'legext', sa_calf:'calf',
 sa_split_squat:'single_leg', sa_step_up:'single_leg', sa_hip_abd:'abduction', sa_farmer:'carry', sa_sb_squat:'single_leg', sa_sl_rdl:'sl_hinge',
 /* focus / injury additions */
 fx_hip_thrust:'hipthrust', fx_kickback:'glute_iso', fx_seated_ham:'hamcurl',
 fx_incline_curl:'curl', fx_cable_lat:'side_delt', fx_pullover:'row', fx_cable_fly:'fly',
 fx_cs_row:'row', fx_pull_apart:'rear_delt', fx_back_ext:'hinge', fx_m_fly2:'fly'
};
const EMPTY_META={p:[],s:[],pat:'',load:[],alts:[]};
function metaOf(id){
  const c=CONCEPT_OF[id];
  if(c&&CONCEPT[c])return CONCEPT[c];
  // an alternate inherits the metadata of the concept that owns it
  for(const k in CONCEPT){ if(CONCEPT[k].alts.some(a=>a.id===id)) return CONCEPT[k]; }
  return EMPTY_META;
}

/* ================= FOCUS AREAS =================
   Emphasis ADDS volume. Nothing is ever removed from the base plan to make room.
   Each note has to earn its place by contradicting the common assumption. */
const FOCUS={
 glutes:{label:"GLUTES",target:12,bump:'hipthrust',
  note:"Volume is rarely the real limiter. The usual pattern is a tucked pelvis under load, where the glutes never fully shorten — so extra sets just add fatigue. Test it first: a hip thrust should be felt in the glutes, not the lower back or the hamstrings.",
  add:[{day:2,block:"Basics · free weight",match:"hip thrust",primary:1,
        ex:{id:"fx_hip_thrust",n:"Hip thrust",r:10,frac:.55,inc:5,key:1}},
       {day:2,block:"Isolation",match:"kickback",
        ex:{id:"fx_kickback",n:"Cable kickback",r:15,frac:.10,inc:5}}]},
 hamstrings:{label:"HAMSTRINGS",target:10,bump:'hamcurl',
  note:"You cannot reduce fat over a muscle by training that muscle. Spot reduction does not work — leanness comes from the deficit, and this only builds what sits underneath it.",
  add:[{day:2,block:"Isolation",match:"seated hamstring",
        ex:{id:"fx_seated_ham",n:"Seated hamstring curl",r:12,frac:.40,inc:5}}]},
 arms:{label:"ARMS",target:12,bump:'curl',
  note:"Biceps already work on every row and pulldown in the plan. The usual gap is total pulling volume, not curls — check how much back work is actually in the week before adding more direct arm work.",
  add:[{day:3,block:"Isolation",match:"incline curl",
        ex:{id:"fx_incline_curl",n:"Incline dumbbell curl",r:12,frac:.12,inc:5,each:1}}]},
 shoulders:{label:"SHOULDERS",target:12,bump:'side_delt',
  note:"Front delts are already covered by every press you do. Side delts are what is missing, and they respond to frequency and lighter high-rep work far more than to heavy pressing.",
  add:[{day:1,block:"Isolation",match:"cable lateral",
        ex:{id:"fx_cable_lat",n:"Cable lateral raise",r:15,frac:.06,inc:5}}]},
 core:{label:"CORE",target:10,
  note:"Abs are visible at low body fat and are trained like any other muscle — crunches do not burn belly fat. A longer plank mostly builds tolerance for being bored, so this adds sets, not minutes, and they stay at the front of the session.",
  add:[]},   /* deliberately sets-only: no fourth exercise, no longer holds */
 back:{label:"BACK",target:12,bump:'pulldown',
  note:"Vertical pulling and horizontal rowing are not interchangeable and most people are short on one of them. Check the split before adding volume — three rows and no pulldown is a gap, not a preference.",
  add:[{day:1,block:"Compound",match:"pullover",
        ex:{id:"fx_pullover",n:"Cable pullover",r:12,frac:.25,inc:5}}]},
 chest:{label:"CHEST",target:12,bump:'fly',
  note:"Flat versus incline matters less than most people think. What usually limits chest growth is load in the stretched position at the bottom — pressing through a short, comfortable range skips exactly the part that drives it.",
  add:[{day:3,block:"Isolation",match:"cable fly",
        ex:{id:"fx_cable_fly",n:"Cable fly",r:12,frac:.20,inc:5}}]}
};

/* ================= INJURIES =================
   Flag the injury; the app infers which exercises it rules out, states what that
   costs in weekly volume, and offers substitutes that avoid the loaded structure. */
const INJURIES={
 spine:{label:"RIB / SPINE",loads:['spine'],
  why:"Neither a leg curl nor a hip thrust loads the spine the way a bar on your back or a loaded hinge does.",
  subs:[{day:2,block:"Isolation",match:"seated hamstring",
         ex:{id:"fx_seated_ham",n:"Seated hamstring curl",r:12,frac:.40,inc:5}},
        {day:2,block:"Isolation",match:"hip thrust",
         ex:{id:"fx_hip_thrust",n:"Hip thrust",r:12,frac:.55,inc:5}}]},
 lowback:{label:"LOWER BACK",loads:['lowback','spine'],
  why:"Supported and machine-based work keeps the hamstrings and glutes loaded without asking the lower back to brace a free weight.",
  subs:[{day:2,block:"Isolation",match:"seated hamstring",
         ex:{id:"fx_seated_ham",n:"Seated hamstring curl",r:12,frac:.40,inc:5}},
        {day:2,block:"Isolation",match:"hip thrust",
         ex:{id:"fx_hip_thrust",n:"Hip thrust",r:12,frac:.55,inc:5}}]},
 shoulder:{label:"SHOULDER",loads:['shoulder'],
  why:"Chest-supported rowing and light band work keep the upper back moving without overhead or bench loading.",
  subs:[{day:1,block:"Compound",match:"chest-supported",
         ex:{id:"fx_cs_row",n:"Chest-supported row",r:12,frac:.25,inc:5}},
        {day:1,block:"Isolation",match:"pull-apart",
         ex:{id:"fx_pull_apart",n:"Band pull-apart",r:20,frac:0,inc:0,bw:1}}]},
 knee:{label:"KNEE",loads:['knee'],
  why:"Hip-dominant work loads the glutes and hamstrings without bending the knee under load.",
  subs:[{day:2,block:"Basics · free weight",match:"hip thrust",
         ex:{id:"fx_hip_thrust",n:"Hip thrust",r:12,frac:.55,inc:5,key:1}},
        {day:2,block:"Isolation",match:"back extension",
         ex:{id:"fx_back_ext",n:"45° back extension",r:15,frac:0,inc:0,bw:1}}]},
 elbow:{label:"ELBOW / WRIST",loads:['elbow'],
  why:"Machine pressing and fly work keeps chest and shoulder volume up while the elbow settles.",
  subs:[{day:1,block:"Isolation",match:"machine fly",
         ex:{id:"fx_m_fly2",n:"Machine fly",r:15,frac:.60,inc:5}}]}
};
const NAG_DAYS=14;

/* Every exercise definition the app knows about, so a lift that has since left the
   plan (a released injury substitute, an alternate you used once) still resolves
   in history instead of silently vanishing from the progression list. */
const EX_INDEX={};
(function(){
  const add=x=>{ if(x&&x.id&&!EX_INDEX[x.id])EX_INDEX[x.id]={...x} };
  [PLAN_NR,PLAN_NR3,PLAN_SA,PLAN_SA3].forEach(P=>Object.keys(P).forEach(d=>P[d].blocks.forEach(b=>b.items.forEach(add))));
  Object.keys(CONCEPT).forEach(k=>(CONCEPT[k].alts||[]).forEach(add));
  Object.keys(FOCUS).forEach(k=>(FOCUS[k].add||[]).forEach(sp=>add(sp.ex)));
  Object.keys(INJURIES).forEach(k=>(INJURIES[k].subs||[]).forEach(sp=>add(sp.ex)));
})();
const exById=id=>(typeof ALL!=='undefined'&&ALL.find(x=>x.id===id))||EX_INDEX[id]||null;
/* ---- BUG: volume was computed three different ways (live counter, endSession,
   and the edit recalc), so a session's number jumped as soon as you edited it.
   One formula now: per-side dumbbells and dual cables both move 2x the logged weight. */
const volOf=(id,w,reps)=>{
  const ex=exById(id)||{}, f=(ex.mult||1)*(ex.each?2:1);
  if(/second/i.test(ex.n||''))return 0;   // timed holds/carries are not lb moved
  return (reps||[]).reduce((a,r)=>a+((r||0)*(w||0)*f),0);
};

/* Experience level drives starting load and increment for GENERATED plans only. */
const EXP={
  "new":      {f:.50, inc:5,   label:"New to lifting"},
  "returning":{f:.75, inc:5,   label:"Returning"},
  "trained":  {f:1.0, inc:null,label:"Trained"}   // null = keep the template's own increment
};

/* ================= STORAGE KEYS ================= */
const KEY_BASE="strata:v1";
const ACTIVE_KEY="strata:active";
const PROFILES_KEY="strata:profiles";
const keyFor=id=>KEY_BASE+":"+id;

function newId(){return "p_"+Date.now().toString(36)+Math.random().toString(36).slice(2,7)}
function defaultDB(planKey){
  return {next:{},history:[],active:null,
          holds: planKey==='nr' ? {rdl:1} : {},
          cycleStarts:[],
          focus:null, injuries:[], cycleAnchor:null,    // anchor() sets this on first use
          cardio:[], age:null};                          // recomp week: cardio/jumps log, age for HR zones
}

/* ================= STATE ================= */
let profiles=[];
let profile=null;           // the active profile OBJECT
let DB=defaultDB('nr');
let editIdx=null, preLowEnergy=false, setupOpen=false, altOpen=null, celebration=null, focusedExId=null;
let view=1;                 // rotation day 1..3, only meaningful when viewMode==='strength'
let viewMode='strength';    // strength | easy | rest | history | recomp
let hydrated=false, dirty=false, storageOK=null;

const store={
 async get(key){if(window.storage){try{const r=await window.storage.get(key);return r?r.value:null}catch(e){}}
   try{return localStorage.getItem(key)}catch(e){return null}},
 async set(key,v){if(window.storage){try{await window.storage.set(key,v);return}catch(e){}}
   try{localStorage.setItem(key,v)}catch(e){}}
};
async function save(){
  dirty=true;
  const payload=JSON.stringify(DB);
  try{
    await store.set(keyFor(profile.id),payload);
    const back=await store.get(keyFor(profile.id));
    storageOK = back===payload;
  }catch(e){ storageOK=false; }
  const chip=document.getElementById('sv');
  if(chip)chip.outerHTML=svChip();
}
async function saveProfiles(){ try{ await store.set(PROFILES_KEY, JSON.stringify(profiles)); }catch(e){} }
const svChip=()=>storageOK===false
  ? `<span class="sv bad" id="sv">NOT SAVING — open the file locally</span>`
  : (storageOK===true?`<span class="sv ok" id="sv">SAVED</span>`:`<span class="sv" id="sv">…</span>`);

/* ================= DATES (local time, never UTC) ================= */
const today=()=>{const d=new Date();
  return new Date(d.getTime()-d.getTimezoneOffset()*6e4).toISOString().slice(0,10);};
const dayDiff=(a,b)=>Math.round((new Date(b)-new Date(a))/864e5);
const fmtLocal=d=>`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
/* Monday-based weekday index, 0=Mon .. 6=Sun */
/* The 7-day block is a ROLLING cycle anchored to the day you started it, not Mon–Sun.
   Start on a Thursday and that Thursday is D1. */
const anchor=()=>{ if(!DB.cycleAnchor)DB.cycleAnchor=today(); return DB.cycleAnchor };
const cycleIdx=ds=>{const n=dayDiff(anchor(),ds); return ((n%7)+7)%7};
const blockStartOf=ds=>addDays(anchor(), Math.floor(dayDiff(anchor(),ds)/7)*7);
const addDays=(ds,n)=>{const d=new Date(ds+'T00:00:00');d.setDate(d.getDate()+n);return fmtLocal(d)};
const DOW=["D1","D2","D3","D4","D5","D6","D7"];

/* ================= ACTIVE PLAN ================= */
let PLAN, BW, STD, QMAP, ALL;
const items=d=>PLAN[d].blocks.flatMap(b=>b.items);
/* Rotation length comes from the plan itself: 4 days for the Upper/Legs plan, 3 for SA. */
const daysOf=P=>Object.keys(P).map(Number).sort((a,b)=>a-b);
const DAYS=()=>daysOf(PLAN);
const round5=v=>Math.max(0,Math.round(v/5)*5);

/* Generate a plan for a profile that has no bespoke one, from bodyweight × experience. */
function genPlan(bw,exp){
  const e=EXP[exp]||EXP.trained, out={};
  daysOf(PLAN_NR).forEach(d=>{
    const src=PLAN_NR[d];
    out[d]={name:src.name,short:src.short,blocks:src.blocks.map(b=>({t:b.t,items:b.items.map(ex=>{
      const o={...ex};
      if(!ex.bw){
        let w=round5((ex.frac||0)*bw*e.f);
        if(ex.bar && w<ex.bar) w=ex.bar;       // never prescribe below the empty bar
        o.w=w;
      }
      if(ex.inc) o.inc = e.inc==null ? ex.inc : e.inc;
      return o;
    })}))};
  });
  return out;
}
function planFor(p){
  if(p.plan==='nr')return PLAN_NR;
  if(p.plan==='sa')return PLAN_SA;
  return genPlan(p.bw,p.exp);
}
function stdFor(p){
  const frac = p.plan==='sa' ? STD_FRAC_SA : STD_FRAC_NR;
  const out={}; Object.keys(frac).forEach(k=>out[k]=frac[k]*p.bw); return out;
}
/* Derive a load for anything that is not part of a bespoke plan
   (alternates, focus additions, injury substitutes). */
function deriveW(spec){
  if(spec.bw)return 0;
  const e=EXP[profile.exp]||EXP.trained;
  let w=round5((spec.frac||0)*profile.bw*e.f);
  if(spec.bar && w<spec.bar)w=spec.bar;
  return w;
}
function mkEx(spec){
  const e=EXP[profile.exp]||EXP.trained, o={...spec};
  o.w=deriveW(spec);
  if(spec.inc)o.inc = e.inc==null ? spec.inc : e.inc;
  return o;
}
function clonePlan(p){
  const out={};
  daysOf(p).forEach(d=>{out[d]={name:p[d].name,short:p[d].short,
    blocks:p[d].blocks.map(b=>({t:b.t,items:b.items.map(x=>({...x}))}))}});
  return out;
}
function findByMatch(plan,match){
  const m=(match||'').toLowerCase(); if(!m)return null;
  for(const d of daysOf(plan))for(const b of plan[d].blocks)
    for(const x of b.items) if(x.n.toLowerCase().includes(m))return {d,b,x};
  return null;
}
function appendEx(plan,spec){
  const found=findByMatch(plan,spec.match);
  if(found){
    /* already in the plan — promote it to the primary block rather than duplicating it,
       so an emphasis movement stops being an afterthought at the end of the session */
    if(spec.primary && found.d===spec.day){
      const bs=plan[spec.day].blocks, dest=bs.find(b=>b.t===spec.block);
      if(dest && dest!==found.b){
        found.b.items=found.b.items.filter(i=>i!==found.x);
        found.x.key=1; dest.items.push(found.x);
      }
    }
    return false;
  }
  const bs=plan[spec.day].blocks;
  (bs.find(b=>b.t===spec.block)||bs[bs.length-1]).items.push(mkEx(spec.ex));
  return true;
}
/* Emphasis = two extra sets on the priority pattern. Core is sets-only and stays
   at the front, one exercise per day rather than inflating every core movement. */
function applyBump(plan,area){
  if(area==='core'){
    daysOf(plan).forEach(d=>{
      for(const b of plan[d].blocks){
        const x=b.items.find(i=>(metaOf(i.id).p||[]).includes('core'));
        if(x){x.sets=5;break}
      }
    });
    return;
  }
  const f=FOCUS[area]; let target=null;
  if(f&&f.bump)daysOf(plan).forEach(d=>plan[d].blocks.forEach(b=>b.items.forEach(x=>{
    if(CONCEPT_OF[x.id]===f.bump)target=x })));
  if(!target){
    const hits=[];
    daysOf(plan).forEach(d=>plan[d].blocks.forEach(b=>b.items.forEach(x=>{
      if((metaOf(x.id).p||[]).includes(area))hits.push(x)})));
    target=hits[hits.length-1];
  }
  if(target)target.sets=(target.sets||3)+2;
}
function idsForInjury(key,plan){
  const def=INJURIES[key]; if(!def)return[];
  const out=[];
  daysOf(plan).forEach(d=>plan[d].blocks.forEach(b=>b.items.forEach(x=>{
    if((metaOf(x.id).load||[]).some(l=>def.loads.includes(l)))out.push(x.id)})));
  return [...new Set(out)];
}
const injuredIds=()=>{const s=new Set();
  (DB.injuries||[]).forEach(i=>(i.ids||[]).forEach(id=>s.add(id)));return s};

let ALT_OF={};
function setActivePlan(){
  BW   = profile.bw;
  STD  = stdFor(profile);
  QMAP = profile.plan==='sa' ? QMAP_SA : QMAP_NR;
  const base=clonePlan(planFor(profile));

  /* injury substitutes first, so emphasis can still bump one if it wants to */
  (DB.injuries||[]).forEach(i=>{
    const def=INJURIES[i.key]; if(def)def.subs.forEach(s=>appendEx(base,s));
  });
  const f=DB.focus&&FOCUS[DB.focus];
  if(f){ f.add.forEach(s=>appendEx(base,s)); applyBump(base,DB.focus); }

  const inj=injuredIds();
  daysOf(base).forEach(d=>base[d].blocks.forEach(b=>b.items.forEach(x=>{
    if(inj.has(x.id))x.injured=1})));
  PLAN=base;

  /* ALL carries the alternates too, so a swapped lift resolves in history,
     progression and the session summary exactly like a planned one. */
  const list=DAYS().flatMap(d=>items(d));
  const alts=[];
  list.forEach(x=>(metaOf(x.id).alts||[]).forEach(a=>{
    if(!alts.some(y=>y.id===a.id))alts.push(mkEx({...a,r:x.r}))}));
  ALL=list.concat(alts);
  ALT_OF={};
  list.forEach(x=>{ALT_OF[x.id]=(metaOf(x.id).alts||[])
    .map(a=>alts.find(y=>y.id===a.id)).filter(Boolean)});
}

/* ================= VOLUME ACCOUNTING ================= */
function weekDays(){ return DAYS(); }
/* Weekly sets per area. Injured exercises count as zero — that is the whole point:
   a hold nobody notices is a hole in the week, not a lift that is merely frozen. */
function setsForPlan(planObj,skip){
  const inj=injuredIds(), acc={}; AREAS.forEach(a=>acc[a]=0);
  daysOf(planObj).forEach(d=>planObj[d].blocks.forEach(b=>b.items.forEach(ex=>{
    if((skip&&skip.has(ex.id))||inj.has(ex.id))return;
    const m=metaOf(ex.id), n=ex.sets||3;
    (m.p||[]).forEach(a=>{if(acc[a]!=null)acc[a]+=n});
    (m.s||[]).forEach(a=>{if(acc[a]!=null)acc[a]+=n/2});
  })));
  return acc;
}
const weeklySets=extraSkip=>setsForPlan(PLAN,new Set(extraSkip||[]));
/* the week as it would be with NO emphasis applied — what the diagnosis reports */
function baselineSets(){
  const base=clonePlan(planFor(profile));
  (DB.injuries||[]).forEach(i=>{const def=INJURIES[i.key]; if(def)def.subs.forEach(sp=>appendEx(base,sp))});
  return setsForPlan(base,null);
}
function patternsLost(ids){
  const skip=new Set(ids||[]), inj=injuredIds(), all={}, live={};
  weekDays().forEach(d=>PLAN[d].blocks.forEach(b=>b.items.forEach(ex=>{
    const p=metaOf(ex.id).pat; if(!p)return;
    all[p]=(all[p]||0)+1;
    if(!skip.has(ex.id)&&!inj.has(ex.id))live[p]=(live[p]||0)+1;
  })));
  return Object.keys(all).filter(p=>!live[p]);
}
const fmtSets=v=>Number.isInteger(v)?String(v):v.toFixed(1);
/* What a hold would cost, stated before it is applied. */
function costOf(ids){
  const before=weeklySets([]), after=weeklySets(ids);
  const drops=AREAS.filter(a=>after[a]<before[a]-.01)
    .map(a=>({area:a,from:before[a],to:after[a]}))
    .sort((x,y)=>(x.to-x.from)-(y.to-y.from));
  return {drops, lost:patternsLost(ids)};
}
function costHTML(key,ids){
  const c=costOf(ids), def=INJURIES[key];
  if(!ids.length)return `<div class="cost">Nothing in your current week loads that, so nothing changes.</div>`;
  const lostTxt=c.lost.length
    ? `Holding these removes your only <b>${c.lost.map(p=>PAT_LABEL[p]||p).join('</b> and <b>')}</b>. `
    : '';
  const dropTxt=c.drops.length
    ? c.drops.slice(0,3).map(d=>`${d.area} ${fmtSets(d.from)} → <b>${fmtSets(d.to)}</b>`).join(', ')+' sets/week.'
    : 'No area loses volume.';
  return `<div class="cost">${lostTxt}${dropTxt}<br><br>${def.why}</div>`;
}

/* ================= ACCENT ================= */
const INK=[15,21,24], BLACK=[0,0,0], WHITE=[255,255,255];
function hex2rgb(h){h=(h||'#43A177').replace('#','');
  if(h.length===3)h=h.split('').map(c=>c+c).join('');
  return [parseInt(h.slice(0,2),16)||0,parseInt(h.slice(2,4),16)||0,parseInt(h.slice(4,6),16)||0]}
const mix=(a,b,t)=>a.map((v,i)=>Math.round(v+(b[i]-v)*t));
const rgb2hex=r=>'#'+r.map(v=>Math.max(0,Math.min(255,v)).toString(16).padStart(2,'0')).join('');
function applyAccent(){
  const c=hex2rgb(profile&&profile.accent), s=document.body.style;
  s.setProperty('--accent', rgb2hex(c));
  s.setProperty('--accentText', rgb2hex(mix(c,BLACK,.88)));
  s.setProperty('--accentDim', rgb2hex(mix(c,INK,.78)));
  s.setProperty('--accentBright', rgb2hex(mix(c,WHITE,.35)));
  s.setProperty('--accentBorder', rgb2hex(mix(c,INK,.55)));
  s.setProperty('--accentGradA', rgb2hex(mix(c,INK,.86)));
  s.setProperty('--accentGlow', `rgba(${c[0]},${c[1]},${c[2]},.2)`);
}

const lastOf=id=>{for(let i=DB.history.length-1;i>=0;i--){const e=DB.history[i].entries[id];
  if(e)return{...e,date:DB.history[i].date}}return null};
const INVERSE_LOAD_IDS=new Set(['alt_assist_pullup','alt_assist_pullup2']);
const inverseLoad=ex=>!!(ex&&INVERSE_LOAD_IDS.has(ex.id));
const progressedWeight=(ex,w)=>inverseLoad(ex)?Math.max(0,w-ex.inc):w+ex.inc;
const wOf=ex=>{
  const next=DB.next[ex.id];
  /* Repair an already-saved target produced by the old assisted-pull-up bug. */
  if(inverseLoad(ex)&&next!=null&&ex.inc){
    const l=lastOf(ex.id);
    if(l&&next===l.w+ex.inc){
      DB.next[ex.id]=Math.max(0,l.w-ex.inc);
      return DB.next[ex.id];
    }
  }
  return next!=null?next:ex.w;
};
const toast=m=>{if(!m)return;const t=document.getElementById('toast');t.textContent=m;t.classList.add('show');
  clearTimeout(t._x);t._x=setTimeout(()=>{t.classList.remove('show');t.textContent=''},2800)};

const eff=(ex,w)=>(w==null?wOf(ex):w)*(ex.mult||1);
function badge(ex,raw){
  const s=STD[ex.id];
  if(!s)return `<span class="badge b0" title="No cross-gym standard — just progress it">TRACK</span>`;
  const e=eff(ex,raw), p=e/s, tip=`${e} lb effective of ~${Math.round(s)} lb target`;
  if(p>=.90)return `<span class="badge b4" title="${tip}">OPTIMAL</span>`;
  if(p>=.70)return `<span class="badge b3" title="${tip}">CLOSE</span>`;
  if(p>=.45)return `<span class="badge b2" title="${tip}">BUILDING</span>`;
  return `<span class="badge b1" title="${tip}">NEEDS BOOST</span>`;
}
const PLATES=[45,35,25,10,5,2.5];
function plateLine(ex,total){
  if(!ex.bar)return'';
  const bt=ex.bar===45?'45 lb bar':ex.bar+' lb EZ bar';
  if(total<ex.bar)return `<span class="warn">below the bar (${bt})</span>`;
  if(total===ex.bar)return `<span class="bar45">${bt} only</span>`;
  let side=(total-ex.bar)/2,out=[];
  PLATES.forEach(p=>{while(side>=p-.001){out.push(p);side=+(side-p).toFixed(2)}});
  return `<span class="bar45">${bt} +</span> ${out.map(p=>`<span class="pl">${p}</span>`).join(' ')}`
    +` <span class="bar45">per side</span>`+(side>.001?` <span class="warn">+${side} short</span>`:'');
}
function loEnergyW(ex,w){
  if(!w)return 0;
  return Math.max(0, Math.floor((w*0.85)/5)*5);
}
const RC_Q={rc_pogo:"pogo hops exercise how to",rc_box:"box jump step down beginner form",
  rc_4x4:"norwegian 4x4 interval training treadmill",rc_z2:"zone 2 incline treadmill walk"};
const ytURL=ex=>`https://www.youtube.com/results?search_query=${encodeURIComponent(QMAP[ex.id]||RC_Q[ex.id]||ex.n+' proper form')}`;
const vid=ex=>`<button class="vid" data-yt="${ex.id}" title="Form video" aria-label="Form video"><svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg></button>`;
/* A real link click: window.open(...,'noopener') always returns null, which used to
   trigger the "link copied" fallback even when the video had opened. */
function openVid(ex){
  const a=document.createElement('a'); a.href=ytURL(ex); a.target='_blank'; a.rel='noopener';
  document.body.appendChild(a); a.click(); a.remove();
}

/* ================= WEEK / CARDIO ================= */
/* ================= REST-DAY GATE =================
   Only strength sessions are logged, so this gate sees the whole picture. */
function gate(){
  const last=DB.history[DB.history.length-1];
  if(!last)return{ok:1,msg:"First session. Nothing logged yet."};
  const gap=dayDiff(last.date,today());
  if(gap===0)return{ok:0,hard:0,msg:`You already trained <b>${PLAN[last.day].name}</b> today. Two sessions in one day is not more progress, it is less recovery — only override to catch up a missed log.`};
  const region=d=>/^legs/i.test((PLAN[d]&&PLAN[d].name)||'')?'legs':'upper';
  if(gap===1&&PLAN[last.day]&&region(last.day)!==region(view))return{ok:1,msg:`You trained <b>${PLAN[last.day].name}</b> yesterday, so today's ${region(view)==='legs'?'legs are':'upper body is'} fresh.`};
  if(gap===1)return{ok:0,hard:0,msg:`You trained <b>${PLAN[last.day].name}</b> yesterday. Give the same muscles a day: do the other half, or a walk.`};
  return{ok:1,msg:`Last strength session: <b>${PLAN[last.day].name}</b>, ${gap} days ago.`};
}
function nextDay(){
  const last=DB.history[DB.history.length-1];
  const n=DAYS().length;
  return last&&last.day<=n?(last.day%n)+1:1;
}
function cycleDone(){
  let set=new Set();
  DB.history.forEach(h=>{ set.add(h.day); if(set.size>=DAYS().length) set=new Set(); });
  return set;
}
/* Menstrual-cycle day — logged only, never used to alter any prescription. */
function cycleDayNum(){
  if(!DB.cycleStarts||!DB.cycleStarts.length)return null;
  const last=[...DB.cycleStarts].sort().slice(-1)[0];
  return dayDiff(last,today())+1;
}

/* "Bonus · if time" and warm-up blocks are optional: they never count against finishing a
   session, and low-energy days drop them (plus any legacy Isolation block). */
const isOptionalBlock=t=>/^(bonus|warm-up|isolation)/i.test(t||'');
const requiredItems=day=>PLAN[day].blocks.filter(b=>!isOptionalBlock(b.t)).flatMap(b=>b.items);
const MIN_PER_LIFT=12;   // measured: ~12 minutes per lift including setup and rest
function sessionItems(day,lowEnergy){
  return PLAN[day].blocks.filter(b=>!(lowEnergy&&isOptionalBlock(b.t))).flatMap(b=>b.items);
}
function applyInjury(key){
  if(!INJURIES[key]||(DB.injuries||[]).some(i=>i.key===key))return;
  const ids=idsForInjury(key,PLAN);
  const c=costOf(ids);                     // measured while they still count as trained
  const added=ids.filter(id=>!DB.holds[id]);   // never clobber a pre-existing manual hold
  DB.injuries=DB.injuries||[];
  DB.injuries.push({key,since:today(),ids,added,cost:c});
  ids.forEach(id=>{DB.holds[id]=1});
  setActivePlan(); save(); render();
  toast(ids.length?`${INJURIES[key].label} flagged · ${ids.length} exercise${ids.length===1?'':'s'} held`
                 : `${INJURIES[key].label} flagged · nothing in your week loads that`);
}
function releaseInjury(key){
  const rec=(DB.injuries||[]).find(i=>i.key===key); if(!rec)return;
  DB.injuries=(DB.injuries||[]).filter(i=>i.key!==key);
  const still=injuredIds();
  (rec.added||rec.ids||[]).forEach(id=>{ if(!still.has(id)) delete DB.holds[id]; });
  setActivePlan(); save(); render();
  toast(`${INJURIES[key].label} released · progression resumes`);
}
function rcHR(){
  const a=+DB.age; if(!a||a<14||a>99)return null;
  const max=Math.round(208-0.7*a);                     // Tanaka estimate
  return {max, z2:[Math.round(max*.6),Math.round(max*.7)], hard:[Math.round(max*.85),Math.round(max*.95)]};
}
function rcPhases(n){
  const ph=[{k:'easy',label:'Warm-up · easy',sec:600}];
  for(let i=1;i<=n;i++){
    ph.push({k:'hard',label:`Interval ${i} of ${n} · hard`,sec:240});
    if(i<n) ph.push({k:'easy',label:`Recover ${i} of ${n-1} · easy`,sec:180});
  }
  ph.push({k:'easy',label:'Cool-down',sec:300});
  return ph;
}
const rcMinutes=n=>10+n*4+(n-1)*3+5;
const mmss=s=>`${Math.floor(s/60)}:${String(Math.max(0,Math.floor(s%60))).padStart(2,'0')}`;
function cue(){
  try{ navigator.vibrate&&navigator.vibrate([220,90,220]); }catch(e){}
  try{
    const C=window.AudioContext||window.webkitAudioContext; if(!C)return;
    const ctx=cue.ctx||(cue.ctx=new C()); if(ctx.state==='suspended')ctx.resume();
    const o=ctx.createOscillator(), g=ctx.createGain(); o.frequency.value=880;
    g.gain.setValueAtTime(.0001,ctx.currentTime); g.gain.exponentialRampToValueAtTime(.3,ctx.currentTime+.02);
    g.gain.exponentialRampToValueAtTime(.0001,ctx.currentTime+.45); o.connect(g).connect(ctx.destination); o.start(); o.stop(ctx.currentTime+.5);
  }catch(e){}
}
async function lockScreen(on){
  try{
    if(on&&navigator.wakeLock&&!wakeLock){ wakeLock=await navigator.wakeLock.request('screen'); }
    if(!on&&wakeLock){ await wakeLock.release(); wakeLock=null; }
  }catch(e){ wakeLock=null; }
}
const rc4x4Count=()=>(DB.cardio||[]).filter(c=>c.type==='4x4').length;
const rcDefaultIntervals=()=>rc4x4Count()<3?3:4;
