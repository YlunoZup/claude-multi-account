# claude-multi-account

Multi-account switching and a rich powerline statusline for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Switch between Claude accounts with one command and see live session stats at a glance.

## Statusline

The statusline appears at the bottom of every Claude Code session, showing the active account and live metrics powered by [claude-powerline](https://www.npmjs.com/package/claude-powerline):

```
 👤 Account 1  claude-multi-account  main ≡  opus-4  $0.23 │ 5.2k tk  ▓▓▓▓░░ 38%  $1.05  ◐ 42%  3m12s │ 8 msgs
```

| Segment | What it shows |
|---------|---------------|
| **Account badge** | Active account name with colored background (purple = Account 1, orange = Account 2+) |
| **Directory** | Current working directory (basename) |
| **Git** | Branch, working tree status, ongoing operations |
| **Model** | Active Claude model |
| **Session** | Session cost and token count |
| **Block** | Rate-limit block budget usage (weighted cost) |
| **Today** | Total spend across all sessions today |
| **Context** | Context window usage percentage |
| **Metrics** | Session duration and message count |

The account badge color tells you which account is active at a glance — no need to check config or environment variables.

## Account Picker

Run `cc` to get the interactive picker:

```
  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
  ┃                                                  ┃
  ┃   ◆  Claude Code                                ┃
  ┃      Account Switcher                            ┃
  ┃                                                  ┃
  ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
  ┃                                                  ┃
  ┃   [1]  ●  Account 1                             ┃
  ┃            Claude Max 20X                        ┃
  ┃                                                  ┃
  ┃   [2]  ●  Account 2                             ┃
  ┃            Claude Pro                            ┃
  ┃                                                  ┃
  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

  Select account [1/2]:
```

## How It Works

Claude Code uses the `CLAUDE_CONFIG_DIR` environment variable to determine where it reads credentials and config from. This tool manages multiple config directories (one per account) and sets the right env var before launching `claude`.

- **Account 1** uses the default `~/.claude` directory
- **Account 2+** use isolated directories under `~/.claude-profiles/`
- Shared data (projects, todos, settings) is symlinked so all accounts see the same workspace
- Each account keeps its own `.credentials.json` for independent authentication

## Prerequisites

- [Node.js](https://nodejs.org) (v18+)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and in your PATH
- [claude-powerline](https://www.npmjs.com/package/claude-powerline) for statusline segments:

  ```bash
  npm install -g claude-powerline
  ```

## Install

```bash
git clone https://github.com/YlunoZup/claude-multi-account.git
cd claude-multi-account
```

**macOS / Linux / Git Bash:**
```bash
bash install.sh
```

**Windows (CMD):**
```cmd
install.bat
```

The installer will:
1. Create `~/.claude-profiles/` with the picker, statusline, and config files
2. Set up an `account2` directory with symlinks to shared data
3. Configure the statusline in Claude Code's `settings.json`
4. Install the `cc` launcher to `~/.local/bin/`

### Custom install directory

Pass a directory to install the launcher elsewhere:

```bash
bash install.sh /usr/local/bin
```

## Usage

```bash
# Open the interactive account picker
cc

# Launch directly with any account by number
cc 1        # Account 1 (default ~/.claude)
cc 2        # Account 2
cc 3        # Account 3 (if configured)

# Add a new account
cc add              # prompts for a name
cc add My Work      # creates with name "My Work"

# Pass any Claude Code flags after the account number
cc 2 --dangerously-skip-permissions
cc 1 -c    # continue mode
cc 3 -r "fix the bug in auth.ts"
```

## First-Time Setup for New Accounts

After installing, log in with each additional account:

```bash
cc 2    # logs into Account 2
cc 3    # logs into Account 3 (if configured)
```

Claude Code will detect there are no credentials and prompt you to authenticate. Log in with that account. After that, the picker will show the account as configured.

## Configuration

### Account config

Edit `~/.claude-profiles/config.json` to customize account names:

```json
{
  "accounts": {
    "1": { "name": "Account 1 (Personal)", "configDir": null },
    "2": { "name": "Account 2 (Work)", "configDir": "account2" }
  }
}
```

- `name` — Display name shown in the picker and statusline badge
- `configDir` — Subdirectory under `~/.claude-profiles/` (`null` = default `~/.claude`)

### Statusline config

Edit `~/.claude-profiles/claude-powerline.json` to customize which segments appear and their behavior. The config uses the `display.lines[].segments` format:

```json
{
  "display": {
    "lines": [
      {
        "segments": {
          "directory": { "enabled": true, "style": "basename" },
          "git": { "enabled": true },
          "model": { "enabled": true },
          "session": { "enabled": true, "type": "both" },
          "block": { "enabled": true },
          "today": { "enabled": true },
          "context": { "enabled": true },
          "metrics": { "enabled": true, "showDuration": true, "showMessageCount": true }
        }
      }
    ]
  },
  "budget": {
    "session": { "amount": 10.0, "warningThreshold": 80 },
    "block": { "amount": 15.0, "warningThreshold": 80 },
    "today": { "amount": 50.0, "warningThreshold": 80 }
  }
}
```

> **Important:** The config must use `display.lines[].segments` (nested format), not top-level `segments`. The top-level format silently fails and segments won't appear.

### Adding more accounts

Use `cc add` to add a new account in one step:

```bash
cc add                  # prompts for a name
cc add Client Project   # creates with name "Client Project"
```

This automatically:
- Finds the next account number
- Creates the profile directory (`~/.claude-profiles/accountN/`)
- Updates `config.json`
- Sets up `settings.json` with the statusline

Then run `cc N` to log in with the new account. The picker will show it immediately.

## How the Statusline Works

The statusline is a Node.js script (`statusline.js`) that Claude Code runs as an external command. On each refresh:

1. **Account detection** — Reads `CLAUDE_CONFIG_DIR` to determine which account is active, then looks up the display name from `config.json`
2. **Cache invalidation** — When the active account changes, the shared `today.json` cache is cleared so claude-powerline recalculates costs from the correct account's transcripts
3. **Powerline rendering** — Pipes stdin through `claude-powerline --config` to render the configured segments (git, model, session cost, context usage, etc.)
4. **Output** — Concatenates the colored account badge with the powerline output

The cache invalidation step is critical because all accounts share the same `~/.claude/powerline/usage/` directory. Without it, switching from Account 1 to Account 2 would show Account 1's cached daily cost.

## Shared Data

The installer creates symlinks so all accounts share:

| Item | Purpose |
|------|---------|
| `projects/` | Project-specific settings and memory |
| `todos/` | Todo lists |
| `statsig/` | Analytics/feature flags |

**Not shared** (per-account):
- `.credentials.json` — each account has its own login
- `settings.json` — each account has its own settings (needed for individual statusline config)

## Project Structure

```
claude-multi-account/
├── README.md
├── LICENSE
├── .gitignore
├── install.sh                  # Installer for macOS/Linux/Git Bash
├── install.bat                 # Installer for Windows CMD
├── bin/
│   ├── cc                      # Bash launcher script
│   └── cc.bat                  # Windows CMD launcher script
├── src/
│   ├── picker.mjs              # Interactive account picker UI
│   └── statusline.js           # Statusline script (account badge + powerline)
├── config/
│   └── claude-powerline.json   # Default powerline segment configuration
└── config.example.json         # Example account configuration
```

## Uninstall

```bash
rm ~/.local/bin/cc
rm ~/.local/bin/cc.bat      # Windows only
rm -rf ~/.claude-profiles   # Removes all profiles, config, and account2 credentials
```

To remove the statusline, delete the `statusLine` key from `~/.claude/settings.json`.

## License

MIT
