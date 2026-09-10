# Neovim configuration

Personal Neovim configuration for macOS and Ubuntu Linux.

## Installation

The setup script installs or verifies Neovim and the command-line tools, creates
a safe configuration symlink, installs the locked plugins, and is safe to run
again.

It supports macOS and Ubuntu Linux. On macOS it installs Homebrew if needed. On
Ubuntu it uses `sudo apt-get` for system prerequisites and installs Neovim and
user tools without requiring root for the configuration.

The setup pins Node.js `24.20.0` and Go `1.27.1` on both platforms. It also
enables the `pnpm` and `yarn` Corepack shims next to the user-local tools, so
they continue to point at the pinned Node.js installation. Treesitter uses
Neovim's 0.12-compatible `nvim-treesitter` main branch; setup installs the
required Tree-sitter CLI automatically.

Go is installed under `${XDG_DATA_HOME:-$HOME/.local/share}/go-1.27.1`.
Setup reuses that installation on subsequent runs and updates your shell's PATH
to prefer it. An older system Go can remain installed; open a new shell after
setup completes to use the pinned version.

```bash
git clone https://github.com/oliverxchen/nvim-config.git ~/nvim-config
cd ~/nvim-config
./setup_nvim.sh
```

Open a new terminal after setup so the user-local tool paths take effect. Run
`./setup_nvim.sh` again to update tools and reinstall the locked plugins. The
script installs `lazy.nvim` at the commit recorded in `nvim/lazy-lock.json`.
Normal Neovim startup only verifies and loads that local checkout; it does not
clone, fetch, or check out a Git revision. Use `:Lazy update` when you
deliberately want newer plugin revisions, then review the lockfile and run
setup again.

## Included workflow

- `<C-p>` finds files with fuzzy matching across file and directory names,
  including hidden paths while respecting `.gitignore`; `:Fg` searches text;
  `:Fb` lists buffers; `:Fe` opens Oil for buffer-style directory editing;
  `<leader>e` or `:E` toggles the Neo-tree sidebar, and `<leader>E` or `:Ee`
  reveals the current file in it.
- `<leader>` is Space in this configuration: `<leader>e` means Space then `e`,
  while `<leader>E` means Space then Shift+`e`.
- Starting `nvim` without a path opens Neo-tree automatically; closing all
  non-Neo-tree windows exits Neovim.
- `:Term` opens a terminal in a 10-line-high split at the bottom of the window.
  Press `<Esc>` in terminal mode to enter Normal mode (equivalent to
  `<C-\> C-n`).
- `:Z` toggles folds. Split navigation uses `<C-w>` followed by `h`, `j`, `k`,
  or `l`.
- `gc` and `gb` comment lines or blocks.
- Fugitive provides Git commands. Gitsigns and Lualine show the current branch
  and changed-line counts.
- Diffview provides a single-tab review of Git changes. Use `:DiffviewOpen` to
  compare the working tree with the index (`:DO` is a shortcut),
  `:DiffviewOpen HEAD~2` to compare against another revision, and
  `:DiffviewFileHistory` or `:DiffviewFileHistory %` for branch or current-file
  history. Close the view with `:DiffviewClose` or `:DC`; `<Tab>` and `<S-Tab>`
  cycle through changed files.
- The TypeScript language server, `ty`, `gopls`, and Taplo provide language
  intelligence when their tools apply.
- Conform formats supported files on save when the appropriate project-local
  formatter is available. Ruff, ESLint, and other linters report diagnostics
  separately.
- Swap files and persistent undo are enabled for recovery.

For troubleshooting, use `:checkhealth`, `:checkhealth vim.lsp`,
`:checkhealth neo-tree`, and `:Lazy` inside Neovim. The configuration expects
Neovim 0.12.0 or newer.

## Project-local formatters and Python tools

Ruff and ty are not installed globally by the setup script. Prettier is
installed in the user-local Node.js tool directory as a fallback for Markdown,
while repository-local versions take precedence:

- For Markdown, Prettier is resolved from the nearest
  `node_modules/.bin/prettier` between the current file and the repository
  root, then from the user-local global Prettier installation.
- Other Prettier-supported filetypes require the nearest repository-local
  `node_modules/.bin/prettier`.
- Ruff and ty are resolved from the active `$VIRTUAL_ENV`, or from a `.venv`,
  `venv`, or `env` directory in the current repository.
- Repository detection follows the current file; for an unnamed buffer it uses
  Neovim's current working directory, so starting Neovim from a repository also
  works.
- Autoformatting and repository linters are disabled when the current file is
  outside a Git repository. Markdown can use the global fallback inside a
  repository; other Prettier-supported filetypes still need a project-local
  formatter.

For example, install the tools in the project rather than globally:

```bash
# JavaScript/TypeScript/JSON/YAML/Markdown projects
pnpm add --save-dev prettier
# or: npm install --save-dev prettier

# Python projects using uv
uv add --dev ruff ty
uv run ruff --version
uv run ty --version
```

The setup still installs `uv` itself as an environment manager, and keeps
ESLint, `eslint_d`, Prettier, TypeScript, and `typescript-language-server` in
the user-local Node.js tool directory. Use `:ConformInfo` to see which
formatter was selected for the current buffer.

## Supported tools and behavior

- Python: project-environment `ty` for type checking and LSP features; project-
  environment Ruff for diagnostics and formatting; four-space indentation.
