<div align="center">

# emacs

**A Nix-built Emacs (evil + eglot) that mirrors the NixVim setup.**

[![Emacs pgtk](https://img.shields.io/badge/Emacs-pgtk-7F5AB6?style=flat-square&logo=gnuemacs&logoColor=white)](https://www.gnu.org/software/emacs/)
[![emacs-overlay](https://img.shields.io/badge/packages-emacs--overlay-5277C3?style=flat-square&logo=nixos&logoColor=white)](https://github.com/nix-community/emacs-overlay)
[![flake-parts](https://img.shields.io/badge/built_with-flake--parts-7EBAE4?style=flat-square&logo=nixos&logoColor=white)](https://flake.parts)

</div>

Built the same way `flakes/nixvim` builds Neovim: a flake-parts flake whose
`packages.default` is a fully configured editor. The elisp config is the source
of truth — [`emacs-overlay`](https://github.com/nix-community/emacs-overlay)'s
`emacsWithPackagesFromUsePackage` scrapes every `:ensure t` out of it, resolves
each to a Nix-built elisp package and bakes the result into the wrapper.
`package.el` never downloads anything at runtime.

> [!NOTE]
> Personal configuration. Borrow from it freely, but expect it to follow my
> habits rather than Emacs defaults.

## Outputs

Systems: `x86_64-linux`, `aarch64-linux`.

| Output | What it is |
| --- | --- |
| `packages.default` | `emacs-pgtk` with all configured packages and every tree-sitter grammar; `emacs` and `emacsclient` wrapped with LSP servers, formatters and search tools on `PATH` |
| `apps.default` | `nix run` entry point for the above |
| `devShells.default` | `nix-output-monitor` + `alejandra` |
| `formatter` | treefmt: deadnix → statix → alejandra |
| `checks.treefmt` | fails if anything is unformatted |
| `checks.statix` | `statix check`, which catches what `statix fix` skips (e.g. W20 repeated keys) |

No NixOS or Home Manager modules are exported — just the package.

## Usage

Try it without installing:

```bash
nix run github:viicslen-nix/emacs
```

Consume it as a flake input:

```nix
{
  inputs.emacs = {
    url = "github:viicslen-nix/emacs";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # …then, in a module:
  home.packages = [inputs.emacs.packages.${pkgs.stdenv.hostPlatform.system}.default];
}
```

In `/etc/nixos` it is a `path:./flakes/emacs` input, installed by the `personal`
preset as `pkgs.inputs.emacs.default`.

## Layout

| File | Role |
| --- | --- |
| `flake.nix` | package set, Emacs build, `PATH` wrapper for LSP servers/formatters |
| `apps.nix` | `apps.default` |
| `treefmt.nix` | formatter / lint configuration |
| `config/init.el` | editor options + packages (mirrors `nixvim/config/default.nix`) |
| `config/keybinds.el` | keybinds (mirrors `nixvim/config/keybinds.nix`) |

Both elisp files are concatenated into one init file, so `:ensure t` is scraped
from either.

> [!WARNING]
> Never put `:ensure t` on a built-in package — there is no melpa/elpa attribute
> to resolve, and evaluation fails.

## Tools on `PATH`

| Kind | Packages |
| --- | --- |
| Language servers | `nil`, `typescript-language-server`, `vue-language-server`, `pyright`, `gopls`, `lua-language-server`, `bash-language-server`, `vscode-langservers-extracted`, `tailwindcss-language-server`, `terraform-ls`, `marksman`, `sqls`, `clang-tools`, `zls`, `phpactor` |
| Formatters (apheleia) | `alejandra`, `prettier`, `stylua` |
| Search / VCS | `ripgrep`, `fd`, `git` |

## Development

```bash
nix run .          # try the config; capped: nix run . --option cores 3
nix fmt            # deadnix, statix, alejandra via treefmt
nix flake check    # treefmt + statix gates
```

<details>
<summary><strong>Mapping from the NixVim config</strong></summary>

Same keys, same `which-key` descriptions, Emacs commands behind them.

| NixVim | Emacs |
| --- | --- |
| modal editing | `evil` + `evil-collection` |
| leader (`SPC`) maps | `general.el`, via the `viic/leader` helper |
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

</details>

<details>
<summary><strong>Why emacs-overlay, not a module system</strong></summary>

There is no `nixvim` for Emacs — no project exposes every Emacs package as a
NixOS-module option tree. Rejected alternatives:
`nix-doom-emacs-unstraightened`, which buys into Doom's whole framework, and
`jeslie0/emacs-init`, which does declare `use-package` blocks as Nix options but
is a one-maintainer project.

</details>
