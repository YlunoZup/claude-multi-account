import { readFileSync, existsSync } from "fs";
import { createInterface } from "readline";
import { homedir } from "os";
import { join } from "path";

const HOME = homedir();
const PROFILES_DIR = join(HOME, ".claude-profiles");
const CONFIG_PATH = join(PROFILES_DIR, "config.json");

// ── Colors & Styles ──────────────────────────────────────────
const c = {
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  dim: "\x1b[2m",
  italic: "\x1b[3m",
  white: "\x1b[97m",
  gray: "\x1b[90m",
  cyan: "\x1b[36m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  magenta: "\x1b[35m",
  blue: "\x1b[34m",
  bgDim: "\x1b[48;5;236m",
  orange: "\x1b[38;5;208m",
};

// ── Load Config ──────────────────────────────────────────────
let config;
try {
  config = JSON.parse(readFileSync(CONFIG_PATH, "utf8"));
} catch {
  config = {
    accounts: {
      1: { name: "Account 1", configDir: null },
      2: { name: "Account 2", configDir: "account2" },
    },
  };
}

// ── Read Credential Info ─────────────────────────────────────
function getAccountInfo(configDir) {
  const dir = configDir ? join(PROFILES_DIR, configDir) : join(HOME, ".claude");
  const credPath = join(dir, ".credentials.json");

  if (!existsSync(credPath)) {
    return { ready: false, tier: null, sub: null };
  }

  try {
    const creds = JSON.parse(readFileSync(credPath, "utf8"));
    const oauth = creds.claudeAiOauth || {};
    return {
      ready: true,
      sub: oauth.subscriptionType || "unknown",
      tier: oauth.rateLimitTier || "unknown",
    };
  } catch {
    return { ready: false, tier: null, sub: null };
  }
}

function formatTier(info) {
  if (!info.ready) return `${c.yellow}${c.dim}not configured${c.reset}`;

  const tier = info.tier || "";
  // Parse tier like "default_claude_max_20x" → "Max 20x"
  const match = tier.match(/max_(\d+x)/i);
  if (match) {
    return `${c.orange}${c.bold}Claude Max ${match[1].toUpperCase()}${c.reset}`;
  }
  if (info.sub === "max") {
    return `${c.orange}${c.bold}Claude Max${c.reset}`;
  }
  if (info.sub === "pro") {
    return `${c.cyan}${c.bold}Claude Pro${c.reset}`;
  }
  return `${c.white}${info.sub}${c.reset}`;
}

// ── Build Account List ───────────────────────────────────────
const accounts = Object.entries(config.accounts).map(([key, acc]) => {
  const info = getAccountInfo(acc.configDir);
  return { key, name: acc.name, configDir: acc.configDir, ...info };
});

// ── Write to stderr so shell wrapper can capture stdout for data ──
const log = (msg = "") => process.stderr.write(msg + "\n");

// ── Render UI ────────────────────────────────────────────────
function render() {
  const W = 50;
  const line = "━".repeat(W);
  const space = " ".repeat(W);

  log("");
  log(`  ${c.dim}${c.cyan}┏${line}┓${c.reset}`);
  log(`  ${c.dim}${c.cyan}┃${c.reset}${space}${c.dim}${c.cyan}┃${c.reset}`);
  const title = `   ${c.orange}${c.bold}◆${c.reset}  ${c.white}${c.bold}Claude Code${c.reset}`;
  log(`  ${c.dim}${c.cyan}┃${c.reset}${title}${" ".repeat(Math.max(0, W - stripAnsi(title).length))}${c.dim}${c.cyan}┃${c.reset}`);
  const subtitle = `      ${c.dim}Account Switcher${c.reset}`;
  log(`  ${c.dim}${c.cyan}┃${c.reset}${subtitle}${" ".repeat(Math.max(0, W - stripAnsi(subtitle).length))}${c.dim}${c.cyan}┃${c.reset}`);
  log(`  ${c.dim}${c.cyan}┃${c.reset}${space}${c.dim}${c.cyan}┃${c.reset}`);
  log(`  ${c.dim}${c.cyan}┣${line}┫${c.reset}`);
  log(`  ${c.dim}${c.cyan}┃${c.reset}${space}${c.dim}${c.cyan}┃${c.reset}`);

  for (const acc of accounts) {
    const status = acc.ready
      ? `${c.green}●${c.reset}`
      : `${c.dim}○${c.reset}`;
    const tierStr = formatTier(acc);
    const nameStr = `${c.white}${c.bold}${acc.name}${c.reset}`;

    // Account row
    const row1 = `   ${c.dim}[${c.reset}${c.white}${c.bold}${acc.key}${c.reset}${c.dim}]${c.reset}  ${status}  ${nameStr}`;
    log(`  ${c.dim}${c.cyan}┃${c.reset}${row1}${" ".repeat(Math.max(0, W - stripAnsi(row1).length))}${c.dim}${c.cyan}┃${c.reset}`);

    // Tier row
    const row2 = `         ${tierStr}`;
    log(`  ${c.dim}${c.cyan}┃${c.reset}${row2}${" ".repeat(Math.max(0, W - stripAnsi(row2).length))}${c.dim}${c.cyan}┃${c.reset}`);

    log(`  ${c.dim}${c.cyan}┃${c.reset}${space}${c.dim}${c.cyan}┃${c.reset}`);
  }

  log(`  ${c.dim}${c.cyan}┗${line}┛${c.reset}`);
  log("");
}

function stripAnsi(str) {
  return str.replace(/\x1b\[[0-9;]*m/g, "");
}

// ── Prompt ───────────────────────────────────────────────────
function prompt() {
  const rl = createInterface({ input: process.stdin, output: process.stderr });
  const keys = accounts.map((a) => a.key).join("/");

  rl.question(
    `  ${c.white}${c.bold}Select account ${c.dim}[${keys}]${c.reset}${c.white}${c.bold}: ${c.reset}`,
    (answer) => {
      rl.close();
      const choice = answer.trim();

      if (choice === "q" || choice === "Q") {
        log(`  ${c.dim}Cancelled.${c.reset}`);
        process.exit(0);
      }

      const acc = accounts.find((a) => a.key === choice);
      if (!acc) {
        log(`  ${c.yellow}Invalid choice. Enter ${keys} or q to quit.${c.reset}`);
        prompt();
        return;
      }

      if (!acc.ready) {
        log(
          `\n  ${c.yellow}${acc.name} not configured yet — Claude will prompt you to log in.${c.reset}\n`
        );
      }

      // stdout: only the profile path (read by shell wrapper)
      if (acc.configDir) {
        process.stdout.write(join(PROFILES_DIR, acc.configDir));
      } else {
        process.stdout.write("__DEFAULT__");
      }
    }
  );
}

render();
prompt();
