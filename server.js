// ==========================
// VORTX-HUB  |  single-file
// ==========================
require('dotenv').config();
const express = require('express');
const helmet  = require('helmet');
const cors    = require('cors');
const multer  = require('multer');
const path    = require('path');
const fs      = require('fs');
const { v4: uuid } = require('uuid');
const { execSync } = require('child_process');

const app  = express();
const PORT = process.env.PORT || 3000;

// ---------- SUPER-STRONG ADMIN KEY ----------
// generate:  node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
const ADMIN_KEY = process.env.ADMIN_KEY ||
                  'a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456';

// ---------- WHITELIST EXECUTOR ----------
// tambah string baru di sini (case-insensitive)
const ALLOWED_UA = new RegExp(
  [
    'Roblox', 'Synapse', 'KRNL', 'Fluxus', 'ScriptWare', 'Electron',
    'Wave', 'OxygenU', 'Comet', 'Delta', 'Trigon', 'Valyse',
    'Hydrogen', 'Arceus X', 'Calamari', 'Tropical', 'JJSploit',
    'Sirhurt', 'Sentinel', 'Proxo', 'Shadow', 'Vega X', 'Coco',
    'Exoliner', 'Nihon', 'Solara', 'Codex', 'Furk Ultra', 'Aztup',
    'Temple', 'Dagger', 'SwagMode', 'Mukuro', 'Linoria'
  ].join('|'),
  'i'
);

// ---------- CONFIG ----------
const uploads   = multer({ dest: 'tmp/' });
const scripts   = path.join(__dirname, 'protected');
if (!fs.existsSync(scripts)) fs.mkdirSync(scripts);
const ALLOWED_ORIGIN = ['roblox.com', 'rbxcdn.com', 'roblox.qq.com'];

// ---------- MIDDLEWARE ----------
app.use(helmet());
app.use(cors({ origin: false }));
app.set('view engine', 'ejs');
app.use(express.json());
app.use(express.static('public'));

// ---------- TOKEN STORE ----------
const tokens = new Map();

// ---------- HELPERS ----------
function obfuscate(raw) {
  const tmp = path.join(__dirname, 'tmp', uuid() + '.lua');
  fs.writeFileSync(tmp, raw);
  try {
    execSync(`IronBrew_CLI.lua --input "${tmp}" --output "${tmp}.obf"`, { stdio: 'pipe' });
    const out = fs.readFileSync(tmp + '.obf', 'utf8');
    fs.unlinkSync(tmp); fs.unlinkSync(tmp + '.obf');
    return out;
  } catch {
    if (!process.env.LURAPH_API) throw new Error('Obfuscator unavailable');
    return execSync(`curl -s -X POST https://api.luraph.net/obfuscate --data-binary @"${tmp}" -H "Authorization: ${process.env.LURAPH_API}"`, { encoding: 'utf8' });
  }
}

// ---------- ROUTES ----------
// 1. Admin upload page
app.get('/admin', (req, res) => {
  if (req.query.key !== ADMIN_KEY) return res.status(401).send('Unauthorized');
  res.render('upload'); // upload.ejs inline di bawah
});

// 2. Handle upload
app.post('/upload', uploads.single('file'), (req, res) => {
  if (req.query.key !== ADMIN_KEY) return res.status(401).send('Unauthorized');
  const raw = fs.readFileSync(req.file.path, 'utf8');
  const obf = obfuscate(raw);
  const id  = uuid();
  fs.writeFileSync(path.join(scripts, id + '.lua'), obf);
  fs.unlinkSync(req.file.path);
  res.json({ url: `https://yourdomain.com/payload/${id}` });
});

// 3. Get one-time token
app.get('/get-token', (req, res) => {
  const ua = req.get('user-agent') || '';
  const origin = req.get('origin') || '';
  if (!ALLOWED_UA.test(ua) || !ALLOWED_ORIGIN.some(o => origin.includes(o))) {
    return res.status(403).send('Forbidden');
  }
  const token = uuid();
  tokens.set(token, Date.now());
  res.json({ token });
});

// 4. Download payload
app.get('/payload/:id', (req, res) => {
  const { id } = req.params;
  const token  = req.query.t;
  if (!tokens.has(token) || Date.now() - tokens.get(token) > 60000) {
    return res.status(403).send('Token invalid/expired');
  }
  tokens.delete(token);
  const file = path.join(scripts, id + '.lua');
  if (!fs.existsSync(file)) return res.status(404).send('Not found');
  res.set('Content-Type', 'text/plain');
  res.sendFile(file);
});

// ---------- INLINE SIMPLE UPLOAD PAGE ----------
app.set('views', './'); // agar bisa pakar inline
app.engine('ejs', require('ejs').renderFile);
const uploadHTML = `
<!doctype html>
<title>VortX-Hub Upload</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>body{font-family:sans-serif;padding:2rem}</style>
<h2>Upload new Lua script</h2>
<form action="/upload?key=<%= key %>" method="post" enctype="multipart/form-data">
  <input type="file" name="file" accept=".lua" required><br><br>
  <select name="obfuscator">
    <option value="ironbrew">IronBrew (free)</option>
    <option value="luraph">Luraph (API key required)</option>
  </select><br><br>
  <button type="submit">Upload & Obfuscate</button>
</form>
`;
fs.writeFileSync('upload.ejs', uploadHTML);

// ---------- START ----------
app.listen(PORT, () => console.log(`VortX-Hub listening on :${PORT}`));
