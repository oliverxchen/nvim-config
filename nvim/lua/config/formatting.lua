local conform = require("conform")
local project_tools = require("config.project_tools")

local function missing_project_tool()
  return "__nvim_project_tool_missing__"
end

local function project_formatter(name, resolver)
  return {
    command = function(_, ctx)
      return resolver(name, ctx.buf) or missing_project_tool()
    end,
    condition = function(_, ctx)
      return resolver(name, ctx.buf) ~= nil
    end,
  }
end

local function oxfmt_command(bufnr)
  local command = project_tools.node_tool("oxfmt", bufnr)
  if command then
    return command
  end

  if project_tools.repository_root(bufnr) then
    command = vim.fn.exepath("oxfmt")
    if command ~= "" then
      return command
    end
  end
end

local function oxfmt_formatter_command(_, bufnr)
  return oxfmt_command(bufnr)
end

conform.setup({
  formatters_by_ft = {
    go = { "gofmt" },
    javascript = function(bufnr)
      return oxfmt_command(bufnr) and { "oxfmt" } or {}
    end,
    javascriptreact = function(bufnr)
      return oxfmt_command(bufnr) and { "oxfmt" } or {}
    end,
    json = function(bufnr)
      return oxfmt_command(bufnr) and { "oxfmt" } or {}
    end,
    jsonc = function(bufnr)
      return oxfmt_command(bufnr) and { "oxfmt" } or {}
    end,
    markdown = function(bufnr)
      return oxfmt_command(bufnr) and { "oxfmt" } or {}
    end,
    python = function(bufnr)
      return project_tools.python_tool("ruff", bufnr) and { "ruff_format" } or {}
    end,
    sh = { "shfmt" },
    terraform = { "terraform_fmt" },
    toml = { "taplo" },
    typescript = function(bufnr)
      return oxfmt_command(bufnr) and { "oxfmt" } or {}
    end,
    typescriptreact = function(bufnr)
      return oxfmt_command(bufnr) and { "oxfmt" } or {}
    end,
    yaml = function(bufnr)
      return oxfmt_command(bufnr) and { "oxfmt" } or {}
    end,
  },
  formatters = {
    oxfmt = vim.tbl_extend("force", project_formatter("oxfmt", oxfmt_formatter_command), {
      -- Conform v9.1.0 predates its built-in Oxfmt formatter.
      inherit = false,
      stdin = true,
      args = function(_, ctx)
        local config = vim.fs.find({
          ".oxfmtrc.json",
          ".oxfmtrc.jsonc",
          "oxfmt.config.ts",
          "oxfmt.config.mts",
        }, { path = ctx.dirname, upward = true, type = "file" })[1]

        -- Resolve from the buffer, even when Neovim was opened elsewhere.
        -- Only use editor defaults when no project Oxfmt config applies.
        return {
          "--stdin-filepath",
          "$FILENAME",
          "--config",
          config or vim.fs.joinpath(vim.fn.stdpath("config"), "oxfmt.json"),
        }
      end,
      cwd = function(_, ctx)
        return project_tools.repository_root(ctx.buf)
      end,
    }),
    ruff_format = vim.tbl_extend("force", project_formatter("ruff", project_tools.python_tool), {
      args = {
        "format",
        "--force-exclude",
        "--stdin-filename",
        "$FILENAME",
        "-",
      },
    }),
    taplo = {
      command = "taplo",
      args = {
        "fmt",
        "--stdin-filepath",
        "$FILENAME",
        "--option",
        "indent_tables=true",
        "--option",
        "indent_entries=true",
        "--option",
        "indent_string=  ",
        "-",
      },
    },
  },
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat
      or vim.b[bufnr].disable_autoformat
      or not project_tools.repository_root(bufnr)
    then
      return
    end

    return {
      timeout_ms = 1000,
      lsp_format = "fallback",
    }
  end,
})
