# mason-lock.nvim

Provides lockfile functionality to [mason.nvim](https://github.com/williamboman/mason.nvim)

## Install

```lua
-- lazy.nvim
require("lazy").setup({
  "zapling/mason-lock.nvim", init = function()
    require("mason-lock").setup({
        lockfile_path = vim.fn.stdpath("config") .. "/mason-lock.json" -- (default)
    }) 
  end},
})
```

## Usage

Installing and updating packages via `:Mason` updates the lockfile automatically.

- `:MasonLock` Creates a lockfile that includes all currently installed packages
- `:MasonLockRestore` Re-installs all packages with the version specified in the lockfile

## Example lockfile

```json
{
  "angular-language-server": "17.1.1",
  "bash-language-server": "5.1.2",
  "biome": "1.6.4",
  "css-lsp": "4.8.0",
  "eslint-lsp": "4.8.0",
  "golangci-lint": "v1.57.1",
  "gopls": "v0.15.2",
  "lua-language-server": "3.7.4",
  "omnisharp": "v1.39.8",
  "prettier": "3.2.5",
  "shellcheck": "v0.9.0",
  "templ": "v0.2.648",
  "vtsls": "0.1.25"
}
```
