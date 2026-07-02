const puppeteer = require('puppeteer');
const { mkdirSync } = require('fs');
const path = require('path');

const URL    = 'https://mukundhantextile-c2ed0.web.app';
const OUT    = '/Users/maithreyan/projects/Mukundhantextile/chromebook_screenshots';
const CHROME = '/Users/maithreyan/.cache/puppeteer/chrome/mac_arm-150.0.7871.24/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing';

mkdirSync(OUT, { recursive: true });
const sleep = ms => new Promise(r => setTimeout(r, ms));

// Chromebook: 16:9, between 1080-7680px per side
// 1920x1080 is perfect
const W = 1920, H = 1080;

async function run() {
  const browser = await puppeteer.launch({
    headless: false,
    executablePath: CHROME,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
    defaultViewport: null,
  });

  const page = await browser.newPage();
  await page.setViewport({ width: W, height: H, deviceScaleFactor: 2 });

  console.log(`🖥  Loading app at ${W}x${H} (Chromebook 16:9)...`);
  await page.goto(URL, { waitUntil: 'networkidle2', timeout: 60000 });
  console.log('  Waiting 25s for Flutter to render...');
  await sleep(25000);

  // Screenshot 1: Home
  let f = path.join(OUT, 'chromebook_01_home.png');
  await page.screenshot({ path: f });
  console.log('📸', f);

  // Nav items are in the TOP bar on wide screens
  // Click Browse (2nd nav item in top bar)
  // On 1920px wide screen, nav items approx at:
  // Home≈720, Browse≈830, Cart≈920, Wishlist≈1020, Profile≈1110  y≈45
  const NAV_Y = 45;
  const navItems = [
    { name: '02_browse',  x: 830  },
    { name: '03_cart',    x: 920  },
    { name: '04_wishlist',x: 1020 },
    { name: '05_profile', x: 1110 },
  ];

  for (const { name, x } of navItems) {
    await page.mouse.click(x, NAV_Y);
    await sleep(3000);
    f = path.join(OUT, `chromebook_${name}.png`);
    await page.screenshot({ path: f });
    console.log('📸', f);
  }

  await browser.close();
  console.log('\n✅ Chromebook screenshots saved to:', OUT);
}

run().catch(e => { console.error(e); process.exit(1); });
