const puppeteer = require('puppeteer');
const { mkdirSync } = require('fs');
const path = require('path');

const URL    = 'https://mukundhantextile-c2ed0.web.app';
const OUT    = '/Users/maithreyan/projects/Mukundhantextile/tablet_screenshots';
const CHROME = '/Users/maithreyan/.cache/puppeteer/chrome/mac_arm-150.0.7871.24/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing';

mkdirSync(OUT, { recursive: true });
const sleep = ms => new Promise(r => setTimeout(r, ms));

const SIZES = [
  { name: '7inch',  w: 1024, h: 600  },
  { name: '10inch', w: 1280, h: 800  },
];

async function run() {
  const browser = await puppeteer.launch({
    headless: false,
    executablePath: CHROME,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--start-maximized'],
    defaultViewport: null,
  });

  for (const { name, w, h } of SIZES) {
    console.log(`\n📱 ${name} (${w}x${h})`);
    const page = await browser.newPage();
    await page.setViewport({ width: w, height: h, deviceScaleFactor: 2 });

    // Navigate to Firebase live URL
    await page.goto(URL, { waitUntil: 'networkidle2', timeout: 60000 });
    console.log('  → Loaded. Waiting 25s for Flutter to render...');
    await sleep(25000);

    // HOME
    let file = path.join(OUT, `${name}_01_home.png`);
    await page.screenshot({ path: file });
    console.log(`  📸 ${file}`);

    // Bottom nav clicks by coordinate (5 tabs evenly spaced at bottom)
    const navItems = [
      { label: 'browse',  idx: 1 },
      { label: 'cart',    idx: 2 },
      { label: 'profile', idx: 4 },
    ];

    for (const { label, idx } of navItems) {
      const navY = h - 28;
      const navX = Math.round((w / 5) * idx + (w / 5) / 2);
      await page.mouse.click(navX, navY);
      console.log(`  🖱  Tapped ${label} nav at (${navX}, ${navY})`);
      await sleep(3000);
      file = path.join(OUT, `${name}_${label}.png`);
      await page.screenshot({ path: file });
      console.log(`  📸 ${file}`);
    }

    await page.close();
  }

  await browser.close();
  console.log('\n✅ Done:', OUT);
}

run().catch(e => { console.error(e); process.exit(1); });
