# emacs

Nix-configured Emacs, built the same way `flakes/nixvim` builds Neovim: a
flake-parts flake whose `packages.default` is a fully configured editor.

There is no `nixvim` for Emacs — no project exposes every Emacs package as a
NixOS-module option tree. The closest equivalent, and what this flake uses, is
[`emacs-overlay`](https://github.com/nix-community/emacs-overlay)'s
`emacsWithPackagesFromUsePackage`: the elisp config is the source of truth, and
Nix reads it, resolves every `:ensure t` to a Nix-built elisp package, and bakes
the result into the wrapper. Nothing is fetched at runtime; `package.el` never
downloads anything.

(The other options, both rejected here: `nix-doom-emacs-unstraightened`, which
buys into Doom's whole framework, and `jeslie0/emacs-init`, which does declare
`use-package` blocks as Nix options but is a one-maintainer project.)

## Layout

| File | Role |
| --- | --- |
| `flake.nix` | package set, emacs build, PATH wrapper for LSP servers/formatters |
| `apps.nix` | `nix run .` |
| `config/init.el` | editor options + packages (mirrors `nixvim/config/default.nix`) |
| `config/keybinds.el` | keybinds (mirrors `nixvim/config/keybinds.nix`) |

Both elisp files are concatenated into one init file, so `:ensure t` is scraped
from either. **Never put `:ensure t` on a built-in package** — there is no
melpa/elpa attribute to resolve and evaluation fails.

## Trying it

```bash
nix run .            # capped: nix run . --option cores 3
```

## Mapping from the NixVim config

Same keys, same `which-key` descriptions, Emacs commands behind them.

| NixVim | Emacs |
| --- | --- |
| evil-less modal editing | `evil` + `evil-collection` |
| leader (`SPC`) maps | `general.el` definer `viic/leader` |
| telescope | `vertico` + `consult` + `orderless` + `marginalia` |
| nvim-cmp / luasnip | `corfu` + `cape` + `yasnippet` |
| lspconfig / lspsaga | `eglot` + `eldoc-box` + `consult-eglot` |
| trouble | `flymake` + `consult-flymake` |
| snacks explorer | `treemacs` |
| gitsigns / fugitive / lazygit / gitlinker | `diff-hl` / `magit` / `git-link` |
| worktrees.nvim | `magit-worktree` |
| dap + dap-ui | `dape` |
| toggleterm | `vterm-toggle` |
| bufferline / lualine / alpha | `centaur-tabs` / `doom-modeline` / `dashboard` |
| onedark (darker, transparent) | `doom-one` + `alpha-background` |
| Comment.nvim / nvim-surround / leap | `evil-nerd-commenter` / `evil-surround` / `avy` |
| avante / copilot | `gptel` |

Not mirrored, because there is no Emacs counterpart worth writing from scratch:
`laravel.nvim`'s `<leader>ll*` maps, `neotest`+pest's `<leader>t*` maps, and the
`mcphub`/`phpantom`/`laravel-lsp` integrations. PHP gets `phpactor` instead.
