# mason-lock.nvim

Provides lockfile functionality to [mason.nvim](https://github.com/williamboman/mason.nvim)

## Install

```lua
-- lazy.nvim
require("lazy").setup({
  "zapling/mason-lock.nvim", init = function() require("mason-lock").setup() end},
})
```

## Usage

Installing and updating packages via `:Mason` updates the lockfile automatically.

- `:MasonLock` Creates a lockfile that includes all currently installed packages
- `:MasonLockRestore` Re-installs all packages with the version specified in the lockfile
