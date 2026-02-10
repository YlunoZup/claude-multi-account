const { execSync } = require("child_process");
const { readFileSync, existsSync, writeFileSync, mkdirSync, unlinkSync } = require("fs");
const { homedir } = require("os");
const { join, basename, normalize } = require("path");

const HOME = homedir();
const PROFILES_DIR = join(HOME, ".claude-profiles");
const CONFIG_PATH = join(PROFILES_DIR, "config.json");
const POWERLINE_CONFIG = join(PROFILES_DIR, "claude-powerline.json");

// Shared powerline cache — invalidate when account changes
const CACHE_DIR = join(HOME, ".claude", "powerline", "usage");
const ACCOUNT_MARKER = join(CACHE_DIR, ".last-account");
const TODAY_CACHE = join(CACHE_DIR, "today.json");

// Read stdin synchronously via fd 0
let input = "";
try {
  input = readFileSync(0, "utf8");
} catch {}

// Detect active account
const configDir = process.env.CLAUDE_CONFIG_DIR;
const accountId = configDir ? basename(normalize(configDir)) : "__default__";
let label;

if (!configDir) {
  label =
    "\x1b[48;2;99;66;245m\x1b[38;2;255;255;255m\x1b[1m \u{1F464} Account 1 \x1b[0m\x1b[38;2;99;66;245m\uE0B0\x1b[0m";
} else {
  const dirName = basename(normalize(configDir));
  let name = dirName;

  try {
    const config = JSON.parse(readFileSync(CONFIG_PATH, "utf8"));
    const acc = Object.values(config.accounts).find(
      (a) => a.configDir === dirName
    );
    if (acc) name = acc.name;
  } catch {}

  label = `\x1b[48;2;230;126;34m\x1b[38;2;255;255;255m\x1b[1m \u{1F464} ${name} \x1b[0m\x1b[38;2;230;126;34m\uE0B0\x1b[0m`;
}

// Invalidate shared today cache when account changes
try {
  mkdirSync(CACHE_DIR, { recursive: true });
  let lastAccount = "";
  try {
    lastAccount = readFileSync(ACCOUNT_MARKER, "utf8").trim();
  } catch {}

  if (lastAccount !== accountId) {
    // Account changed — clear today cache so powerline recalculates from correct transcripts
    try { unlinkSync(TODAY_CACHE); } catch {}
    writeFileSync(ACCOUNT_MARKER, accountId, "utf8");
  }
} catch {}

// Run powerline with captured input
let powerline = "";
try {
  const configFlag = existsSync(POWERLINE_CONFIG) ? ` --config "${POWERLINE_CONFIG}"` : "";
  powerline = execSync(`claude-powerline --style=powerline${configFlag}`, {
    input,
    encoding: "utf8",
    timeout: 5000,
    stdio: ["pipe", "pipe", "pipe"],
  }).trim();
} catch {}

process.stdout.write(`${label} ${powerline}\n`);
