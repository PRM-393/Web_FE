const {chromium}=require('C:/Users/thait/AppData/Local/Temp/voucher-ui-check/node_modules/playwright');
(async()=>{
 const browser=await chromium.launch({channel:'msedge',headless:true});
 const page=await browser.newPage({viewport:{width:1440,height:1000}});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto('http://localhost:5173',{waitUntil:'networkidle',timeout:60000});await page.waitForTimeout(3000);
 await page.locator('flt-semantics-placeholder').evaluate(e=>e.click());await page.waitForTimeout(1000);
 await page.mouse.click(1080,493);await page.keyboard.type('admin@voucher.local');
 await page.mouse.click(1080,560);await page.keyboard.type('Voucher@123');
 await page.mouse.click(1080,630);await page.waitForTimeout(3000);
 if(!page.url().includes('/admin/dashboard')) throw Error('Admin login did not navigate: '+page.url());
 await page.goto('http://localhost:5173/#/admin/categories');await page.waitForTimeout(2000);
 if(!page.url().includes('/admin/categories')) throw Error('Category navigation failed: '+page.url());
 await page.screenshot({path:'qa/web-admin-categories.png',animations:'disabled'});
 console.log(JSON.stringify({url:page.url(),errors},null,2));
 await browser.close();
})().catch(e=>{console.error(e);process.exitCode=1});
