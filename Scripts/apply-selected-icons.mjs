#!/usr/bin/env node
/**
 * Apply selected icon options to the asset catalog.
 *
 * - AppIcon (option 02): dark full-bleed, flat puzzle, ~78% safe zone — Liquid Glass friendly
 * - LaunchCrestHero (option 01): light stage with ghost slots — matches splash / launch screen
 *
 * Also writes size previews to design/icon-options/previews/
 *
 * Usage: node Scripts/apply-selected-icons.mjs
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
const appIconDir = path.join(repoRoot, "App/Assets.xcassets/AppIcon.appiconset");
const heroDir = path.join(repoRoot, "App/Assets.xcassets/LaunchCrestHero.imageset");
const previewDir = path.join(repoRoot, "design/icon-options/previews");
const CANVAS_SELECTOR = "svg[data-om-exportable-video-with-duration-secs]";
const SETTLE_MS = 60;

// iOS 26 HIG: keep foreground inside ~76–80% of canvas; system applies corner mask + glass.
const APP_ICON_SIZE = 1024;
const APP_ICON_PUZZLE_RATIO = 0.78;
const DARK_BG = "#0a0d12";
const LIGHT_BG = "#f2f7fa";

// Puzzle board geometry from puzzle-scene.jsx (1080 design canvas, 720 board, centered).
const DESIGN_SIZE = 1080;
const BOARD_OFFSET = 180;
const BOARD_AREA = 720;
const BOARD_PAD = 10; // stroke + anti-alias slack at design coords

const APP_ICON_SIZES = [
  [40, "icon-20@2x.png"],
  [60, "icon-20@3x.png"],
  [58, "icon-29@2x.png"],
  [87, "icon-29@3x.png"],
  [76, "icon-38@2x.png"],
  [114, "icon-38@3x.png"],
  [80, "icon-40@2x.png"],
  [120, "icon-40@3x.png"],
  [120, "icon-60@2x.png"],
  [180, "icon-60@3x.png"],
  [128, "icon-64@2x.png"],
  [192, "icon-64@3x.png"],
  [136, "icon-68@2x.png"],
  [152, "icon-76@2x.png"],
  [167, "icon-83_5@2x.png"],
];

function magick(args) {
  execFileSync("magick", args, { stdio: "pipe" });
}

function imageSize(imagePath) {
  const out = execFileSync("magick", ["identify", "-format", "%w %h", imagePath], { encoding: "utf8" }).trim();
  const [w, h] = out.split(" ").map(Number);
  return { w, h };
}

function cropBoard(scenePath, outPath) {
  const { w } = imageSize(scenePath);
  const scale = w / DESIGN_SIZE;
  const cropX = Math.round((BOARD_OFFSET - BOARD_PAD) * scale);
  const cropY = Math.round((BOARD_OFFSET - BOARD_PAD) * scale);
  const cropW = Math.round((BOARD_AREA + BOARD_PAD * 2) * scale);
  const cropH = Math.round((BOARD_AREA + BOARD_PAD * 2) * scale);
  magick([scenePath, "-crop", `${cropW}x${cropH}+${cropX}+${cropY}`, outPath]);
}

function verifyBoardCrop(boardPath) {
  const { w, h } = imageSize(boardPath);
  if (w < 8 || h < 8) throw new Error(`Board crop too small: ${w}x${h}`);

  const sampleMean = (geometry) =>
    Number(execFileSync("magick", [boardPath, "-crop", geometry, "-format", "%[mean]", "info:"], {
      encoding: "utf8",
    }).trim());

  const right = sampleMean(`4x4+${w - 4}+${Math.floor(h / 2)}`);
  const bottom = sampleMean(`4x4+${Math.floor(w / 2)}+${h - 4}`);

  // Background-ish edges are very bright (>62000); puzzle edge pixels are darker/teal.
  if (right > 62000 || bottom > 62000) {
    throw new Error(`Board crop looks clipped (right=${right}, bottom=${bottom}).`);
  }
}

async function captureScene(page, url, query) {
  await page.goto(`${url}?${query}`, { waitUntil: "networkidle0", timeout: 120_000 });
  await page.waitForSelector(CANVAS_SELECTOR, { timeout: 60_000 });
  const canvas = await page.$(CANVAS_SELECTOR);
  if (!canvas) throw new Error("Canvas not found");

  const seekTime = await page.evaluate(() => window.PuzzleSceneTiming?.HOLD_MID ?? 2.5);
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

  const rawPath = path.join(previewDir, ".work-scene.png");
  await canvas.screenshot({ path: rawPath, omitBackground: false });
  return rawPath;
}

function composeAppIcon(boardPath, outPath) {
  const puzzlePx = Math.round(APP_ICON_SIZE * APP_ICON_PUZZLE_RATIO);
  const tile = path.join(previewDir, ".work-app-tile.png");
  magick([boardPath, "-resize", `${puzzlePx}x${puzzlePx}`, tile]);
  magick([
    "-size", `${APP_ICON_SIZE}x${APP_ICON_SIZE}`, `xc:${DARK_BG}`,
    tile, "-gravity", "center", "-compose", "over", "-composite",
    outPath,
  ]);
}

function composeHeroFromStage(stagePath, outPath, px) {
  magick([stagePath, "-resize", `${px}x${px}`, outPath]);
}

function simulateBrandMarkClip(heroPath, outPath, px) {
  const radius = Math.round(px * 0.22);
  magick([
    "-size", `${px}x${px}`, `xc:${LIGHT_BG}`,
    "(", heroPath, "-resize", `${px}x${px}`,
      "(", "-size", `${px}x${px}`, "xc:none",
         "-draw", `fill white roundrectangle 0,0 ${px - 1},${px - 1} ${radius},${radius}`,
      ")", "-alpha", "off", "-compose", "CopyOpacity", "-composite",
    ")", "-gravity", "center", "-compose", "over", "-composite",
    outPath,
  ]);
}

function simulateHomeScreenIcon(appIconPath, outPath, px) {
  const radius = Math.round(px * 0.223);
  magick([
    "(", appIconPath, "-resize", `${px}x${px}`,
      "(", "-size", `${px}x${px}`, "xc:none",
         "-draw", `fill white roundrectangle 0,0 ${px - 1},${px - 1} ${radius},${radius}`,
      ")", "-alpha", "off", "-compose", "CopyOpacity", "-composite",
    ")", outPath,
  ]);
}

async function main() {
  await fs.mkdir(previewDir, { recursive: true });

  const { server, url } = await startStaticServer(sourceDir, entryHtml);
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();
  await page.setCacheEnabled(false);
  await page.setViewport({ width: 1400, height: 1400, deviceScaleFactor: 1 });

  try {
    console.log("Capturing light stage (option 01)…");
    const stagePath = await captureScene(page, url, "preset=teal");

    console.log("Capturing flat puzzle board for AppIcon (option 02, glass-safe)…");
    const flatStagePath = await captureScene(page, url, "preset=teal&flat=1&ghost=0");
    const boardPath = path.join(previewDir, ".work-board.png");
    cropBoard(flatStagePath, boardPath);
    verifyBoardCrop(boardPath);
    await fs.copyFile(boardPath, path.join(previewDir, "verify-board-crop.png"));

    const marketingPath = path.join(appIconDir, "ios-marketing.png");
    composeAppIcon(boardPath, marketingPath);
    for (const [px, filename] of APP_ICON_SIZES) {
      magick([marketingPath, "-resize", `${px}x${px}`, path.join(appIconDir, filename)]);
    }

    composeHeroFromStage(stagePath, path.join(heroDir, "LaunchCrestHero@1x.png"), 132);
    composeHeroFromStage(stagePath, path.join(heroDir, "LaunchCrestHero@2x.png"), 264);
    composeHeroFromStage(stagePath, path.join(heroDir, "LaunchCrestHero@3x.png"), 396);

    composeAppIcon(boardPath, path.join(previewDir, "production-appicon-1024.png"));
    composeHeroFromStage(stagePath, path.join(previewDir, "production-hero-132.png"), 132);
    simulateBrandMarkClip(
      path.join(previewDir, "production-hero-132.png"),
      path.join(previewDir, "production-hero-brandmark-132.png"),
      132,
    );
    simulateHomeScreenIcon(
      path.join(previewDir, "production-appicon-1024.png"),
      path.join(previewDir, "production-appicon-homescreen-60.png"),
      60,
    );
    simulateHomeScreenIcon(
      path.join(previewDir, "production-appicon-1024.png"),
      path.join(previewDir, "production-appicon-homescreen-180.png"),
      180,
    );

    console.log("Applied AppIcon + LaunchCrestHero.");
    console.log(`Previews: ${previewDir}`);
  } finally {
    await browser.close();
    server.close();
    for (const file of [".work-scene.png", ".work-board.png", ".work-app-tile.png"]) {
      await fs.rm(path.join(previewDir, file), { force: true });
    }
  }
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
