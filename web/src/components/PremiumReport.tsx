import { useEffect, useState } from 'react';
import { api, openCheckout, type PaymentConfig } from '../payments';
import type { CalculationRequest } from '../core/models';
export function PremiumReport({calculation,online}:{calculation:CalculationRequest|null;online:boolean}) {
  const [config,setConfig]=useState<PaymentConfig|null>(null),[message,setMessage]=useState(''),[busy,setBusy]=useState(false),[ready,setReady]=useState(false);
  const [orderId,setOrderId]=useState(()=>sessionStorage.getItem('pension-order')||'');
  useEffect(()=>{if(online)api<PaymentConfig>('config').then(setConfig).catch(()=>setConfig(null));},[online]);
  useEffect(()=>{setReady(false);},[orderId]);
  async function status(id=orderId) {
    const result=await api<{ready:boolean;state:string}>(`orders/${id}`);setReady(result.ready);
    setMessage(result.ready?'Your verified report is ready to download.':result.state==='revoked'?'Report access was revoked after a refund. Contact merchant support.':'Waiting for captured payment and the authenticated webhook. Keep this tab to check again; do not pay again.');return result.ready;
  }
  async function buy() {
    if(!calculation||!config)return;
    setBusy(true);setReady(false);setMessage('Opening secure checkout…');
    try {
      await api('session',{});
      const order=await api<{id:string;gatewayOrderId:string;keyId:string;amount:number;currency:string}>('orders',{requestKey:crypto.randomUUID(),calculation});
      setOrderId(order.id);sessionStorage.setItem('pension-order',order.id);
      const result=await openCheckout(order,config.merchant);
      await api('payments/verify',{orderId:order.id,...result});
      for(let attempt=0;attempt<12;attempt++) {
        if(await status(order.id))break;
        await new Promise(resolve=>setTimeout(resolve,2500));
      }
    } catch(e) {setMessage(e instanceof Error?e.message:'Checkout could not be completed.');}
    finally{setBusy(false);}
  }
  async function check() {setBusy(true);try{await status();}catch(e){setMessage((e as Error).message);}finally{setBusy(false);}}
  async function download() {
    setBusy(true);
    try {
      const response=await fetch(`/api/orders/${orderId}/report`,{cache:'no-store',credentials:'same-origin'});
      if(!response.ok){const data=await response.json() as {error:string};throw new Error(data.error);}
      const objectURL=URL.createObjectURL(await response.blob()),a=document.createElement('a');a.href=objectURL;a.download='Defence-Pension-Report.pdf';a.click();setTimeout(()=>URL.revokeObjectURL(objectURL),30000);
      setMessage('Report downloaded. Keep the file safely on your device.');
    }catch(e){setReady(false);setMessage((e as Error).message);}finally{setBusy(false);}
  }
  return <section className="premium" aria-labelledby="premium-title"><span className="eyebrow">OPTIONAL PREMIUM</span><h2 id="premium-title">A clear report to keep.</h2><p>Detailed breakdown, assumptions and rule limitations in a professionally formatted PDF.</p><div className="price">₹5 <small>per calculation · 500 paise</small></div><p className="fine">The calculation is free. Payment buys report formatting only and does not verify pension entitlement. The report is tied to the calculation sent at checkout; later input changes require a new calculation.</p>
    {!online?<p className="availability">You’re offline. All basic calculations still work. Payments need an internet connection.</p>:!config?.paymentsEnabled?<p className="availability">Paid reports are not enabled. Your free calculator is ready to use.</p>:<><p className="fine">{config.mode==='test'?'TEST MODE — no real payment. ':''}Checkout is provided by Razorpay; UPI availability depends on your device and merchant configuration. Continuing shares this report’s calculation with our server and opens Razorpay. No static QR scan or screenshot unlocks a report.</p><button type="button" className="primary" disabled={!calculation||busy} onClick={buy}>Get PDF report · ₹5</button>{!calculation&&<small>Calculate a supported estimate first.</small>}</>}
    {orderId&&online&&<div className="order-actions"><p className="fine">Last checkout reference: <code>{orderId}</code>. Keep this browser session for access. Report data expires after 7 days.</p><button type="button" disabled={busy} onClick={check}>Check payment status</button>{ready&&<button type="button" className="primary" disabled={busy} onClick={download}>Download verified PDF</button>}</div>}
    <p role="status" aria-live="polite">{busy?'Processing securely… ':''}{message}</p>
    {config?.supportEmail&&<a href={`mailto:${config.supportEmail}`}>Contact merchant support</a>}
  </section>;
}
