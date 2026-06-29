// Puzzle Buddy — jigsaw loading animation
// Reads timeline globals (Stage, useTime, Easing) from window (animations.jsx).
const { Stage, useTime, Easing } = window;

// ---------- geometry ----------
const N = 4;                 // 4x4 = 16 pieces
const AREA = 720;            // puzzle drawing size (px) inside the stage
const S = AREA / N;          // cell size
const OFF = (1080 - AREA) / 2; // center inside 1080 square

// deterministic pseudo-random sign for a seam
function sgn(a, b) {
  const h = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
  return (h - Math.floor(h)) > 0.5 ? 1 : -1;
}

// sample one edge from p0 to p1 with an elliptical jigsaw knob (s = ±1, 0 = flat)
function edge(p0, p1, s) {
  if (!s) return [p0, p1];
  const dx = p1[0] - p0[0], dy = p1[1] - p0[1];
  const len = Math.hypot(dx, dy);
  const ux = dx / len, uy = dy / len;     // edge dir
  const nx = uy, ny = -ux;                // outward normal (rotate -90)
  const peak = 0.17 * S, hw = 0.16;       // knob height / half-width (in t)
  const steps = 56, pts = [];
  for (let i = 0; i <= steps; i++) {
    const t = i / steps;
    const d = (t - 0.5) / hw;
    const bump = Math.abs(d) < 1 ? peak * Math.sqrt(1 - d * d) : 0;
    const bx = p0[0] + dx * t, by = p0[1] + dy * t;
    pts.push([bx + nx * s * bump, by + ny * s * bump]);
  }
  return pts;
}

const P = (col, row) => [OFF + col * S, OFF + row * S]; // grid corner

// canonical seams (computed once)
const vSeam = {}; // vSeam[`${col}_${row}`] top->bottom, col=1..N-1
const hSeam = {}; // hSeam[`${row}_${col}`] left->right, row=1..N-1
for (let r = 0; r < N; r++)
  for (let c = 1; c < N; c++)
    vSeam[`${c}_${r}`] = edge(P(c, r), P(c, r + 1), sgn(c, r) * 1);
for (let r = 1; r < N; r++)
  for (let c = 0; c < N; c++)
    hSeam[`${r}_${c}`] = edge(P(c, r), P(c + 1, r), sgn(r + 99, c) * 1);

function rev(a) { return a.slice().reverse(); }
function toPath(pts) {
  let d = `M ${pts[0][0].toFixed(2)} ${pts[0][1].toFixed(2)}`;
  for (let i = 1; i < pts.length; i++) d += ` L ${pts[i][0].toFixed(2)} ${pts[i][1].toFixed(2)}`;
  return d + " Z";
}

// build each piece outline by concatenating its 4 edges (clockwise)
function piecePoints(r, c) {
  // top: P(c,r)->P(c+1,r)
  const top = r === 0 ? [P(c, r), P(c + 1, r)] : hSeam[`${r}_${c}`];
  // right: P(c+1,r)->P(c+1,r+1)
  const right = c === N - 1 ? [P(c + 1, r), P(c + 1, r + 1)] : vSeam[`${c + 1}_${r}`];
  // bottom: P(c+1,r+1)->P(c,r+1)  (reverse of left->right seam)
  const bottom = r === N - 1 ? [P(c + 1, r + 1), P(c, r + 1)] : rev(hSeam[`${r + 1}_${c}`]);
  // left: P(c,r+1)->P(c,r)  (reverse of top->bottom seam)
  const left = c === 0 ? [P(c, r + 1), P(c, r)] : rev(vSeam[`${c}_${r}`]);
  return [...top, ...right.slice(1), ...bottom.slice(1), ...left.slice(1)];
}

// ---------- color presets ----------
function mix(a, b, t) {
  return a.map((v, i) => Math.round(v + (b[i] - v) * t));
}
const rgb = (a) => `rgb(${a[0]},${a[1]},${a[2]})`;

const PRESETS = {
  terracotta: {
    light: [236, 200, 156],
    dark: [193, 92, 56],
    background: "#f4efe6",
    ghostFill: "#eaddc9",
    ghostStroke: "#f4efe6",
    pieceStroke: "#f4efe6",
    shadow: "#7a3b22",
  },
  teal: {
    light: [184, 224, 240],  // airy cyan — Brand.accentSecondary family
    dark: [13, 140, 158],  // signature teal #0d8c9e
    background: "#f2f7fa",   // Brand.background light
    ghostFill: "#dde8f0",
    ghostStroke: "#f2f7fa",
    pieceStroke: "#f2f7fa",
    shadow: "#0a4a55",
  },
  ocean: {
    light: [64, 168, 230],   // Brand.gradientMid family
    dark: [26, 115, 217],    // Brand.gradientTop family
    background: "#eef6fc",
    ghostFill: "#d6eafb",
    ghostStroke: "#eef6fc",
    pieceStroke: "#eef6fc",
    shadow: "#0c3d6e",
  },
};

function readPreset() {
  try {
    const injected = globalThis.__ICON_RENDER_PRESET;
    if (injected && PRESETS[injected]) return PRESETS[injected];
    const name = new URLSearchParams(globalThis.location?.search || "").get("preset") || "teal";
    return PRESETS[name] || PRESETS.teal;
  } catch {
    return PRESETS.teal;
  }
}

