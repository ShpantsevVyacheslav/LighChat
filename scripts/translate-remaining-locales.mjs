import fs from 'node:fs';
import ts from 'typescript';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);

const WEB_LOCALES = [
  { code: 'ru', exportName: 'messagesRu', file: 'src/lib/i18n/messages/ru.ts', tl: 'ru' },
  { code: 'kk', exportName: 'messagesKk', file: 'src/lib/i18n/messages/kk.ts', tl: 'kk' },
  { code: 'uz', exportName: 'messagesUz', file: 'src/lib/i18n/messages/uz.ts', tl: 'uz' },
  { code: 'tr', exportName: 'messagesTr', file: 'src/lib/i18n/messages/tr.ts', tl: 'tr' },
  { code: 'id', exportName: 'messagesId', file: 'src/lib/i18n/messages/id.ts', tl: 'id' },
  { code: 'pt-BR', exportName: 'messagesPtBr', file: 'src/lib/i18n/messages/pt-BR.ts', tl: 'pt' },
  { code: 'es-MX', exportName: 'messagesEsMx', file: 'src/lib/i18n/messages/es-MX.ts', tl: 'es' },
];

const MOBILE_LOCALES = [
  { code: 'kk', file: 'mobile/app/lib/l10n/app_kk.arb', tl: 'kk' },
  { code: 'uz', file: 'mobile/app/lib/l10n/app_uz.arb', tl: 'uz' },
  { code: 'tr', file: 'mobile/app/lib/l10n/app_tr.arb', tl: 'tr' },
  { code: 'id', file: 'mobile/app/lib/l10n/app_id.arb', tl: 'id' },
  { code: 'pt', file: 'mobile/app/lib/l10n/app_pt.arb', tl: 'pt' },
  { code: 'pt_BR', file: 'mobile/app/lib/l10n/app_pt_BR.arb', tl: 'pt' },
  { code: 'es', file: 'mobile/app/lib/l10n/app_es.arb', tl: 'es' },
  { code: 'es_MX', file: 'mobile/app/lib/l10n/app_es_MX.arb', tl: 'es' },
];

const WEB_SKIP_PATHS = new Set([
  'settings.language.en',
]);

const MOBILE_SKIP_KEYS = new Set([
  'settings_language_en',
]);

function escapeSingle(str) {
  return str.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\r/g, '\\r').replace(/\n/g, '\\n');
}

function loadTsObject(file, exportName) {
  const src = fs.readFileSync(file, 'utf8');
  const out = ts.transpileModule(src, {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 },
  }).outputText;
  const m = { exports: {} };
  new Function('exports', 'module', 'require', out)(m.exports, m, require);
  return m.exports[exportName];
}

function flatten(obj, prefix = '', out = {}) {
  for (const [k, v] of Object.entries(obj || {})) {
    const p = prefix ? `${prefix}.${k}` : k;
    if (v && typeof v === 'object' && !Array.isArray(v)) flatten(v, p, out);
    else if (typeof v === 'string') out[p] = v;
  }
  return out;
}

function unwrapObject(expr) {
  if (!expr) return null;
  if (ts.isObjectLiteralExpression(expr)) return expr;
  if (ts.isSatisfiesExpression(expr) || ts.isAsExpression(expr) || ts.isParenthesizedExpression(expr)) {
    return unwrapObject(expr.expression);
  }
  return null;
}

function collectStringNodes(sf, objExpr, prefix = '', out = []) {
  for (const prop of objExpr.properties) {
    if (!ts.isPropertyAssignment(prop)) continue;
    let key = null;
    if (ts.isIdentifier(prop.name)) key = prop.name.text;
    else if (ts.isStringLiteral(prop.name) || ts.isNoSubstitutionTemplateLiteral(prop.name)) key = prop.name.text;
    if (!key) continue;
    const path = prefix ? `${prefix}.${key}` : key;
    const init = prop.initializer;
    const nested = unwrapObject(init);
    if (nested) collectStringNodes(sf, nested, path, out);
    else if (ts.isStringLiteral(init) || ts.isNoSubstitutionTemplateLiteral(init)) out.push({ path, node: init });
  }
  return out;
}

function protectTokens(text) {
  let t = text;
  const map = [];

  const protect = (regex, wrap) => {
    t = t.replace(regex, (m) => {
      const id = map.length;
      const token = `__LC_TOKEN_${id}__`;
      map.push({ token, value: m, wrap });
      return wrap ? `<span class=\"notranslate\">${token}</span>` : token;
    });
  };

  protect(/\{\w+\}/g, true);
  protect(/%\d*\$?[sd]/gi, true);
  protect(/\bLighChat\b/g, true);
  protect(/\bE2EE\b/g, true);
  protect(/\bGIPHY\b/g, true);
  protect(/\bGIF\b/g, true);
  protect(/\bQR\b/g, true);

  return { text: t, map };
}

function unprotectTokens(text, map) {
  let out = text.replace(/<\/?span[^>]*>/g, '');
  for (const { token, value } of map) {
    out = out.replaceAll(token, value);
  }
  return out;
}

const translateCache = new Map();

