#!/usr/bin/env node
/**
 * Render Puzzle Buddy app icon candidates from the jigsaw scene export.
 *
 * Usage: node Scripts/render-icon-options.mjs
 * Output: design/icon-options/*.png (1024×1024)
 */
import { execFileSync } from "node:child_process";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "../../claude-design-zip-to-gif/node_modules/puppeteer/lib/esm/puppeteer/puppeteer.js";
import { startStaticServer } from "../../claude-design-zip-to-gif/lib/server.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const sourceDir = path.join(repoRoot, "Resources/loading-animation-source");
const entryHtml = path.join(sourceDir, "Puzzle Buddy Loader.dc.html");
const outDir = path.join(repoRoot, "design/icon-options");
const CANVAS_SELECTOR = "svg[data-om-exportable-video-with-duration-secs]";
const SETTLE_MS = 60;

const VARIANTS = [
  {
    file: "01-teal-stage-assembled.png",
    label: "Teal jigsaw — assembled on light stage",
    preset: "teal",
    time: "hold",
    compose: "stage",
  },
  {
    file: "02-teal-dark-ring.png",
    label: "Teal jigsaw — App Store dark ring",
    preset: "teal",
    time: "hold",
    compose: "dark-ring",
  },
  {
    file: "03-ocean-assembled.png",
    label: "Ocean blue jigsaw — assembled",
    preset: "ocean",
    time: "hold",
    compose: "stage",
  },
  {
    file: "04-ocean-dark-ring.png",
    label: "Ocean blue jigsaw — dark ring",
    preset: "ocean",
    time: "hold",
    compose: "dark-ring",
  },
  {
    file: "05-teal-mid-assemble.png",
    label: "Teal jigsaw — mid assembly (dynamic)",
    preset: "teal",
    time: 1.25,
    compose: "stage",
  },
  {
    file: "06-teal-brand-gradient.png",
    label: "Teal jigsaw — brand gradient background",
    preset: "teal",
    time: "hold",
    compose: "brand-gradient",
  },
];

function magick(args) {
  execFileSync("magick", args, { stdio: "pipe" });
}

async function captureScene({ page, url, preset, timeKey }) {
  const targetUrl = `${url}?preset=${encodeURIComponent(preset)}`;
  await page.goto(targetUrl, { waitUntil: "networkidle0", timeout: 120_000 });
  await page.waitForSelector(CANVAS_SELECTOR, { timeout: 60_000 });
  const canvas = await page.$(CANVAS_SELECTOR);
  if (!canvas) throw new Error("Canvas not found");

  const seekTime = timeKey === "hold"
    ? await page.evaluate(() => window.PuzzleSceneTiming?.HOLD_MID ?? 2.5)
    : timeKey;

  await page.evaluate(
    (selector, time) => {
      document.querySelector(selector)?.dispatchEvent(
        new CustomEvent("data-om-seek-to-time-frame", { detail: { time } }),
      );
    },
    CANVAS_SELECTOR,
    seekTime,
  );
  await new Promise((resolve) => setTimeout(resolve, SETTLE_MS));

  const rawPath = path.join(outDir, ".work-raw.png");
  await canvas.screenshot({ path: rawPath, omitBackground: false });
  return rawPath;
}

function composeStage(rawPath, outPath) {
  magick([rawPath, "-resize", "1024x1024", outPath]);
}

function composeDarkRing(rawPath, outPath) {
  const size = 1024;
  const inner = Math.round(size * 0.86);
  const radius = Math.round(inner * 0.22);
  const tile = path.join(outDir, ".work-tile.png");
  magick([rawPath, "-resize", `${inner}x${inner}`, tile]);
  magick([
    "-size", `${size}x${size}`, "xc:#0a0d12",
    "(", tile,
      "(", "-size", `${inner}x${inner}`, "xc:none",
         "-draw", `fill white roundrectangle 0,0 ${inner - 1},${inner - 1} ${radius},${radius}`,
      ")", "-alpha", "off", "-compose", "CopyOpacity", "-composite",
    ")", "-gravity", "center", "-compose", "over", "-composite",
    outPath,
  ]);
}

function composeBrandGradient(rawPath, outPath) {
  const size = 1024;
  const inner = Math.round(size * 0.88);
  const radius = Math.round(inner * 0.22);
  const tile = path.join(outDir, ".work-tile.png");
  magick([rawPath, "-resize", `${inner}x${inner}`, tile]);
  magick([
    "-size", `${size}x${size}`,
    "gradient:#a8e0f0-#0d8c9e",
    "(", tile,
      "(", "-size", `${inner}x${inner}`, "xc:none",
         "-draw", `fill white roundrectangle 0,0 ${inner - 1},${inner - 1} ${radius},${radius}`,
      ")", "-alpha", "off", "-compose", "CopyOpacity", "-composite",
    ")", "-gravity", "center", "-compose", "over", "-composite",
    outPath,
  ]);
}

async function main() {
  if (!process.env.PATH?.includes("magick")) {
    try {
      execFileSync("magick", ["-version"], { stdio: "pipe" });
    } catch {
      throw new Error("ImageMagick (magick) is required.");
    }
  }

  await fs.mkdir(outDir, { recursive: true });

  const currentIcon = path.join(
    repoRoot,
    "Puzzle Buddy/Assets.xcassets/AppIcon.appiconset/ios-marketing.png",
  );
  await fs.copyFile(currentIcon, path.join(outDir, "00-current-shipped.png"));

  const { server, url } = await startStaticServer(sourceDir, entryHtml);
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();
  await page.setCacheEnabled(false);
  await page.setViewport({ width: 1400, height: 1400, deviceScaleFactor: 1 });

  const manifest = [
    {
      file: "00-current-shipped.png",
      label: "Current shipped icon (restored blue crest)",
    },
  ];

  try {
    for (const variant of VARIANTS) {
      process.stdout.write(`Rendering ${variant.file}… `);
      const rawPath = await captureScene({
        page,
        url,
        preset: variant.preset,
        timeKey: variant.time,
      });
      const outPath = path.join(outDir, variant.file);

      switch (variant.compose) {
        case "dark-ring":
          composeDarkRing(rawPath, outPath);
          break;
        case "brand-gradient":
          composeBrandGradient(rawPath, outPath);
          break;
        default:
          composeStage(rawPath, outPath);
      }

      manifest.push({ file: variant.file, label: variant.label });
      process.stdout.write("done\n");
    }
  } finally {
    await browser.close();
    server.close();
    await fs.rm(path.join(outDir, ".work-raw.png"), { force: true });
    await fs.rm(path.join(outDir, ".work-tile.png"), { force: true });
  }

  const readme = [
    "# Puzzle Buddy icon options",
    "",
    "Generated by `node Scripts/render-icon-options.mjs`.",
    "",
    "| File | Description |",
    "|------|-------------|",
    ...manifest.map(({ file, label }) => `| \`${file}\` | ${label} |`),
    "",
    "Pick a favorite and say which number — we can wire it into `AppIcon.appiconset` + `LaunchCrestHero`.",
    "",
  ].join("\n");
  await fs.writeFile(path.join(outDir, "README.md"), readme);

  console.log(`\nWrote ${manifest.length} icons to ${outDir}`);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