function readExportFlags() {
  try {
    const params = new URLSearchParams(globalThis.location?.search || "");
    return {
      flat: params.get("flat") === "1",
      ghost: params.get("ghost") !== "0",
    };
  } catch {
    return { flat: false, ghost: true };
  }
}

function buildPieces(palette) {
  const pieces = [];
  for (let r = 0; r < N; r++) {
    for (let c = 0; c < N; c++) {
      const pts = piecePoints(r, c);
      const cx = OFF + c * S + S / 2, cy = OFF + r * S + S / 2;
      const g = (r + c) / (2 * (N - 1));
      const jitter = (sgn(r * 7, c * 3) > 0 ? 0.06 : -0.04);
      const col = rgb(mix(palette.light, palette.dark, Math.min(1, Math.max(0, g + jitter))));
      pieces.push({ r, c, d: toPath(pts), cx, cy, col });
    }
  }
  return pieces;
}

// snake (boustrophedon) order — reads like a progress sweep
const ORDER = [];
for (let r = 0; r < N; r++) {
  const cols = [];
  for (let c = 0; c < N; c++) cols.push(c);
  if (r % 2 === 1) cols.reverse();
  for (const c of cols) ORDER.push(r * N + c);
}
const orderIndex = new Array(N * N);
ORDER.forEach((pi, k) => { orderIndex[pi] = k; });

// ---------- timeline ----------
const STAGGER = 0.11, IN_DUR = 0.5;
const HOLD = 0.75;
const OUT_STAGGER = 0.085, OUT_DUR = 0.42, GAP = 0.25;
const IN_END = (N * N - 1) * STAGGER + IN_DUR;
const HOLD_END = IN_END + HOLD;
const OUT_END = HOLD_END + (N * N - 1) * OUT_STAGGER + OUT_DUR;
const LOOP = OUT_END + GAP;
const HOLD_MID = IN_END + HOLD / 2;

function clamp01(x) { return Math.max(0, Math.min(1, x)); }

function Board() {
  const palette = readPreset();
  const flags = readExportFlags();
  const pieces = buildPieces(palette);
  const t = useTime();
  const breathe = flags.flat
    ? 1
    : (t > IN_END && t < HOLD_END)
      ? 1 + 0.012 * Math.sin(((t - IN_END) / HOLD) * Math.PI * 2)
      : 1;
  const pieceFilter = flags.flat ? undefined : "url(#psh)";

  return (
    <svg width="1080" height="1080" viewBox="0 0 1080 1080" style={{ display: "block" }}>
      {!flags.flat && (
        <defs>
          <filter id="psh" x="-30%" y="-30%" width="160%" height="160%">
            <feDropShadow dx="0" dy="6" stdDeviation="10" floodColor={palette.shadow} floodOpacity="0.18" />
          </filter>
        </defs>
      )}

      {/* ghost board — empty slots, always present */}
      {flags.ghost && (
        <g opacity="0.5">
          {pieces.map((p) => (
            <path key={"g" + p.r + p.c} d={p.d} fill={palette.ghostFill} stroke={palette.ghostStroke} strokeWidth="6" />
          ))}
        </g>
      )}

      {/* animated colored pieces */}
      <g style={{ transform: `scale(${breathe})`, transformBox: "fill-box", transformOrigin: "center" }}>
        {pieces.map((p, pi) => {
          const k = orderIndex[pi];
          const inStart = k * STAGGER;
          const outStart = HOLD_END + k * OUT_STAGGER;

          let opacity = 0, ty = -0.55 * S, sc = 0.7, rot = -8;

          if (t >= inStart && t < outStart) {
            // entering / settled
            const pin = clamp01((t - inStart) / IN_DUR);
            const e = Easing.easeOutBack ? Easing.easeOutBack(pin) : pin;
            const f = Easing.easeOutCubic ? Easing.easeOutCubic(pin) : pin;
            opacity = Math.min(1, pin * 1.6);
            ty = -0.55 * S * (1 - e);
            sc = 0.7 + 0.3 * e;
            rot = -8 * (1 - f);
          } else if (t >= outStart) {
            // lifting away
            const pout = clamp01((t - outStart) / OUT_DUR);
            const e = Easing.easeInCubic ? Easing.easeInCubic(pout) : pout;
            opacity = 1 - e;
            ty = -0.45 * S * e;
            sc = 1 - 0.28 * e;
            rot = 6 * e;
          }

          if (opacity <= 0.001) return null;

          return (
            <g
              key={p.r + "-" + p.c}
              style={{
                transformBox: "fill-box",
                transformOrigin: "center",
                transform: `translateY(${ty.toFixed(2)}px) rotate(${rot.toFixed(2)}deg) scale(${sc.toFixed(3)})`,
                opacity,
              }}
            >
              <path d={p.d} fill={p.col} stroke={palette.pieceStroke} strokeWidth="6"
                strokeLinejoin="round" filter={pieceFilter} />
              {/* soft top highlight */}
              <path d={p.d} fill="#ffffff" opacity="0.10" />
            </g>
          );
        })}
      </g>
    </svg>
  );
}

function PuzzleLoader() {
  const palette = readPreset();
  return (
    <Stage width={1080} height={1080} duration={LOOP} loop autoplay background={palette.background}>
      <Board />
    </Stage>
  );
}

window.PuzzleLoader = PuzzleLoader;
window.PuzzleSceneTiming = { IN_END, HOLD_MID, HOLD_END, OUT_END, LOOP };
