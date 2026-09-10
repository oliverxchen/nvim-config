# Neovim migration plan

> Historical record: the migration is complete. See [`README.md`](README.md) for the current setup and verification instructions. References to Vim below describe the pre-migration repository.

## Goal and assumptions

This is a personal configuration. The repository is public only to make cloning easy, so it does not need to support many users or old versions of Vim.

Assume a recent stable Neovim release (0.12.0 or newer) on macOS or Ubuntu Linux. Use Lua and [`lazy.nvim`](https://github.com/folke/lazy.nvim), with its lockfile committed to the repository. Do not support old Neovim releases. Keep the setup simple enough to run on a Mac and on an Ubuntu VPS.

The migration should preserve useful workflows, not every old plugin. The current repository has no plugin lockfile, and the current setup script installs Vim and Vundle. The new setup should install or verify Neovim, use an idempotent config link, and pin plugin versions.

## Branch and cutover plan

This work is being prepared on the `neovim-migration` branch. It is intended to be a wholesale migration, not a long-term Vim/Neovim compatibility layer.

All migration-level decisions are settled. Implementation on this branch should:

- add the Neovim configuration and `setup_nvim.sh`;
- update the README for Neovim on macOS and Ubuntu;
- remove `vimrc`, `setup_vim.sh`, Vundle references, and Vim-only setup instructions;
- keep this document as the migration and testing checklist.

Do not merge this branch into `main` until the configuration has been tested on both macOS and the Ubuntu VPS. Once those tests pass, merging this branch is the final move from Vim to Neovim. No Vim rollback files are planned after the merge.

## Current setup: what to keep

The current `vimrc` provides the following behavior. Each item includes its purpose and migration decision.

- Filetype detection, syntax, and indentation
  - Purpose: load language-specific behavior.
  - Decision: keep Neovim defaults, then add Treesitter.
- Split navigation mappings
  - Purpose: move between splits.
  - Decision: do not remap `<C-h>`, `<C-j>`, `<C-k>`, or `<C-l>`. Use `<C-w>` followed by `h`, `j`, `k`, or `l`.
- `splitbelow`
  - Purpose: open horizontal splits below the current window.
  - Decision: keep.
- `foldmethod=indent`, `foldlevel=99`, `:Z`
  - Purpose: provide simple code folding and a fold toggle.
  - Decision: keep the fold toggle as `:Z`; start with indent folds and test Treesitter folds later.
- Line numbers and active-window cursorline
  - Purpose: show location and highlight the current line only in the focused split.
  - Decision: keep.
- Indentation rules
  - Purpose: Python uses 4 spaces; JavaScript uses 2; Go uses tabs with width 2; Markdown, JSON, YAML, TOML, Terraform, and SQL use 2 spaces.
  - Decision: keep them in filetype-specific Lua files.
- Git commit settings
  - Purpose: spell checking and two-space indentation.
  - Decision: keep them in `after/ftplugin/gitcommit.lua`.
- `set clipboard=unnamed`
  - Purpose: send yanks to Vim's unnamed clipboard.
  - Decision: change to `unnamedplus` and test macOS, Ubuntu desktop, and SSH clipboard providers.
- `set noswapfile`
  - Purpose: avoid swap files.
  - Decision: do not copy it. Enable swap files and persistent undo for crash recovery.
- Trailing-whitespace highlight/removal
  - Purpose: show some bad whitespace and remove trailing spaces on every write.
  - Decision: remove the global highlighting and write hook. Let the selected formatter handle whitespace.
- `:W` and `:Wq`
  - Purpose: handle common uppercase command typos.
  - Decision: keep.
- Zenburn/Solarized
  - Purpose: provide dark color schemes.
  - Decision: use [`onedark_dark`](https://github.com/olimorris/onedarkpro.nvim) from OneDarkPro as the only theme.

The README also contains VS Code/Cursor settings. Keep those as separate editor documentation. Cmd-key bindings, VS Code format-on-save, the Flutter SDK path, and `composerMode.agent` are not Neovim features.

## Current plugin audit

The current Vundle block declares 18 plugins, including Vundle. “Remove” means remove after the replacement passes the tests below. The repository cannot prove daily use, so each item records its purpose and decision.

- `VundleVim/Vundle.vim`
  - Purpose: install the other Vim plugins.
  - Decision: remove and use `lazy.nvim`; commit `lazy-lock.json`.
- `tpope/vim-fugitive`
  - Purpose: Git commands, diffs, blame, commits, and merge tools. It is installed but has no custom mappings.
  - Decision: keep. It works in Neovim and is a useful fallback to terminal Git.
- `scrooloose/nerdtree`
  - Purpose: file tree. The README documents `:NERDTree`; hidden files are enabled.
  - Decision: keep [Oil](https://github.com/stevearc/oil.nvim) for buffer-style directory editing and add [Neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim) for a persistent tree sidebar.
- `jistr/vim-nerdtree-tabs`
  - Purpose: keep NERDTree synchronized across tabs. No tab workflow is documented.
  - Decision: remove and test the new explorer first.
- `ctrlpvim/ctrlp.vim`
  - Purpose: fuzzy file search. `<C-p>` is documented.
  - Decision: replace with [Telescope](https://github.com/nvim-telescope/telescope.nvim); keep `<C-p>` for files and add live grep.
- `w0rp/ale`
  - Purpose: run ESLint, Flake8, and SQLInt; fix with Prettier, Black, and SQLInt; `<C-M>` runs `:ALEFix`; fix-on-save is off.
  - Decision: replace with `conform.nvim` for format-on-save and `nvim-lint` for standalone linters. Do not run both ALE and the replacements for the same tool.
- `Shougo/deoplete.nvim`
  - Purpose: insert completion. It is enabled at startup but has no custom sources.
  - Decision: remove and use LSP completion through `blink.cmp`.
- `roxma/nvim-yarp` and `roxma/vim-hug-neovim-rpc`
  - Purpose: compatibility layers for older remote plugins.
  - Decision: remove with deoplete. They are not needed for Lua plugins or built-in LSP.
- `tmhedberg/SimpylFold`
  - Purpose: Python folds with docstring preview.
  - Decision: remove. Neovim indent/Treesitter folds are enough; docstring preview is unnecessary.
- `scrooloose/nerdcommenter`
  - Purpose: comment/uncomment commands. Only `g:NERDSpaceDelims` is configured. Recent commits disable its insert mapping because `<Plug>` text leaked into buffers.
  - Decision: remove and use `mini.comment` with `gc`/`gb` mappings.
- `altercation/vim-colors-solarized` and `jnurmine/Zenburn`
  - Purpose: color schemes.
  - Decision: remove both and use OneDarkPro's `onedark_dark` style.
- `vim-airline/vim-airline`
  - Purpose: statusline and tabline. It has no configuration.
  - Decision: remove and use `lualine.nvim`. Git information is required, so the built-in statusline is not enough.
- `Vimjas/vim-python-pep8-indent`
  - Purpose: Python indentation. It has no explicit configuration.
  - Decision: remove. Use Neovim's filetype indentation and project formatters.
- `cespare/vim-toml`
  - Purpose: TOML syntax and filetype support. No TOML command is documented.
  - Decision: remove it. Use the Treesitter TOML parser and Taplo instead. Taplo provides TOML LSP features and formatting.
- `chrisbra/csv.vim`
  - Purpose: CSV syntax and table-editing commands. No CSV workflow is documented.
  - Decision: keep and install it because CSV is used regularly.

### Stale items to delete

Do not copy these into Neovim:

- `g:pydiction_location` points to Pydiction, but Pydiction is not installed by the current Vundle block.
- `g:syntastic_auto_jump` belongs to Syntastic, which is no longer installed.
- The setup script still reminds the user to install `grip`, although Markdown preview was removed from the current README and plugin list.
- Git history contains old Pathogen, YouCompleteMe, Jedi, Rope, SuperTab, Syntastic, Powerline, Python virtualenv, and Markdown preview experiments. They are not migration requirements.
- The Vim Python-host instructions for `pynvim` were needed by the old deoplete setup. Do not install a Python provider unless a retained plugin needs it.

## Recommended Neovim stack

This is the baseline stack. It covers the current workflows and adds the most useful Neovim features without becoming a full distribution.

- Plugin manager
  - Recommendation: [`lazy.nvim`](https://github.com/folke/lazy.nvim).
  - Use: handle dependencies, lazy loading, updates, and a lockfile.
- Syntax and structure
  - Recommendation: [`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter).
  - Use the `main` branch for Neovim 0.12+, enable highlighting with Neovim's native Treesitter API, and install parsers only for languages that are used. The setup script installs Tree-sitter CLI 0.26.1 or newer for parser builds.
- Language intelligence
  - Recommendation: Neovim's built-in LSP with [`nvim-lspconfig`](https://github.com/neovim/nvim-lspconfig) for server configurations.
  - Use: the recent `vim.lsp.config()` and `vim.lsp.enable()` APIs for definitions, references, hover, rename, code actions, diagnostics, and semantic completion.
- Completion
  - Recommendation: [`blink.cmp`](https://github.com/saghen/blink.cmp).
  - Use: LSP, buffer, path, and command-line completion. Do not add snippets until they solve a real problem.
- Files and search
  - Recommendation: Telescope for files, buffers, help, diagnostics, and live grep; Oil for directory editing.
  - Requirement: install `ripgrep` and preferably `fd`.
- Git
  - Recommendation: keep Fugitive and add [`gitsigns.nvim`](https://github.com/lewis6991/gitsigns.nvim).
  - Use: changed-line signs, hunk navigation, previews, staging, and blame.
- Formatting
  - Recommendation: [`conform.nvim`](https://github.com/stevearc/conform.nvim).
  - Use: format the current buffer on save, using the project's formatter settings where available.
- Standalone linting
  - Recommendation: [`nvim-lint`](https://github.com/mfussenegger/nvim-lint).
  - Use: only where an LSP does not already provide the same diagnostics.
- Comments
  - Recommendation: [`mini.comment`](https://github.com/nvim-mini/mini.nvim).
  - Use: `gc` for line/selection comments and `gb` for block comments.
- Statusline
  - Recommendation: [`lualine.nvim`](https://github.com/nvim-lualine/lualine.nvim) with Gitsigns integration.
  - Use: with `laststatus=2`, Neovim's default statusline shows the file name, modified/read-only flags, cursor line/column, and percentage. Recent versions can also show diagnostics, progress, and terminal exit status. Lualine adds a consistent layout; Gitsigns adds the Git branch and changed-line counts.

### Language tools

Start with tools that match the existing config and VS Code settings:

- Python: [`ty`](https://docs.astral.sh/ty/) through `nvim-lspconfig` for type checking and LSP features; Ruff for linting and formatting. Respect each project's configuration.
- JavaScript/TypeScript: the TypeScript language server (`ts_ls` / `typescript-language-server`), ESLint, and Prettier.
- Go: `gopls`, `gofmt`, and optionally `goimports`.
- TOML: use the nvim-treesitter parser for highlighting and structure. Use [Taplo](https://taplo.tamasfe.dev/) for TOML validation, completion, schemas, and formatting through Conform.
  - Install a Taplo build that includes both `taplo lsp` and `taplo fmt`; the npm package does not include the language server. Verify the commands before testing Neovim.
- CSV: keep and install `csv.vim` for CSV syntax and table-editing commands. Add SQL, YAML, JSON, Terraform, and Markdown LSPs or linters when a real project needs them.

Prefer project-managed tools. The setup should not hide the project's required Python, Node, Go, `ty`, Ruff, or Taplo versions.

### Plugin release and maintenance check

Release dates below mean the latest formal GitHub release, checked on 2026-08-18. Some mature plugins use continuous commits or tags instead of formal releases. When the formal release is older than six months, an alternative is listed.

- [`lazy.nvim`](https://github.com/folke/lazy.nvim/releases/tag/v11.17.5)
  - Latest release: `v11.17.5`, 2025-11-06. This is older than six months; the latest commit was 2025-12-17, but it remains the selected plugin manager.
  - Alternatives: Neovim's built-in `vim.pack` (no separate plugin release) or `mini.deps`, included in [`mini.nvim`](https://github.com/nvim-mini/mini.nvim/releases/tag/v0.18.0) `v0.18.0`, 2026-06-21.
- [`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter)
  - No formal GitHub releases. The latest tag is `v0.10.0`, dated 2025-05-18. The repository is still active; its latest commit was 2026-08-15.
  - Alternative: Neovim's built-in filetype and syntax support, which has no separate plugin release but provides less structure-aware highlighting and folding.
- [`nvim-lspconfig`](https://github.com/neovim/nvim-lspconfig/releases/tag/v2.11.0)
  - Latest release: `v2.11.0`, 2026-07-21.
- [`blink.cmp`](https://github.com/saghen/blink.cmp/releases/tag/v1.10.2)
  - Latest release: `v1.10.2`, 2026-04-04.
- [`telescope.nvim`](https://github.com/nvim-telescope/telescope.nvim/releases/tag/v0.2.1)
  - Latest release: `v0.2.1`, 2025-12-31. This is older than six months, although the latest commit was 2026-08-17.
  - Alternatives: [`mini.pick`](https://github.com/nvim-mini/mini.nvim/releases/tag/v0.18.0), part of `mini.nvim` `v0.18.0`, 2026-06-21; or [`fzf-lua`](https://github.com/ibhagwan/fzf-lua), which has no formal releases but had a commit on 2026-08-13.
- [`oil.nvim`](https://github.com/stevearc/oil.nvim/releases/tag/v2.16.0)
  - Latest release: `v2.16.0`, 2026-05-24.
- [`vim-fugitive`](https://github.com/tpope/vim-fugitive)
  - No formal GitHub releases. The latest tag is `v3.7`, dated 2022-06-07. The repository is still active; its latest commit was 2026-03-07.
  - Alternative: [`Neogit`](https://github.com/NeogitOrg/neogit/releases/tag/v2.0.0), whose latest formal release is `v2.0.0`, 2024-11-07. Its latest `v3.0.0` tag is newer, but is not a formal release.
- [`gitsigns.nvim`](https://github.com/lewis6991/gitsigns.nvim/releases/tag/v2.1.0)
  - Latest release: `v2.1.0`, 2026-03-26.
- [`conform.nvim`](https://github.com/stevearc/conform.nvim/releases/tag/v9.1.0)
  - Latest release: `v9.1.0`, 2025-08-22. This is older than six months, although the latest commit was 2026-08-11.
  - Alternatives: Neovim's built-in LSP formatting (no separate plugin release), [`guard.nvim`](https://github.com/nvimdev/guard.nvim/releases/tag/v2.7.0) `v2.7.0`, 2026-01-31, or [`none-ls.nvim`](https://github.com/nvimtools/none-ls.nvim), which has no formal releases but had a commit on 2026-08-10.
- [`nvim-lint`](https://github.com/mfussenegger/nvim-lint)
  - No formal GitHub releases. The latest tag is `nvim-05`, dated 2021-12-04. The repository is still active; its latest commit was 2026-08-17.
  - Alternatives: Neovim's built-in LSP diagnostics (no separate plugin release) or `none-ls.nvim`, which has no formal releases but had a commit on 2026-08-10.
- [`mini.comment`](https://github.com/nvim-mini/mini.nvim)
  - Latest release: `mini.nvim` `v0.18.0`, 2026-06-21.
  - Alternative: [`Comment.nvim`](https://github.com/numToStr/Comment.nvim/releases/tag/v0.8.0) `v0.8.0`, 2023-04-13. It has no recent formal release, so `mini.comment` is preferred.
- [`lualine.nvim`](https://github.com/nvim-lualine/lualine.nvim)
  - No formal GitHub releases. The repository is still active; its latest commit was 2026-05-31.
  - Alternative: [`mini.statusline`](https://github.com/nvim-mini/mini.nvim), included in `mini.nvim` `v0.18.0`, 2026-06-21. It can show Git information through Gitsigns but has fewer ready-made components.
- [`onedarkpro.nvim`](https://github.com/olimorris/onedarkpro.nvim/releases/tag/v2.28.0)
  - Latest release: `v2.28.0`, 2026-03-10. Use the `onedark_dark` style.
- [`csv.vim`](https://github.com/chrisbra/csv.vim)
  - No formal GitHub releases or tags. The latest commit was 2026-07-30.
  - Alternative: [`csvview.nvim`](https://github.com/hat0uma/csvview.nvim/releases/tag/v1.3.0) `v1.3.0`, 2025-09-03. Its latest commit was 2026-05-02, but its formal release is also older than six months.

Language servers, formatters, and linters such as `ty`, Ruff, Prettier, `gopls`, `gofmt`, and Taplo are external tools, not Neovim plugins. Track their versions in each project's package or tool configuration. `ty` is currently beta and uses 0.0.x versions, so pin it and expect occasional breaking changes.

### Plugin selection signals

Popularity is only a rough signal. For a personal configuration, prefer a plugin that is maintained, compatible with the selected Neovim version, documented, and useful to the workflow.

- Check GitHub stars and forks for awareness, then check recent commits, releases, issue responses, and contributors for maintenance.
- Use [Dotfyle's plugin and configuration lists](https://dotfyle.com/neovim) to compare usage in tracked public configurations. This is not a global install count.
- Use [Awesome Neovim](https://github.com/rockerBOO/awesome-neovim) as a curated list, not a ranking.
- Test the plugin's health checks, dependencies, startup cost, and behavior in this configuration before keeping it.

## Decisions with context

These are the choices most likely to affect implementation. The context comes from the current repository, so there is no need to rediscover it.

- Python quality tools
  - Context: Vim uses Flake8 + Black; VS Code uses Ruff actions and Ruff formatting.
  - Decision: use `ty` for Python type checking and LSP features, and Ruff for linting and formatting. Respect each project's existing configuration.
- JavaScript/TypeScript language server
  - Context: Vim runs ESLint through ALE; VS Code uses ESLint and Prettier.
  - Decision: use the TypeScript language server (`ts_ls` / `typescript-language-server`), ESLint, and Prettier. Do not add vtsls.
- Formatting policy
  - Context: Vim formats only when `<C-M>` runs ALE; VS Code formats on save.
  - Decision: use format-on-save to mirror VS Code behaviour, with the formatter selected by filetype and project configuration.
- Theme and statusline
  - Context: two themes and Airline are installed, but none has much configuration. The built-in statusline does not show Git branch or change information.
  - Decision: use OneDarkPro's `onedark_dark` style with Lualine and Gitsigns.
- TOML and CSV
  - Context: Markdown preview was removed, but TOML and CSV are used regularly.
  - Decision: remove `vim-toml`; use Treesitter and Taplo for TOML. Keep and install `csv.vim`.
  - If Taplo fails on either machine, choose another maintained TOML tool during testing; do not restore `vim-toml`.
- Swap files
  - Context: the current config disables them to avoid `.swp` files.
  - Decision: enable swap files and persistent undo for safer recovery.
- Trailing whitespace
  - Context: the current global write hook can change unrelated lines in every file.
  - Decision: remove the global hook and let formatters handle whitespace; add a manual command only if a real workflow needs it.

## Keymap compatibility

- Split navigation
  - Neovim: use `<C-w>` followed by `h`, `j`, `k`, or `l`.
  - Decision: do not define `<C-h>`, `<C-j>`, `<C-k>`, or `<C-l>` mappings because they are used for cursor keys.
- `:Z`
  - Neovim: user command for the normal-mode `za` fold toggle.
- `<C-p>`
  - Neovim: Telescope `find_files`.
- `:NERDTree`
  - Neovim: `:Fe` opens Oil; `<leader>e` or `:E` toggles Neo-tree; `<leader>E` or `:Ee` reveals the current file; `nvim` without a path opens Neo-tree automatically; `:Oil` remains available as the plugin command.
- `<C-M>` / `:ALEFix`
  - Neovim: removed. Conform formats the current buffer on save.
  - Decision: remove because we're changing to format-on-save.
- NERDCommenter mappings
  - Neovim: `gc` and `gb` through `mini.comment`.
- `:W`, `:Wq`
  - Neovim: same custom commands.
- New commands
  - Neovim: `:Fg` searches text, `:Fb` lists buffers, and `:Fe` opens Oil. Telescope files remain on `<C-p>`, with diagnostics on `<leader>fd`; LSP maps such as `gd`, `gr`, `K`, rename, and code actions should be buffer-local when an LSP attaches.

## macOS and Ubuntu setup

The config should not assume Homebrew paths or macOS commands.

- Install a recent Neovim using Homebrew on macOS. On Ubuntu, use a package source that provides the selected recent version. Verify `nvim --version` before setup.
- Require Git, `ripgrep`, and `fd` for the baseline search workflow.
- Verify Taplo is installed with both LSP and formatter support before testing TOML.
- For clipboard support, use `pbcopy`/`pbpaste` on macOS. On Ubuntu desktop, use `wl-copy`/`wl-paste` or `xclip`; over direct SSH use Neovim's [OSC 52 provider](https://neovim.io/doc/user/provider.html), and inside tmux use Neovim's built-in tmux provider. Check `:checkhealth provider` and test copy/paste in each environment.
- Keep Python, Node, Go, `ty`, Ruff, formatters, linters, and language servers project-specific where possible.

Suggested repository layout:

```text
nvim-config/
├── README.md
├── neovim-migration.md
├── nvim/
│   ├── init.lua
│   ├── lua/config/
│   │   ├── options.lua
│   │   ├── keymaps.lua
│   │   └── autocmds.lua
│   ├── lua/plugins/
│   └── after/ftplugin/
├── setup_nvim.sh
└── nvim/lazy-lock.json
```

`setup_nvim.sh` should find its own repository path, safely back up an existing `~/.config/nvim`, create the link, and be safe to run more than once. It should verify required commands and then let lazy.nvim install the locked plugins.

## Migration order

1. **Audit the old setup.** On Vim, run `:PluginList`, `:scriptnames`, `:ALEInfo`, and `:verbose nmap <C-p>`. Try Fugitive, NERDTree, comments, folds, TOML, and CSV once. Mark each feature daily, occasional, or unused.
2. **Implement the wholesale migration on this branch.** Add `nvim/init.lua`, lazy.nvim, the lockfile, core options, and the selected features. Do not build a compatibility layer for `vimrc`.
3. **Add the baseline plugins.** Add Treesitter, Telescope, Oil, Fugitive, Gitsigns, Lualine, blink.cmp, Conform, nvim-lint, `mini.comment`, and CSV support in small groups. Add the external Taplo tool with the TOML parser.
4. **Add language servers and tools.** Start with Python (`ty` + Ruff), then JavaScript/TypeScript or Go. Add SQL and configuration-file tools only when needed.
5. **Test a clean machine.** Clone the public repository on macOS and on the Ubuntu VPS. Run setup twice. Test the matrix below.
6. **Cut over.** Update the README, remove the old Vim artifacts, and complete the acceptance tests. Merge to `main` only after macOS and Ubuntu testing passes.

## Acceptance tests

- A fresh macOS clone and a fresh Ubuntu clone install without editing paths by hand.
- Running setup twice is safe, and the plugin lockfile controls versions.
- Neovim starts without errors or `<Plug>` text in insert mode.
- Clipboard copy/paste works in both environments.
- `<C-w>` plus `h/j/k/l`, `:Z`, `<C-p>`, `:Fg`, `:Fb`, `:Fe`, Fugitive, Lualine Git information, and `gc` work.
- Python has four-space indentation, `ty` type diagnostics and LSP completion/navigation, Ruff diagnostics and formatting, and format-on-save.
- JavaScript/TypeScript has two-space indentation, LSP navigation, ESLint diagnostics, and Prettier formatting.
- Go uses the selected tab policy and `gopls`/`gofmt` when installed.
- Git commit buffers have spell checking and the intended indentation.
- TOML Treesitter highlighting, Taplo validation/formatting, and CSV support work; Markdown, JSON, YAML, Terraform, and SQL have a deliberate keep/remove decision.
- Format-on-save changes only the current buffer and does not use a global whitespace hook.

## Useful references

- [Neovim LSP](https://neovim.io/doc/user/lsp.html)
- [Neovim Treesitter](https://neovim.io/doc/user/treesitter/)
- [Neovim packages](https://neovim.io/doc/user/pack/)
- [Vim/Neovim color schemes](https://vimcolorschemes.com/)
- [Dotfyle top Neovim color schemes](https://dotfyle.com/neovim/colorscheme/top)
- [`ty` editor integration](https://docs.astral.sh/ty/editors/)
- [Taplo TOML language server](https://taplo.tamasfe.dev/cli/usage/language-server.html)
- [`lazy.nvim`](https://github.com/folke/lazy.nvim)
- [`nvim-lspconfig`](https://github.com/neovim/nvim-lspconfig)
- [`lualine.nvim`](https://github.com/nvim-lualine/lualine.nvim)
- [`gitsigns.nvim`](https://github.com/lewis6991/gitsigns.nvim)
- [`onedarkpro.nvim`](https://github.com/olimorris/onedarkpro.nvim)
