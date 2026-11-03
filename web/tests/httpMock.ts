import { vi, expect } from 'vitest';
interface Route {origin:string;path:string;method:string;status:number;reply:unknown|((options:{body:string})=>unknown);remaining:number}
let routes:Route[]=[];
// Strict synthetic HTTP boundary for the real gateway adapter. Every unexpected outbound request fails.
export const fetchMock={
 activate(){vi.stubGlobal('fetch',async(input:RequestInfo|URL,init?:RequestInit)=>{
   const url=new URL(typeof input==='string'?input:input instanceof URL?input.href:input.url);
   const method=init?.method??(input instanceof Request?input.method:'GET');
   const route=routes.find(r=>r.remaining>0&&r.origin===url.origin&&r.path===url.pathname&&r.method===method);
   if(!route)throw new Error(`Unexpected provider HTTP request: ${method} ${url.origin}${url.pathname}`);
   route.remaining--;
   expect(new Headers(init?.headers).get('Authorization')).toMatch(/^Basic /);
   const data=typeof route.reply==='function'?route.reply({body:String(init?.body??'')}):route.reply;
   return Response.json(data,{status:route.status});
 });},
 disableNetConnect(){/* The stub never falls back to network. */},
 get(origin:string){return {intercept(spec:{path:string;method:string}){return {reply(status:number,reply:Route['reply']){const route:Route={origin,...spec,status,reply,remaining:1};routes.push(route);return {times(n:number){route.remaining=n;}};}};}};},
 assertNoPendingInterceptors(){try{expect(routes.filter(r=>r.remaining>0)).toEqual([]);}finally{routes=[];}}
};
