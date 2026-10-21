const {chromium}=require('C:/Users/thait/AppData/Local/Temp/voucher-ui-check/node_modules/playwright');
(async()=>{
 const browser=await chromium.launch({channel:'msedge',headless:true});
 const page=await browser.newPage({viewport:{width:1440,height:1000}});
 await page.goto('http://localhost:5173');
 await page.waitForTimeout(10000);
 await page.screenshot({path:'ui-login-desktop.png'});
 await page.locator('flt-semantics-placeholder').evaluate(e=>e.click()).catch(()=>{});
 await page.waitForTimeout(1000);
 console.log((await page.locator('body').innerText()).slice(0,2000));
 await page.setViewportSize({width:375,height:812});
 await page.waitForTimeout(1000);
 await page.screenshot({path:'ui-login-mobile.png'});
 await browser.close();
})();
