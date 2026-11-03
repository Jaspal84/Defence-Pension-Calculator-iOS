interface CheckoutResult { razorpay_payment_id:string;razorpay_order_id:string;razorpay_signature:string }
interface CheckoutOptions { key:string;amount:number;currency:string;order_id:string;name:string;description:string;handler:(result:CheckoutResult)=>void;modal:{ondismiss:()=>void} }
declare global { interface Window { Razorpay?:new(options:CheckoutOptions)=>{open:()=>void;on:(event:string,handler:()=>void)=>void} } }
export interface PaymentConfig {paymentsEnabled:boolean;mode:string;pricePaise:number;currency:string;merchant:string;supportEmail:string|null}
export async function api<T>(path:string,body?:unknown):Promise<T> {
  const response=await fetch('/api/'+path,{method:body?'POST':'GET',credentials:'same-origin',headers:body?{'Content-Type':'application/json'}:undefined,body:body?JSON.stringify(body):undefined,cache:'no-store'});
  const value=await response.json() as {error?:string};if(!response.ok) throw new Error(value.error||'Request failed.');return value as T;
}
let loading:Promise<void>|undefined;
export function checkoutSDK():Promise<void> {
  if(window.Razorpay)return Promise.resolve();
  if(loading)return loading;
  loading=new Promise((resolve,reject)=>{
    const script=document.createElement('script');script.src='https://checkout.razorpay.com/v1/checkout.js';script.async=true;
    const timeout=window.setTimeout(()=>{script.remove();loading=undefined;reject(new Error('Checkout could not load. Please try again online.'));},15000);
    script.onload=()=>{clearTimeout(timeout);if(window.Razorpay)resolve();else{loading=undefined;reject(new Error('Checkout is unavailable.'));}};
    script.onerror=()=>{clearTimeout(timeout);script.remove();loading=undefined;reject(new Error('Checkout could not load.'));};document.head.append(script);
  });return loading;
}
export async function openCheckout(order:{keyId:string;amount:number;currency:string;gatewayOrderId:string},merchant:string):Promise<CheckoutResult> {
  await checkoutSDK();return new Promise((resolve,reject)=>{
    const checkout=new window.Razorpay!({key:order.keyId,amount:order.amount,currency:order.currency,order_id:order.gatewayOrderId,name:merchant,description:'Detailed illustrative pension PDF report',handler:resolve,modal:{ondismiss:()=>reject(new Error('Checkout closed. No report is unlocked until payment is independently verified.'))}});
    checkout.on('payment.failed',()=>reject(new Error('Payment was not confirmed. Check the order status before trying again.')));checkout.open();
  });
}