- JavaScript and TypeScript: `ts_ls`, ESLint, and project-local Prettier;
  Markdown also has a user-local global fallback; two-space indentation. The
  setup uses TypeScript 6 because `typescript-language-server` needs
  `tsserver.js`.
- Go: pinned `gopls` `v0.23.0` and pinned Go `1.27.1`'s `gofmt`; tabs with a
  width of two.
- TOML: Treesitter highlighting and Taplo for validation, completion, and
  formatting, with two-space indentation for nested tables and entries.
- JSON, YAML, and Markdown: Treesitter and Prettier. Terraform uses
  `terraform fmt` when Terraform is installed. SQL has highlighting only. CSV
  uses `csv.vim`.
- Git commit buffers: spell checking and two-space indentation.

Normal `y` and `p` use the system clipboard through `unnamedplus`. macOS uses
its native clipboard; Ubuntu desktop uses Wayland or X11 tools; direct SSH uses
OSC 52; SSH inside tmux uses Neovim's tmux provider. Check
`:checkhealth provider` if clipboard behavior is unexpected. In tmux,
`tmux info | grep 'Ms:'` should show an `Ms` capability.

Swap files and persistent undo are enabled for recovery. Formatting runs on
save for supported file types inside repositories when a formatter is available.
The global trailing-whitespace hook from the Vim configuration was intentionally
removed.

## Verification

Run setup twice on both macOS and Ubuntu:

```bash
./setup_nvim.sh
./setup_nvim.sh
```

Open a new shell afterward so user-local paths are loaded. Confirm the main
tools:

```bash
nvim --version
node --version # v24.20.0
go version # go1.27.1
tsc --version
typescript-language-server --version
gopls version
corepack --version
tree-sitter --version
taplo lsp --help
taplo fmt --help
```

Neovim should start without errors, use the `onedark_dark` theme, show Git
branch and change counts, open Neo-tree as a left sidebar with `<leader>e` or
`:E`, and keep the lockfile unchanged during normal setup. Test `nvim` with no
path, Oil with `:Fe`, Neo-tree with `<leader>e`, `:E`, `:Ee`, and `<leader>E`,
and one file of each commonly used type: Python, TypeScript, JavaScript, Go,
TOML, Markdown, JSON, YAML, Terraform, SQL, and CSV. For language buffers,
`:checkhealth vim.lsp` should show the expected client; `:checkhealth neo-tree`
should pass; `:ConformInfo` shows the selected formatter.

The detailed migration plan is kept in
[`neovim-migration.md`](neovim-migration.md). It records the old Vim plugin
audit, rejected alternatives, and the reasons for the current choices; it is not
needed for normal installation.

## Updates to shell profile

The setup script adds these settings to the relevant shell profile:

```bash
export EDITOR=nvim
export VISUAL=nvim
export GIT_EDITOR=nvim
alias vim=nvim
alias vi=nvim
```

## VS Code/Cursor vim mode

Execute the following command in a terminal to allow holding a direction to
scroll:

```
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
```

For cursor, find the app address:

```
cd /Applications
mdls -name kMDItemCFBundleIdentifier Cursor.app
```

And then use the output with the `defaults write` command.

Add the following to VSCode's `settings.json` to be able to yank into the system
clipboard:

```
    "vim.useSystemClipboard": true
```

Go to the command pallete cmd+shift+P and select: "Preferences: Open Keyboard
Shortcuts (JSON)" add to the keybindings.json file

```
// Place your key bindings in this file to override the defaults
[
    {
        "key":     "cmd+j",
        "command": "workbench.action.terminal.focus"
    },
    {
        "key":     "cmd+j",
        "command": "workbench.action.focusActiveEditorGroup",
        "when":    "terminalFocus"
    },
    {
        "key":     "cmd+r",
        "command": "workbench.action.terminal.runSelectedText"
    },
    {
        "key": "shift+enter",
        "command": "-python.execInREPL",
        "when": "config.python.REPL.sendToNativeREPL && editorTextFocus && !accessibilityModeEnabled && !isCompositeNotebook && !jupyter.ownsSelection && !notebookEditorFocused && editorLangId == 'python'"
    },
    {
        "key": "shift+enter",
        "command": "-python.execSelectionInTerminal",
        "when": "editorTextFocus && !findInputFocussed && !isCompositeNotebook && !jupyter.ownsSelection && !notebookEditorFocused && !replaceInputFocussed && editorLangId == 'python'"
    },
    {
      "key": "cmd+i",
      "command": "composerMode.agent",
    },
    {
      "key": "shift+cmd+0",
      "command": "workbench.action.terminal.focusPrevious",
    },
    {
      "key": "shift+cmd+backspace",
      "command": "workbench.action.terminal.focusNext",
    },
]
```

User settings in VS Code:

```
{
  "dart.flutterSdkPath": "/Users/oliverchen/src/flutter",
  "editor.minimap.enabled": false,
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "vim.useSystemClipboard": true,
  "[python]": {
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll": "explicit",
      "source.organizeImports": "explicit"
    },
    "editor.defaultFormatter": "charliermarsh.ruff"
  },
  "[javascript]": {
    "editor.tabSize": 2
  },
  "[javascriptreact]": {
    "editor.tabSize": 2
  },
  "[typescript]": {
    "editor.tabSize": 2
  },
  "[typescriptreact]": {
    "editor.tabSize": 2
  },
  "files.associations": {
    ".cursorrules": "plaintext"
  },
  "git.openRepositoryInParentFolders": "never",
  "editor.accessibilitySupport": "off",
  "git.confirmSync": false
}
```
