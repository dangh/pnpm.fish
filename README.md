# pnpm.fish

### Install

```sh
fisher install dangh/pnpm.fish
```

### What for?

This plugin was born to solve 2 issue with pnpm:

1. pnpm always put global binary in the same directory as `npm`, `node`. (Check out [@pnpm/global-bin-dir](https://github.com/pnpm/pnpm/tree/main/packages/global-bin-dir)). If you're using a nodejs version manager like nvm, it's tedious to re-install the global packages everytime switching nodejs version. The workaround is:
  - Set [`global-dir`](https://pnpm.js.org/en/npmrc#global-dir)
  - Put `global-dir/bin` frontmost in the $PATH when install package

2. `npx pnpm i -g pnpm` [doesn't work](https://github.com/pnpm/pnpm/issues/2873). This plugin workaround the sell-installer to put pnpm binary to the `global-dir`.

