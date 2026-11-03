import type { D1Database, ScheduledEvent } from '@cloudflare/workers-types';
import { z, ZodError } from 'zod';
import { calculate } from '../src/core/engine';
import { PensionError, requestSchema, type Report } from '../src/core/models';
import { PRICE_PAISE, RazorpayGateway, digest, signatureValid, matchesCaptured } from './gateway';
import { createPDF } from './pdf';
export interface Env {
  DB: D1Database; ASSETS?: {fetch:(request:Request)=>Promise<Response>}; APP_ORIGIN: string; PAYMENTS_MODE: 'disabled'|'test'|'live';
  RAZORPAY_KEY_ID?: string; RAZORPAY_KEY_SECRET?: string; RAZORPAY_WEBHOOK_SECRET?: string;
  LIVE_PAYMENTS_CONFIRMED?: string; MERCHANT_NAME?: string; SUPPORT_EMAIL?: string;
}
interface Order { id:string; session_hash:string; request_key:string; gateway_order_id:string|null; payment_id:string|null; state:string; server_verified:number; webhook_verified:number; report:string|null; created_at:number; expires_at:number }
const now = () => Math.floor(Date.now()/1000);
class HttpError extends Error { constructor(public status:number,message:string) { super(message); } }
const json = (body:unknown,status=200,headers?:HeadersInit) => new Response(JSON.stringify(body),{status,headers:{'Content-Type':'application/json',...headers}});
function config(env:Env) {
  if(!['test','live'].includes(env.PAYMENTS_MODE)) throw new HttpError(503,'Paid reports are not enabled. The basic calculator remains free.');
  if(!env.RAZORPAY_KEY_ID || !env.RAZORPAY_KEY_SECRET || !env.RAZORPAY_WEBHOOK_SECRET) throw new HttpError(503,'Payment configuration is incomplete.');
  const prefix=env.PAYMENTS_MODE==='test'?'rzp_test_':'rzp_live_';
  if(!env.RAZORPAY_KEY_ID.startsWith(prefix)) throw new HttpError(503,'Payment key mode mismatch.');
  if(env.PAYMENTS_MODE==='live' && (env.LIVE_PAYMENTS_CONFIRMED!=='merchant-owned-account-verified' || !env.MERCHANT_NAME || !env.SUPPORT_EMAIL)) throw new HttpError(503,'Merchant launch configuration is incomplete.');
  return {keyId:env.RAZORPAY_KEY_ID,secret:env.RAZORPAY_KEY_SECRET,webhookSecret:env.RAZORPAY_WEBHOOK_SECRET};
}
async function limitedBody(req:Request) {
  const max=32768;
  if(Number(req.headers.get('Content-Length')??0)>max) throw new HttpError(413,'Request is too large.');
  if(!req.body) throw new HttpError(400,'Request body required.');
  const reader=req.body.getReader(); const chunks:Uint8Array[]=[];let size=0;
  while(true) { const {value,done}=await reader.read();if(done) break;size+=value.length;if(size>max) {await reader.cancel();throw new HttpError(413,'Request is too large.');}chunks.push(value); }
  const merged=new Uint8Array(size);let at=0;for(const chunk of chunks){merged.set(chunk,at);at+=chunk.length;}return new TextDecoder().decode(merged);
}
function sameOrigin(req:Request,env:Env) {
  if(req.headers.get('Origin')!==env.APP_ORIGIN) throw new HttpError(403,'Request origin is not allowed.');
}
function cookieName(env:Env) {return env.APP_ORIGIN.startsWith('https://')?'__Host-pension_session':'pension_session';}
function sessionToken(req:Request,env:Env): string|null {
  const match=req.headers.get('Cookie')?.match(new RegExp('(?:^|;\\s*)'+cookieName(env)+'=([a-f0-9]{64})(?:;|$)'));return match?.[1]??null;
}
async function session(req:Request,env:Env) {
  const token=sessionToken(req,env);if(!token) throw new HttpError(401,'Start a secure checkout session first.');return digest(token);
}
async function rateLimit(env:Env,key:string,limit:number) {
  const minute=Math.floor(now()/60); const row=await env.DB.prepare('INSERT INTO rate_limits(bucket,count,expires_at) VALUES(?,1,?) ON CONFLICT(bucket) DO UPDATE SET count=count+1 RETURNING count').bind(key+':'+minute,now()+120).first<{count:number}>();
  if(!row || row.count>limit) throw new HttpError(429,'Too many requests. Please try again in a minute.');
}
async function findOrder(env:Env,id:string,owner?:string) {
  const row=await env.DB.prepare('SELECT * FROM orders WHERE id=?').bind(id).first<Order>();
  if(!row || (owner && row.session_hash!==owner)) throw new HttpError(404,'Report order not found.');
  if(row.expires_at<=now()) throw new HttpError(410,'This report has expired. Contact merchant support about payment issues.');
  return row;
}
async function markVerified(env:Env,order:Order,paymentId:string,webhook:boolean) {
  await env.DB.prepare(`UPDATE orders SET payment_id=?, server_verified=1, webhook_verified=MAX(webhook_verified,?), state=CASE WHEN MAX(webhook_verified,?)=1 THEN 'paid' ELSE 'pending' END WHERE id=? AND state IN ('pending','paid') AND (payment_id IS NULL OR payment_id=?)`).bind(paymentId,webhook?1:0,webhook?1:0,order.id,paymentId).run();
}
async function webhook(req:Request,env:Env) {
  const c=config(env), raw=await limitedBody(req);
  if(!await signatureValid(c.webhookSecret,raw,req.headers.get('x-razorpay-signature')??'')) throw new HttpError(400,'Invalid webhook signature.');
  const body=z.object({event:z.string(),payload:z.record(z.string(),z.unknown())}).parse(JSON.parse(raw));
  if(!['payment.captured','refund.processed'].includes(body.event)) return json({received:true,ignored:true});
  const eventId=req.headers.get('x-razorpay-event-id')??await digest(raw);
  if(eventId.length>200) throw new HttpError(400,'Invalid event identifier.');
  if(await env.DB.prepare('SELECT id FROM webhook_events WHERE id=?').bind(eventId).first()) return json({received:true,duplicate:true});
  const payloadSchema=body.event==='payment.captured'?z.object({payment:z.object({entity:z.object({id:z.string(),order_id:z.string()})})}):z.object({refund:z.object({entity:z.object({payment_id:z.string()})})});
  const payload=payloadSchema.parse(body.payload);
  const paymentId='payment' in payload?payload.payment.entity.id:payload.refund.entity.payment_id;
  const remote=await new RazorpayGateway(c).payment(paymentId);
  if(remote.id!==paymentId) throw new HttpError(400,'Payment identifier mismatch.');
  const order=await env.DB.prepare('SELECT * FROM orders WHERE gateway_order_id=?').bind(remote.order_id).first<Order>();
  if(!order) throw new HttpError(503,'Order is not yet available. Retry webhook delivery.');
  // Signed event content alone cannot grant access. Fetch independently and bind the captured payment to our server-created order.
  if(remote.amount_refunded>0 || remote.status==='refunded') {
    await env.DB.prepare("UPDATE orders SET state='revoked',payment_id=?,report=NULL WHERE id=?").bind(remote.id,order.id).run();
  } else if(body.event==='refund.processed') {
    throw new HttpError(503,'Refund is not yet reflected by the payment provider. Retry delivery.');
  } else {
    const captured=z.object({payment:z.object({entity:z.object({id:z.string(),order_id:z.string()})})}).parse(body.payload);
    if(captured.payment.entity.order_id!==order.gateway_order_id || !matchesCaptured(remote,order.gateway_order_id!,paymentId)) throw new HttpError(400,'Payment does not match the report order.');
    await markVerified(env,order,paymentId,true);
  }
  await env.DB.prepare('INSERT OR IGNORE INTO webhook_events(id,received_at) VALUES(?,?)').bind(eventId,now()).run();
  return json({received:true});
}
async function api(req:Request,env:Env,url:URL) {
  const path=url.pathname;
  if(path==='/api/config' && req.method==='GET') {
    let available=false;try{config(env);available=true;}catch{/* intentionally fail closed */}
    return json({paymentsEnabled:available,mode:env.PAYMENTS_MODE,pricePaise:PRICE_PAISE,currency:'INR',merchant:env.MERCHANT_NAME||'Defence Pension Calculator',supportEmail:env.SUPPORT_EMAIL||null});
  }
  if(path==='/api/webhooks/razorpay' && req.method==='POST') return webhook(req,env);
  // All browser payment API routes are same-origin, including reads. No cross-origin CORS grants.
  if(req.method==='POST') {sameOrigin(req,env);if(!req.headers.get('Content-Type')?.startsWith('application/json')) throw new HttpError(415,'JSON required.');}
  else if(req.headers.get('Sec-Fetch-Site')==='cross-site') throw new HttpError(403,'Cross-site requests are not allowed.');
  if(path==='/api/session' && req.method==='POST') {
    config(env);
    const identity=await digest(req.headers.get('CF-Connecting-IP')??'local');await rateLimit(env,'session:'+identity,10);
    const token=sessionToken(req,env)??[...crypto.getRandomValues(new Uint8Array(32))].map(n=>n.toString(16).padStart(2,'0')).join('');
    const secure=env.APP_ORIGIN.startsWith('https://')?'; Secure':'';
    if(!secure && !env.APP_ORIGIN.startsWith('http://localhost:')) throw new HttpError(503,'HTTPS is required.');
    return json({ok:true},200,{'Set-Cookie':`${cookieName(env)}=${token}; HttpOnly; SameSite=Strict; Path=/; Max-Age=604800${secure}`});
  }
  const owner=await session(req,env);
  if(path==='/api/orders' && req.method==='POST') {
    const c=config(env);await rateLimit(env,'create:'+owner,5);
    const body=z.object({requestKey:z.string().uuid(),calculation:requestSchema}).strict().parse(JSON.parse(await limitedBody(req)));
    const result=calculate(body.calculation); // Recompute on the server; never trust a browser result, report or price.
    const id=crypto.randomUUID();
    const inserted=await env.DB.prepare('INSERT OR IGNORE INTO orders(id,session_hash,request_key,report,created_at,expires_at) VALUES(?,?,?,?,?,?)').bind(id,owner,body.requestKey,JSON.stringify(result),now(),now()+604800).run();
    const order=await env.DB.prepare('SELECT * FROM orders WHERE session_hash=? AND request_key=?').bind(owner,body.requestKey).first<Order>();
    if(!order) throw new HttpError(503,'Could not create order.');
    if(order.report && order.report!==JSON.stringify(result)) throw new HttpError(409,'This checkout reference belongs to a different calculation.');
    if(order.expires_at<=now()) throw new HttpError(410,'Report order expired.');
    if(inserted.meta.changes===1) {
      try {
        const remote=await new RazorpayGateway(c).createOrder(id);
        await env.DB.prepare("UPDATE orders SET gateway_order_id=?,state='pending' WHERE id=? AND state='creating'").bind(remote.id,id).run();
        order.gateway_order_id=remote.id;order.state='pending';
      } catch {
        await env.DB.prepare("UPDATE orders SET state='failed',report=NULL WHERE id=? AND state='creating'").bind(id).run();
        throw new HttpError(502,'Could not confirm order creation. Do not pay outside checkout. Try a new checkout or contact support if charged.');
      }
    }
    if(!order.gateway_order_id || ['failed','revoked'].includes(order.state)) throw new HttpError(409,'This order is unavailable. Start a new checkout.');
    return json({id:order.id,gatewayOrderId:order.gateway_order_id,keyId:c.keyId,amount:PRICE_PAISE,currency:'INR',state:order.state});
  }
  if(path==='/api/payments/verify' && req.method==='POST') {
    const c=config(env);await rateLimit(env,'verify:'+owner,15);
    const b=z.object({orderId:z.string().uuid(),razorpay_payment_id:z.string().regex(/^pay_[A-Za-z0-9]+$/),razorpay_order_id:z.string().regex(/^order_[A-Za-z0-9]+$/),razorpay_signature:z.string().regex(/^[a-fA-F0-9]{64}$/)}).strict().parse(JSON.parse(await limitedBody(req)));
    const order=await findOrder(env,b.orderId,owner);
    if(order.state==='revoked' || order.state==='failed') throw new HttpError(403,'Payment access has been revoked.');
    if(b.razorpay_order_id!==order.gateway_order_id || !await signatureValid(c.secret,`${order.gateway_order_id}|${b.razorpay_payment_id}`,b.razorpay_signature)) throw new HttpError(400,'Invalid checkout signature.');
    const payment=await new RazorpayGateway(c).payment(b.razorpay_payment_id);
    if(!matchesCaptured(payment,order.gateway_order_id!,b.razorpay_payment_id)) throw new HttpError(409,'Captured payment not confirmed. Wait for verification or contact merchant support.');
    await markVerified(env,order,b.razorpay_payment_id,false);
    return json({verified:true,awaitingWebhook:!(await findOrder(env,order.id,owner)).webhook_verified});
  }
  const match=path.match(/^\/api\/orders\/([a-f0-9-]{36})(\/report)?$/);
  if(match && req.method==='GET') {
    await rateLimit(env,'read:'+owner,90);
    const order=await findOrder(env,match[1],owner);
    if(!match[2]) return json({id:order.id,state:order.state,expiresAt:order.expires_at,ready:order.state==='paid' && !!order.server_verified && !!order.webhook_verified});
    config(env);
    if(order.state!=='paid' || !order.server_verified || !order.webhook_verified || !order.payment_id || !order.report) throw new HttpError(403,'A captured, server-verified payment and verified webhook are required.');
    // Recheck provider state on every download; catches refunds even if a webhook is delayed.
    const payment=await new RazorpayGateway(config(env)).payment(order.payment_id);
    if(!matchesCaptured(payment,order.gateway_order_id!,order.payment_id)) {
      if(payment.amount_refunded>0 || payment.status==='refunded') await env.DB.prepare("UPDATE orders SET state='revoked',report=NULL WHERE id=?").bind(order.id).run();
      throw new HttpError(403,'Payment no longer grants report access.');
    }
    const bytes=await createPDF(JSON.parse(order.report) as Report,new Date(order.created_at*1000));
    return new Response(new Uint8Array(bytes).buffer,{headers:{'Content-Type':'application/pdf','Content-Disposition':'attachment; filename="Defence-Pension-Report.pdf"'}});
  }
  throw new HttpError(404,'API route not found.');
}
export async function handleRequest(req:Request,env:Env):Promise<Response> {
  const url=new URL(req.url);let response:Response;
  try {
    response=url.pathname.startsWith('/api/')?await api(req,env,url):env.ASSETS?await env.ASSETS.fetch(req):new Response('Not found',{status:404});
  } catch(error) {
    const status=error instanceof HttpError?error.status:error instanceof ZodError || error instanceof SyntaxError || error instanceof PensionError?400:502;
    const message=error instanceof HttpError || error instanceof PensionError?error.message:error instanceof ZodError?'Invalid input. Check the calculation fields.':'The request could not be completed. Please retry or contact merchant support.';
    response=json({error:message},status);
  }
  const headers=new Headers(response.headers);
  headers.set('X-Content-Type-Options','nosniff');headers.set('Referrer-Policy','no-referrer');headers.set('X-Frame-Options','DENY');
  headers.set('Permissions-Policy','camera=(), microphone=(), geolocation=()');
  headers.set('Content-Security-Policy',"default-src 'self'; script-src 'self' https://checkout.razorpay.com; connect-src 'self' https://*.razorpay.com; frame-src https://*.razorpay.com; img-src 'self' data: https://*.razorpay.com; style-src 'self' 'unsafe-inline'; font-src 'self'; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'");
  if(url.protocol==='https:') headers.set('Strict-Transport-Security','max-age=31536000; includeSubDomains');
  if(url.pathname.startsWith('/api/')) headers.set('Cache-Control','no-store, private');
  if(url.pathname==='/sw.js') headers.set('Cache-Control','no-cache');
  return new Response(response.body,{status:response.status,headers});
}
export async function cleanup(env:Env) {
  const t=now();await env.DB.batch([
    env.DB.prepare('UPDATE orders SET report=NULL WHERE expires_at<?').bind(t),
    env.DB.prepare('DELETE FROM orders WHERE created_at<?').bind(t-90*86400),
    env.DB.prepare('DELETE FROM webhook_events WHERE received_at<?').bind(t-90*86400),
    env.DB.prepare('DELETE FROM rate_limits WHERE expires_at<?').bind(t)
  ]);
}
export default {fetch:handleRequest,scheduled:async(_event:ScheduledEvent,env:Env)=>cleanup(env)};
