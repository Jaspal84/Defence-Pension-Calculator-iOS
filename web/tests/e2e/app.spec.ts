import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
test.beforeEach(async({page})=>{
 await page.route('**/api/config',route=>route.fulfill({json:{paymentsEnabled:false,mode:'disabled',pricePaise:500,currency:'INR',merchant:'Test configuration',supportEmail:null}}));
 await page.goto('/');
});
test('mobile free service estimate, stale result clearing, disclaimer and disabled payment',async({page})=>{
 await page.setViewportSize({width:390,height:844});
 await expect(page.getByRole('heading',{name:'Your service. Your pension, explained.'})).toBeVisible();
 await page.getByRole('button',{name:'Calculate estimate'}).click();
 await expect(page.getByText('₹22,600.00').first()).toBeVisible();
 await expect(page.getByText('Paid reports are not enabled.')).toBeVisible();
 await expect(page.getByText('Illustrative estimates · not official pension entitlements')).toBeVisible();
 expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
 await page.getByLabel('Basic pay (₹)',{exact:true}).fill('50000');
 await expect(page.getByText('See the full picture.')).toBeVisible();
});
test('family eligibility gate and commutation/arrears screens are functional',async({page})=>{
 await page.getByRole('button',{name:'Family pension',exact:true}).click();
 await page.getByRole('button',{name:'Calculate estimate'}).click();
 await expect(page.getByRole('alert')).toContainText('Confirm beneficiary eligibility');
 await page.getByLabel('Beneficiary eligibility confirmed').check();
 await page.getByRole('button',{name:'Calculate estimate'}).click();
 await expect(page.getByText('₹12,000.00').first()).toBeVisible();
 await page.getByRole('button',{name:'Commutation',exact:true}).click();
 await page.getByLabel('Illustrative factor from your records').fill('8');
 await page.getByLabel('I confirmed the legally applicable').check();
 await page.getByRole('button',{name:'Calculate estimate'}).click();
 await expect(page.getByText('₹8,67,840.00')).toBeVisible();
 await page.getByRole('button',{name:'Arrears',exact:true}).click();
 await page.getByRole('button',{name:'Calculate estimate'}).click();
 await expect(page.getByText('₹31,200.00').first()).toBeVisible();
});
test('OROP does not fabricate data or offer purchasable unsupported report',async({page})=>{
 await page.getByRole('button',{name:'OROP comparison'}).click();
 await page.getByRole('button',{name:'Check official data availability'}).click();
 await expect(page.getByRole('alert')).toContainText('Official OROP table data unavailable for this selection.');
 await expect(page.getByRole('button',{name:'Get PDF report'})).toHaveCount(0);
});
test('installed application shell and free calculator work offline without caching API data',async({page,context})=>{
 await page.evaluate(()=>navigator.serviceWorker.ready.then(()=>true));
 await page.reload();
 await page.waitForFunction(()=>!!navigator.serviceWorker.controller);
 const apiCached=await page.evaluate(async()=>{const keys=await caches.keys();for(const key of keys)for(const request of await (await caches.open(key)).keys())if(new URL(request.url).pathname.startsWith('/api/'))return true;return false;});expect(apiCached).toBe(false);
 await context.setOffline(true);await page.reload();
 await page.getByRole('button',{name:'Calculate estimate'}).click();
 await expect(page.getByText('₹22,600.00').first()).toBeVisible();
 await expect(page.getByText('You’re offline.')).toBeVisible();
 await context.setOffline(false);
});
test('basic and result screens meet automated WCAG checks',async({page})=>{
 await page.getByRole('button',{name:'Calculate estimate'}).click();
 const result=await new AxeBuilder({page}).withTags(['wcag2a','wcag2aa','wcag21aa']).analyze();
 expect(result.violations).toEqual([]);
});
test('synthetic checkout callback waits for backend-confirmed webhook before showing download',async({page})=>{
 let ready=false,verificationSeen=false;
 const id='12345678-1234-4234-8234-123456789abc';
 await page.route('**/api/config',route=>route.fulfill({json:{paymentsEnabled:true,mode:'test',pricePaise:500,currency:'INR',merchant:'Synthetic test merchant',supportEmail:null}}));
 await page.route('https://checkout.razorpay.com/v1/checkout.js',route=>route.fulfill({contentType:'application/javascript',body:`window.Razorpay=function(options){return{open:function(){if(options.amount!==500)throw Error('Wrong price');options.handler({razorpay_payment_id:'pay_synthetic',razorpay_order_id:'order_synthetic',razorpay_signature:'synthetic'});},on:function(){}};};`}));
 await page.route('**/api/session',route=>route.fulfill({json:{ok:true}}));
 await page.route('**/api/orders',route=>route.fulfill({json:{id,gatewayOrderId:'order_synthetic',keyId:'rzp_test_synthetic',amount:500,currency:'INR'}}));
 await page.route('**/api/payments/verify',route=>{verificationSeen=true;return route.fulfill({json:{verified:true,awaitingWebhook:true}});});
 await page.route(`**/api/orders/${id}`,route=>route.fulfill({json:{id,state:ready?'paid':'pending',ready}}));
 await page.reload();await page.getByRole('button',{name:'Calculate estimate'}).click();
 await page.getByRole('button',{name:'Get PDF report · ₹5'}).click();
 await expect.poll(()=>verificationSeen).toBe(true);
 await expect(page.getByRole('button',{name:'Download verified PDF'})).toHaveCount(0);
 await expect(page.getByRole('status')).toContainText('Waiting for captured payment');
 ready=true;
 await expect(page.getByRole('button',{name:'Download verified PDF'})).toBeVisible({timeout:10000});
});
