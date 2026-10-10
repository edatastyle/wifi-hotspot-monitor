<?php
/*
 * Developed by: Md. Saiful Islam
 * Email: e2getway@gmail.com
 * Website: https://edatastyle.com/
 */

require __DIR__ . '/../lib.php';
if (isset($_GET['logout'])) { session_destroy(); header('Location: ./'); exit; }
$err = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && !authed()) {
    if (hash_equals(cfg('username'), $_POST['u'] ?? '') && password_verify($_POST['p'] ?? '', cfg('password_hash'))) {
        session_regenerate_id(true); $_SESSION['u'] = 1; header('Location: ./'); exit;
    }
    $err = 'Invalid username or password';
}
$css = <<<'CSS'
:root{--bg:#0f1419;--panel:#1a2332;--ink:#e7ecf3;--mute:#8b9bb4;--line:#2a3548;--ok:#3dd68c;--bad:#f07178;--accent:#59c2ff}
*{box-sizing:border-box}body{margin:0;font:15px/1.45 system-ui,sans-serif;background:var(--bg);color:var(--ink)}
header{display:flex;justify-content:space-between;align-items:center;padding:14px 18px;border-bottom:1px solid var(--line)}
h1{font-size:18px;margin:0}nav a{color:var(--mute);margin-left:14px;text-decoration:none}nav a.on{color:var(--accent)}
button,.btn{background:var(--panel);border:1px solid var(--line);color:var(--ink);padding:6px 12px;border-radius:4px;cursor:pointer}
button.primary{background:var(--accent);color:#0f1419;border-color:transparent}
button.danger{background:transparent;border-color:var(--bad);color:var(--bad)}
input,select{background:var(--bg);border:1px solid var(--line);color:var(--ink);padding:6px 10px;border-radius:4px}
.wrap{padding:16px 18px}#spark{background:var(--panel);border:1px solid var(--line);border-radius:6px;padding:8px 12px;margin-top:12px}
#spark svg{width:100%;height:56px;display:block}
.card{background:var(--panel);border:1px solid var(--line);border-radius:6px;overflow:auto}
table{border-collapse:collapse;width:100%;min-width:900px}th{text-align:left;font-weight:600;color:var(--mute);padding:8px 12px;border-bottom:1px solid var(--line)}
td{padding:9px 12px;border-bottom:1px solid var(--line);vertical-align:top;font-variant-numeric:tabular-nums}
.m{font-family:ui-monospace,monospace;font-size:13px}tr.off td:not(.act){opacity:.55}.act{white-space:nowrap}.act button{margin:0 3px 3px 0}
.bar{display:flex;gap:10px;align-items:center;flex-wrap:wrap;margin-bottom:12px}.tag{color:var(--bad);font-weight:600}
.cols{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:14px}.cols section{background:var(--panel);border:1px solid var(--line);border-radius:6px;padding:14px}
h2{font-size:16px;margin:0 0 8px}ul{list-style:none;margin:10px 0 0;padding:0}li{display:flex;justify-content:space-between;gap:8px;align-items:center;padding:6px 0;border-top:1px solid var(--line)}
li.e{color:var(--mute)}label{display:inline-block;margin:0 14px 8px 0}.chips button{margin:0 6px 6px 0}
footer{margin:24px 0 8px;color:var(--mute);font-size:13px}footer a{color:var(--ok)}
#toast{position:fixed;bottom:16px;left:50%;transform:translateX(-50%);background:var(--ink);color:#fff;padding:8px 14px;border-radius:4px;display:none}
.login{max-width:340px;margin:12vh auto;background:var(--panel);border:1px solid var(--line);border-radius:6px;padding:22px}.login input{width:100%;margin:6px 0 12px}
@media(prefers-reduced-motion:no-preference){tr{transition:opacity .2s}}
CSS;
if (!authed()) { ?><!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Hotspot sign in</title>
<style><?= $css ?></style><form class="login" method="post"><h1>Hotspot manager</h1><br>
<label for="u">Username</label><input id="u" name="u" autocomplete="username" required>
<label for="p">Password</label><input id="p" name="p" type="password" autocomplete="current-password" required>
<footer>By <a href="https://edatastyle.com/">Md. Saiful Islam</a></footer><?php if ($err) echo '<p class="tag">' . htmlspecialchars($err) . '</p>'; ?><button class="primary">Sign in</button></form><?php exit; }
$tok = csrf();
?><!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Hotspot manager</title>
<style><?= $css ?></style>
<header><h1>Hotspot Manager</h1><nav>
<a href="#" data-tab="devices" class="on">Devices</a>
<a href="#" data-tab="rules">Rules</a>
<a href="#" data-tab="activity">Activity</a>
<a href="#" data-tab="diagnose">Diagnose</a>
<a href="?logout=1">Sign out</a>
</nav></header>
<div class="wrap">
<div class="bar">
<button class="primary" id="restart">Restart hotspot</button>
<button id="apply">Apply rules</button>
<span id="status" class="mute"></span>
</div>
<div id="devices" class="tab">
<div class="card"><table><thead><tr><th>Device</th><th>IP</th><th>MAC</th><th>Vendor / OS</th><th>Signal</th><th>Actions</th></tr></thead><tbody id="devbody"></tbody></table></div>
</div>
<div id="rules" class="tab" hidden>
<div class="cols">
<section><h2>Block domains</h2>
<input id="dom" placeholder="example.com"> <button id="blockdom">Block</button>
<ul id="domlist"></ul></section>
<section><h2>Block / allow MAC</h2>
<input id="mac" placeholder="aa:bb:cc:dd:ee:ff"> <button id="blockmac">Block</button> <button id="allowmac">Allow</button>
<ul id="maclist"></ul></section>
</div></div>
<div id="activity" class="tab" hidden>
<div class="card"><pre id="log" class="m" style="padding:12px;max-height:420px;overflow:auto"></pre></div>
</div>
<div id="diagnose" class="tab" hidden>
<button id="rundiag">Run check</button>
<ul id="diaglist"></ul>
</div>
<footer>Hotspot Manager by <a href="https://edatastyle.com/" target="_blank" rel="noopener">Md. Saiful Islam</a></footer>
</div><div id="toast" role="status"></div>
<script>
const tok = <?= json_encode($tok) ?>;
let tab = 'devices', state = {};
const $ = s => document.querySelector(s);
const esc = s => String(s??'').replace(/[&<>"']/g, c => ({'&':'&','<':'<','>':'>','"':'"',"'":'&#39;'}[c]));
function toast(m){const t=$('#toast');t.textContent=m;t.style.display='block';setTimeout(()=>t.style.display='none',2200)}
async function api(a, body={}){
  const r = await fetch('api.php?a='+encodeURIComponent(a), {method: body && Object.keys(body).length ? 'POST':'GET',
    headers: {'X-CSRF': tok, 'Content-Type': 'application/x-www-form-urlencoded'},
    body: body && Object.keys(body).length ? new URLSearchParams(body) : null});
  return r.json();
}
function renderDevices(devs){
  $('#devbody').innerHTML = (devs||[]).map(d => `<tr class="${d.blocked?'off':''}">
    <td>${esc(d.name||d.hostname||'—')}</td><td class="m">${esc(d.ip)}</td><td class="m">${esc(d.mac)}</td>
    <td>${esc(d.vendor)} <small>${esc(d.os)}</small></td><td>${d.signal??'—'}</td>
    <td class="act">
      <button data-a="kick" data-mac="${esc(d.mac)}">Kick</button>
      <button data-a="${d.blocked?'unblock-mac':'block-mac'}" data-mac="${esc(d.mac)}">${d.blocked?'Unblock':'Block'}</button>
    </td></tr>`).join('') || '<tr><td colspan="6">No devices yet. Connect a phone to the hotspot.</td></tr>';
}
function renderRules(s){
  state = s || state;
  $('#domlist').innerHTML = (state.blocked_domains||[]).map(d=>`<li>${esc(d)} <button data-a="unblock-domain" data-domain="${esc(d)}">×</button></li>`).join('') || '<li class="e">None</li>';
  $('#maclist').innerHTML = [...(state.blocked_macs||[]).map(m=>`<li>Block ${esc(m)} <button data-a="unblock-mac" data-mac="${esc(m)}">×</button></li>`),
    ...(state.allowed_macs||[]).map(m=>`<li>Allow ${esc(m)} <button data-a="disallow-mac" data-mac="${esc(m)}">×</button></li>`)].join('') || '<li class="e">None</li>';
}
async function poll(){
  const j = await api('overview');
  if (!j.ok) { $('#status').textContent = j.error||'Error'; return; }
  renderDevices(j.devices); renderRules(j.state); $('#status').textContent = (j.devices||[]).length + ' devices';
}
async function loadLogs(){
  const j = await api('logs');
  if (j.ok) $('#log').textContent = (j.lines||[]).slice(-80).join('');
}
document.querySelectorAll('[data-tab]').forEach(a=>a.onclick=e=>{e.preventDefault();tab=a.dataset.tab;
  document.querySelectorAll('[data-tab]').forEach(x=>x.classList.toggle('on',x===a));
  document.querySelectorAll('.tab').forEach(t=>t.hidden = t.id!==tab);
  if (tab==='activity') loadLogs();
});
document.body.addEventListener('click', async e=>{
  const b = e.target.closest('button[data-a]'); if (!b) return;
  const a = b.dataset.a, body = {};
  if (b.dataset.mac) body.mac = b.dataset.mac;
  if (b.dataset.domain) body.domain = b.dataset.domain;
  const j = await api(a, body); toast(j.ok ? 'Done' : (j.error||'Failed')); poll();
});
$('#blockdom').onclick = async ()=>{ const d=$('#dom').value.trim(); if(!d)return; await api('block-domain',{domain:d}); $('#dom').value=''; poll();};
$('#blockmac').onclick = async ()=>{ const m=$('#mac').value.trim(); if(!m)return; await api('block-mac',{mac:m}); poll();};
$('#allowmac').onclick = async ()=>{ const m=$('#mac').value.trim(); if(!m)return; await api('allow-mac',{mac:m}); poll();};
$('#restart').onclick = async ()=>{ const j=await api('restart-hotspot'); toast(j.ok?'Hotspot restarted':(j.error||'Failed'));};
$('#apply').onclick = async ()=>{ const j=await api('apply'); toast(j.ok?'Rules applied':(j.error||'Failed'));};
$('#rundiag').onclick = async ()=>{ const j=await api('diagnose'); $('#diaglist').innerHTML=(j.checks||[]).map(c=>`<li>${c.ok?'OK':'Problem'}: ${esc(c.title)} <small>${esc(c.detail)}</small></li>`).join('');};
poll(); setInterval(poll, 3000); setInterval(()=>tab==='activity'&&loadLogs(), 5000);
</script>
