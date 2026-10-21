const {chromium}=require('C:/Users/thait/AppData/Local/Temp/voucher-ui-check/node_modules/playwright');
(async()=>{
 const browser=await chromium.launch({channel:'msedge',headless:true});
 const page=await browser.newPage({viewport:{width:1440,height:1000}});
 const logs=[];page.on('console',m=>logs.push(m.type()+': '+m.text()));page.on('pageerror',e=>logs.push('pageerror: '+e.message));
 const response=await page.goto('http://localhost:5173',{waitUntil:'networkidle',timeout:60000});
 await page.waitForTimeout(5000);
 const info=await page.evaluate(()=>({title:document.title,html:document.body.innerHTML.slice(0,1000),canvases:document.querySelectorAll('canvas').length,flutterViews:document.querySelectorAll('flutter-view').length}));
 await page.screenshot({path:'qa/web-login.png',animations:'disabled'});
 console.log(JSON.stringify({status:response.status(),info,logs},null,2));
 await browser.close();
})().catch(e=>{console.error(e);process.exitCode=1});
