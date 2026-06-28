#!/usr/bin/env node
/**
 * Puzzle Buddy wrapper — regenerates splash_loading.gif from the bundled design export.
 */
import path from "node:path";
import { fileURLToPath } from "node:url";
import { runCli } from "../../claude-design-zip-to-gif/lib/cli.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

await runCli([
  process.argv[0],
  process.argv[1],
  path.join(repoRoot, "Resources/loading-animation-source"),
  "-o",
  path.join(repoRoot, "Puzzle Buddy/Resources/splash_loading.gif"),
  "--size",
  "240",
]);

// After regenerating the GIF, refresh the static app icon + LaunchCrestHero:
//   ./Scripts/render-app-icon.sh
