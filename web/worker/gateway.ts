import { z } from 'zod';
export interface GatewayConfig { keyId: string; secret: string; webhookSecret: string }
export const PRICE_PAISE = 500;
const encoder = new TextEncoder();
export async function hmac(secret: string, body: string): Promise<string> {
  const key = await crypto.subtle.importKey('raw', encoder.encode(secret), {name:'HMAC',hash:'SHA-256'}, false, ['sign']);
  return [...new Uint8Array(await crypto.subtle.sign('HMAC',key,encoder.encode(body)))].map(b => b.toString(16).padStart(2,'0')).join('');
}
export async function signatureValid(secret: string, body: string, signature: string): Promise<boolean> {
  if (!/^[a-f0-9]{64}$/i.test(signature)) return false;
  const key = await crypto.subtle.importKey('raw',encoder.encode(secret),{name:'HMAC',hash:'SHA-256'},false,['verify']);
  const bytes = Uint8Array.from(signature.match(/../g)!,h => parseInt(h,16));
  return crypto.subtle.verify('HMAC',key,bytes,encoder.encode(body));
}
export async function digest(body: string): Promise<string> {
  return [...new Uint8Array(await crypto.subtle.digest('SHA-256',encoder.encode(body)))].map(b => b.toString(16).padStart(2,'0')).join('');
}
const paymentSchema = z.object({id:z.string(),order_id:z.string(),amount:z.number().int(),currency:z.string(),status:z.string(),captured:z.boolean(),amount_refunded:z.number().int().nonnegative().default(0)});
export type GatewayPayment = z.infer<typeof paymentSchema>;
export class RazorpayGateway {
  constructor(private config: GatewayConfig, private send: typeof fetch = fetch) {}
  private async request(path: string, body?: unknown) {
    const response = await this.send('https://api.razorpay.com/v1/'+path, {
      method:body ? 'POST' : 'GET',
      headers:{'Authorization':'Basic '+btoa(`${this.config.keyId}:${this.config.secret}`),'Content-Type':'application/json'},
      ...(body ? {body:JSON.stringify(body)} : {}), signal:AbortSignal.timeout(12000)
    });
    if (!response.ok) throw new Error('Payment provider is temporarily unavailable.');
    return response.json();
  }
  async createOrder(receipt: string) {
    const order = z.object({id:z.string().regex(/^order_[A-Za-z0-9]+$/),amount:z.number().int(),currency:z.string(),receipt:z.string()}).parse(await this.request('orders',{amount:PRICE_PAISE,currency:'INR',receipt,notes:{product:'pension_report_v1'}}));
    if (order.amount !== PRICE_PAISE || order.currency !== 'INR' || order.receipt !== receipt) throw new Error('Payment provider order mismatch.');
    return order;
  }
  async payment(id: string) {
    if (!/^pay_[A-Za-z0-9]+$/.test(id)) throw new Error('Invalid payment identifier.');
    return paymentSchema.parse(await this.request('payments/'+id));
  }
}
export function matchesCaptured(payment: GatewayPayment, orderId: string, paymentId: string) {
  return payment.id === paymentId && payment.order_id === orderId && payment.amount === PRICE_PAISE && payment.currency === 'INR' && payment.status === 'captured' && payment.captured && payment.amount_refunded === 0;
}
