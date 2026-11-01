/* Loads the web app (core.js, app.js, workout.js) into a Node vm with a stubbed DOM,
   the way index.html loads it. sensors.demo.js is deliberately NOT loaded.
   Used by make-fixtures.mjs and make-catalog.mjs. */
import vm from 'node:vm';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const read = f => fs.readFileSync(path.join(ROOT, f), 'utf8');

export async function loadWeb(tz) {
  if (tz) process.env.TZ = tz;
  const state = {now: Date.parse('2026-11-02T08:00:00-05:00')};
  const toasts = [], confirms = [];
  const flags = {confirm: true};
  const els = new Map(), docListeners = {};

  const mkEl = sel => {
    const t = {dataset: {}, style: {setProperty() {}}, classList: {add() {}, remove() {}, toggle() {}},
      innerHTML: '', textContent: '', value: '', hidden: false, listeners: {}, id: sel.startsWith('#') ? sel.slice(1) : ''};
    return new Proxy(t, {
      get(o, p) {
        if (p in o) return o[p];
        if (p === 'addEventListener') return (ev, fn) => { (o.listeners[ev] = o.listeners[ev] || []).push(fn); };
        if (p === 'querySelectorAll') return () => [];
        return () => undefined;
      },
      set(o, p, v) { o[p] = v; if (sel === '#toast' && p === 'textContent' && v) toasts.push(v); return true; }
    });
  };
  const getEl = sel => { if (!els.has(sel)) els.set(sel, mkEl(sel)); return els.get(sel); };

  class MockDate extends Date {
    constructor(...a) { if (a.length) super(...a); else super(state.now); }
    static now() { return state.now; }
  }
  const sandbox = {
    document: {
      querySelector: getEl, getElementById: id => getEl('#' + id), querySelectorAll: () => [],
      createElement: () => mkEl('x'), body: getEl('body'), hidden: false,
      addEventListener: (ev, fn) => { (docListeners[ev] = docListeners[ev] || []).push(fn); }
    },
    navigator: {}, localStorage: {getItem: () => null, setItem() {}},
    setInterval: () => 0, clearInterval() {}, setTimeout: () => 0, clearTimeout() {},
    confirm: m => { confirms.push(m); return flags.confirm; },
    Date: MockDate, console
  };
  sandbox.window = {scrollTo() {}};
  const context = vm.createContext(sandbox);
  for (const f of ['core.js', 'app.js', 'workout.js'])
    new vm.Script(read(f), {filename: f}).runInContext(context);
  await new Promise(r => setImmediate(r));          // let the async boot finish
  const run = code => vm.runInContext(code, context);
  // The fixtures exercise logic, not rendering.
  run('onboard=null; render=function(){}; go=function(s){prevScr=scr;scr=s}; renderRest=function(){}; blockSheet=function(){}; openSheet=function(){}; closeSheet=function(){}');
  return {run, state, toasts, confirms, flags, docListeners, getEl, context};
}
