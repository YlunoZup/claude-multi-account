# claude-multi-account

A multi-account switcher for [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code). Switch between Claude accounts (personal, work, different tiers) with a single command.

```
  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
  ┃                                                    ┃
  ┃   ◆  Claude Code                                   ┃
  ┃      Account Switcher                              ┃
  ┃                                                    ┃
  ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
  ┃                                                    ┃
  ┃   [1]  ●  Account 1                                ┃
  ┃            Claude Max 20X                          ┃
  ┃                                                    ┃
  ┃   [2]  ●  Account 2                                ┃
  ┃            Claude Pro                              ┃
  ┃                                                    ┃
  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

  Select account [1/2]:
```

## How It Works

Claude Code uses the `CLAUDE_CONFIG_DIR` environment variable to determine where it reads credentials and config from. This tool manages multiple config directories (one per account) and sets the right env var before launching `claude`.

- **Account 1** uses the default `~/.claude` directory
- **Account 2+** use isolated directories under `~/.claude-profiles/`
- Shared data (projects, todos, settings) is symlinked so all accounts see the same workspace

## Prerequisites

- [Node.js](https://nodejs.org) (v18+)
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and in your PATH

## Install

```bash
git clone https://github.com/YOUR_USERNAME/claude-multi-account.git
cd claude-multi-account
```

**macOS / Linux:**
```bash
bash install.sh
```

**Windows (Git Bash):**
```bash
bash install.sh
```

**Windows (CMD):**
```cmd
install.bat
```

The installer will:
1. Create `~/.claude-profiles/` with the picker and config
2. Set up an `account2` directory with symlinks to shared data
3. Install the `cc` launcher to `~/.local/bin/`

### Custom install directory

Pass a directory as an argument to install the launcher elsewhere:

```bash
bash install.sh /usr/local/bin
```

## Usage

```bash
# Open the interactive account picker
cc

# Launch directly with Account 1 (default ~/.claude)
cc 1

# Launch directly with Account 2
cc 2

# Pass any Claude Code flags after the account number
cc 2 --dangerously-skip-permissions
cc 1 -c    # continue mode
cc 2 -r "fix the bug in auth.ts"
```

## First-Time Setup for Account 2

After installing, you need to log in with your second account once:

```bash
cc 2
```

Claude Code will detect there are no credentials and prompt you to authenticate. Log in with your second Claude account. After that, the picker will show both accounts as configured.

## Configuration

Edit `~/.claude-profiles/config.json` to customize account names:

```json
{
  "accounts": {
    "1": { "name": "Personal (Max)", "configDir": null },
    "2": { "name": "Work (Pro)", "configDir": "account2" }
  }
}
```

- `name` — Display name shown in the picker
- `configDir` — Subdirectory under `~/.claude-profiles/` (`null` = default `~/.claude`)

### Adding More Accounts

1. Create a new directory: `mkdir ~/.claude-profiles/account3`
2. Add it to `config.json`:
   ```json
   {
     "accounts": {
       "1": { "name": "Personal", "configDir": null },
       "2": { "name": "Work", "configDir": "account2" },
       "3": { "name": "Client Project", "configDir": "account3" }
     }
   }
   ```
3. Run `cc 3` to log in with the new account

> **Note:** Quick-switch shortcuts (`cc 1` / `cc 2`) are hardcoded in the launcher scripts for speed. For accounts 3+, use the interactive picker or edit `bin/cc` to add more shortcuts.

## Shared Data

The installer creates symlinks so all accounts share:

| Item | Purpose |
|------|---------|
| `projects/` | Project-specific settings and memory |
| `todos/` | Todo lists |
| `settings.json` | Claude Code preferences |
| `statsig/` | Analytics/feature flags |

Credentials (`.credentials.json`) are **not** shared — each account has its own login.

## Project Structure

```
claude-multi-account/
├── README.md              # This file
├── LICENSE                # MIT License
├── install.sh             # Installer for macOS/Linux/Git Bash
├── install.bat            # Installer for Windows CMD
├── bin/
│   ├── cc                 # Bash launcher script
│   └── cc.bat             # Windows CMD launcher script
├── src/
│   └── picker.mjs         # Node.js account picker UI
└── config.example.json    # Example configuration
```

## Uninstall

```bash
rm ~/.local/bin/cc
rm ~/.local/bin/cc.bat      # Windows only
rm -rf ~/.claude-profiles   # Removes picker, config, and account2 credentials
```

## License

MIT
