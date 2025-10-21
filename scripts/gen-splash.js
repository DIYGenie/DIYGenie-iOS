#!/usr/bin/env node

const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

async function generateSplash() {
  const WIDTH = 1290;
  const HEIGHT = 2796;
  const LOGO_SCALE = 0.38;
  const PADDING_PERCENT = 0.06;

  const iconPath = path.join(__dirname, '../assets/Icon.png');
  
  if (!fs.existsSync(iconPath)) {
    console.error('[splash] error: icon missing');
    process.exit(1);
  }

  const gradientSvg = `
    <svg width="${WIDTH}" height="${HEIGHT}" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="grad" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" style="stop-color:#8B5CF6;stop-opacity:1" />
          <stop offset="100%" style="stop-color:#FFFFFF;stop-opacity:1" />
        </linearGradient>
      </defs>
      <rect width="${WIDTH}" height="${HEIGHT}" fill="url(#grad)"/>
    </svg>
  `;

  const gradientBuffer = Buffer.from(gradientSvg);

  const iconMetadata = await sharp(iconPath).metadata();
  const logoWidth = Math.round(WIDTH * LOGO_SCALE);
  const logoHeight = Math.round((iconMetadata.height / iconMetadata.width) * logoWidth);
  
  const paddingPx = Math.round(logoWidth * PADDING_PERCENT);
  const finalLogoWidth = logoWidth - (paddingPx * 2);
  const finalLogoHeight = Math.round((iconMetadata.height / iconMetadata.width) * finalLogoWidth);

  const logoBuffer = await sharp(iconPath)
    .resize(finalLogoWidth, finalLogoHeight, { fit: 'inside' })
    .toBuffer();

  const left = Math.round((WIDTH - finalLogoWidth) / 2);
  const top = Math.round((HEIGHT - finalLogoHeight) / 2);

  const outputPath = path.join(__dirname, '../assets/splash.png');

  await sharp(gradientBuffer)
    .composite([
      {
        input: logoBuffer,
        left,
        top
      }
    ])
    .png()
    .toFile(outputPath);

  console.log(`[splash] updated { size:"${WIDTH}x${HEIGHT}", gradient:"#8B5CF6→#FFFFFF", logoScale:"${Math.round(LOGO_SCALE * 100)}%" }`);

  const metadata = await sharp(outputPath).metadata();
  if (metadata.width === WIDTH && metadata.height === HEIGHT) {
    console.log(`[assets] ok { splash:true, size:"${WIDTH}x${HEIGHT}" }`);
  } else {
    console.error(`[assets] error { expected:"${WIDTH}x${HEIGHT}", actual:"${metadata.width}x${metadata.height}" }`);
    process.exit(1);
  }
}

generateSplash().catch(err => {
  console.error('[splash] generation failed:', err);
  process.exit(1);
});
