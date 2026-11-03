import { readdir, readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
async function walk(dir){return(await Promise.all((await readdir(dir,{withFileTypes:true})).map(e=>e.isDirectory()?walk(`${dir}/${e.name}`):`${dir}/${e.name}`))).flat();}
const files=(await walk('dist')).filter(f=>!f.endsWith('/sw.js')).sort();
const hash=createHash('sha256');for(const f of files)hash.update(await readFile(f));
const cache='pension-public-'+hash.digest('hex').slice(0,16),urls=files.map(f=>'/'+f.slice(5));
await writeFile('dist/sw.js',`
const CACHE=${JSON.stringify(cache)},PUBLIC=${JSON.stringify(urls)};
self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(PUBLIC))));
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith('pension-public-')&&k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('message',e=>{if(e.data?.type==='SKIP_WAITING')self.skipWaiting();});
self.addEventListener('fetch',e=>{
 const u=new URL(e.request.url);
 // NEVER cache API requests, PDFs, payment callbacks, external SDKs, or user data.
 if(e.request.method!=='GET'||u.origin!==self.location.origin||u.pathname.startsWith('/api/'))return;
 if(e.request.mode==='navigate'){e.respondWith(fetch(e.request).catch(()=>caches.match('/index.html')));return;}
 if(PUBLIC.includes(u.pathname))e.respondWith(caches.match(u.pathname).then(hit=>hit||fetch(e.request)));
});
`);
console.log(`Generated offline service worker: ${urls.length} public assets, ${cache}`);