async function translatePhraseSet(phrases, tl, label) {
  const out = new Map();
  const queue = [...phrases];
  const total = queue.length;
  let done = 0;

  const workers = Array.from({ length: 8 }, async () => {
    while (queue.length > 0) {
      const phrase = queue.shift();
      if (phrase === undefined) return;
      const translated = await translateText(phrase, tl);
      out.set(phrase, translated);
      done += 1;
      if (done % 100 === 0 || done === total) {
        console.log(`[${label}] progress ${done}/${total}`);
      }
    }
  });

  await Promise.all(workers);
  return out;
}

async function translateText(text, tl) {
  const key = `${tl}:::${text}`;
  if (translateCache.has(key)) return translateCache.get(key);

  if (!/[A-Za-z]/.test(text)) {
    translateCache.set(key, text);
    return text;
  }

  const { text: safe, map } = protectTokens(text);
  const url = new URL('https://translate.googleapis.com/translate_a/single');
  url.searchParams.set('client', 'gtx');
  url.searchParams.set('sl', 'en');
  url.searchParams.set('tl', tl);
  url.searchParams.set('dt', 't');
  url.searchParams.set('q', safe);

  let lastError = null;
  for (let attempt = 1; attempt <= 3; attempt++) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 12000);
    try {
      const res = await fetch(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0',
          'Accept': 'application/json,text/plain,*/*',
        },
        signal: controller.signal,
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const json = await res.json();
      const translated = (json?.[0] || []).map((x) => x?.[0] || '').join('');
      const finalText = unprotectTokens(translated || text, map);
      translateCache.set(key, finalText);
      return finalText;
    } catch (err) {
      lastError = err;
      if (attempt < 3) await new Promise((r) => setTimeout(r, 500 * attempt));
    } finally {
      clearTimeout(timeoutId);
    }
  }

  console.warn(`[warn] translate fallback tl=${tl} text=${JSON.stringify(text).slice(0, 120)} err=${String(lastError)}`);
  translateCache.set(key, text);
  return text;
}

async function translateWeb() {
  const en = flatten(loadTsObject('src/lib/i18n/messages/en.ts', 'messagesEn'));

  for (const locale of WEB_LOCALES) {
    const data = flatten(loadTsObject(locale.file, locale.exportName));
    const pending = [];
    for (const k of Object.keys(en)) {
      if (WEB_SKIP_PATHS.has(k)) continue;
      if (data[k] === en[k]) pending.push(k);
    }

    const uniq = [...new Set(pending.map((k) => en[k]))];
    const phraseMap = await translatePhraseSet(uniq, locale.tl, `web:${locale.code}`);

    const byPath = new Map();
    for (const k of pending) {
      const enValue = en[k];
      const translated = phraseMap.get(enValue);
      if (translated && translated !== enValue) byPath.set(k, translated);
    }

    const src = fs.readFileSync(locale.file, 'utf8');
    const sf = ts.createSourceFile(locale.file, src, ts.ScriptTarget.Latest, true, ts.ScriptKind.TS);

    let rootObject = null;
    sf.forEachChild((node) => {
      if (!ts.isVariableStatement(node)) return;
      for (const decl of node.declarationList.declarations) {
        if (!ts.isIdentifier(decl.name) || decl.name.text !== locale.exportName) continue;
        rootObject = unwrapObject(decl.initializer);
      }
    });

    if (!rootObject) continue;

    const nodes = collectStringNodes(sf, rootObject);
    const edits = [];
    for (const { path, node } of nodes) {
      const rep = byPath.get(path);
      if (!rep) continue;
      edits.push({ start: node.getStart(sf), end: node.getEnd(), text: `'${escapeSingle(rep)}'` });
    }

    edits.sort((a, b) => b.start - a.start);
    let out = src;
    for (const e of edits) out = out.slice(0, e.start) + e.text + out.slice(e.end);
    if (edits.length > 0) fs.writeFileSync(locale.file, out, 'utf8');

    console.log(`[web:${locale.code}] pending=${pending.length}, translated=${edits.length}`);
  }
}

async function translateMobile() {
  const en = JSON.parse(fs.readFileSync('mobile/app/lib/l10n/app_en.arb', 'utf8'));

  for (const locale of MOBILE_LOCALES) {
    const file = locale.file;
    const data = JSON.parse(fs.readFileSync(file, 'utf8'));
    const keys = [];

    for (const [k, v] of Object.entries(en)) {
      if (k.startsWith('@')) continue;
      if (MOBILE_SKIP_KEYS.has(k)) continue;
      if (typeof v !== 'string') continue;
      if (typeof data[k] !== 'string') continue;
      if (data[k] === v) keys.push(k);
    }

    const uniq = [...new Set(keys.map((k) => en[k]))];
    const phraseMap = await translatePhraseSet(uniq, locale.tl, `mobile:${locale.code}`);

    let changed = 0;
    for (const k of keys) {
      const enValue = en[k];
      const translated = phraseMap.get(enValue);
      if (translated && translated !== enValue) {
        data[k] = translated;
        changed++;
      }
    }

    fs.writeFileSync(file, JSON.stringify(data, null, 2) + '\n', 'utf8');
    console.log(`[mobile:${locale.code}] pending=${keys.length}, translated=${changed}`);
  }
}

await translateWeb();
await translateMobile();

console.log('Done');
