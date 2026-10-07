-- Configuration contract tests: run from the repository root with Lua 5.1+.
-- These test formatter selection and arguments, not Oxfmt's formatting engine.
package.path = "./nvim/lua/?.lua;" .. package.path

local config
local root = "/project"
local local_oxfmt
local global_oxfmt = "/tools/bin/oxfmt"
local project_config
local seen_names
local seen_find_opts

vim = {
  g = {},
  b = { [1] = {} },
  fn = {
    exepath = function(name)
      assert(name == "oxfmt")
      return global_oxfmt or ""
    end,
    stdpath = function(name)
      assert(name == "config")
      return "/config/nvim"
    end,
  },
  fs = {
    joinpath = function(a, b)
      return a .. "/" .. b
    end,
    find = function(names, opts)
      seen_names, seen_find_opts = names, opts
      return project_config and { project_config } or {}
    end,
  },
  tbl_extend = function(_, ...)
    local result = {}
    for _, values in ipairs({ ... }) do
      for key, value in pairs(values) do
        result[key] = value
      end
    end
    return result
  end,

}

package.loaded.conform = { setup = function(opts) config = opts end }
package.loaded["config.project_tools"] = {
  repository_root = function() return root end,
  node_tool = function(name)
    assert(name == "oxfmt")
    return root and local_oxfmt or nil
  end,
  python_tool = function() return "/project/.venv/bin/ruff" end,
}
require("config.formatting")

local filetypes = {
  "javascript", "javascriptreact", "typescript", "typescriptreact",
  "json", "jsonc", "yaml", "markdown",
}
local ctx = { buf = 1, dirname = "/project/packages/app/src", filename = "/project/packages/app/src/file.ts" }
local formatter = config.formatters.oxfmt
assert(formatter.inherit == false and formatter.stdin == true)
assert(config.formatters.prettier == nil)

local function check_selection(expected)
  for _, ft in ipairs(filetypes) do
    local selected = config.formatters_by_ft[ft](1)
    assert(#selected == (expected and 1 or 0), ft)
    assert(selected[1] == (expected and "oxfmt" or nil), ft)
  end
  assert(formatter.command(nil, ctx) == (expected or "__nvim_project_tool_missing__"))
  assert(formatter.condition(nil, ctx) == (expected ~= nil))
end

check_selection(global_oxfmt)
local_oxfmt = "/project/packages/app/node_modules/.bin/oxfmt"
check_selection(local_oxfmt)
global_oxfmt = nil
check_selection(local_oxfmt)
local_oxfmt = nil
check_selection(nil)
global_oxfmt = "/tools/bin/oxfmt"
root = nil
check_selection(nil)
assert(config.format_on_save(1) == nil)
root = "/project"
assert(formatter.cwd(nil, ctx) == root)
assert(config.format_on_save(1).timeout_ms == 1000)
assert(config.format_on_save(1).lsp_format == "fallback")
vim.g.disable_autoformat = true
assert(config.format_on_save(1) == nil)
vim.g.disable_autoformat = nil
vim.b[1].disable_autoformat = true
assert(config.format_on_save(1) == nil)
vim.b[1].disable_autoformat = nil

local args = formatter.args(nil, ctx)
assert(table.concat(args, " ") == "--stdin-filepath $FILENAME --config /config/nvim/oxfmt.json")
assert(seen_find_opts.path == ctx.dirname and seen_find_opts.upward and seen_find_opts.type == "file")
assert(table.concat(seen_names, " ") == ".oxfmtrc.json .oxfmtrc.jsonc oxfmt.config.ts oxfmt.config.mts")
for _, name in ipairs(seen_names) do
  project_config = "/project/packages/app/" .. name
  assert(table.concat(formatter.args(nil, ctx), " ") == "--stdin-filepath $FILENAME --config " .. project_config)
end

assert(config.formatters_by_ft.go[1] == "gofmt")
assert(config.formatters_by_ft.python(1)[1] == "ruff_format")
assert(config.formatters_by_ft.sh[1] == "shfmt")
assert(config.formatters_by_ft.terraform[1] == "terraform_fmt")
assert(config.formatters_by_ft.toml[1] == "taplo")
print("PASS: Oxfmt selection for 8 filetypes, local/global/missing tools, config precedence, save guards, and unchanged formatters")
