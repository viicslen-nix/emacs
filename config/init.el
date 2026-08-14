;;; init.el --- Nix-managed Emacs configuration -*- lexical-binding: t; -*-

;; Mirrors flakes/nixvim: same editor options, the same plugin roles, and the
;; same keybinds (keybinds live in ./keybinds.el, which flake.nix concatenates
;; onto the end of this file).
;;
;; Packages come from Nix: `emacsWithPackagesFromUsePackage` scrapes every
;; `:ensure t` below and pulls that package from `epkgs`.  Never put `:ensure t`
;; on a built-in package — there is no melpa/elpa attribute to resolve.

;;; Code:

;; ===== Core options (nixvim `opts` / `globals`) =====
(use-package emacs
  :init
  (setq inhibit-startup-screen t
        ring-bell-function 'ignore
        ;; Nix byte-compiles this file but cannot native-compile it, so Emacs
        ;; does that asynchronously on first run — and every `use-package`
        ;; :config body trips "might not be defined at runtime", popping up
        ;; *Warnings* at every startup. Keep it in the compile log instead.
        native-comp-async-report-warnings-errors 'silent
        use-short-answers t
        make-backup-files nil            ; backup = false
        auto-save-default nil            ; swapfile = false
        create-lockfiles nil
        scroll-margin 8                  ; scrolloff = 8
        scroll-conservatively 101
        mouse-wheel-progressive-speed nil
        display-line-numbers-type 'relative ; number + relativenumber
        select-enable-clipboard t        ; clipboard = unnamedplus
        custom-file (expand-file-name "custom.el" user-emacs-directory))
  (setq-default indent-tabs-mode nil     ; expandtab
                tab-width 4              ; tabstop = 4
                standard-indent 4        ; shiftwidth = 4
                truncate-lines t         ; wrap = false
                fill-column 80)          ; colorcolumn = "80"
  ;; transparent = true (onedark's `transparent`), matched to the compositor.
  (add-to-list 'default-frame-alist '(alpha-background . 92))
  :config
  (menu-bar-mode -1)
  (when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
  (when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
  (global-display-line-numbers-mode 1)
  (global-hl-line-mode 1)                          ; cursorline
  (global-display-fill-column-indicator-mode 1)    ; colorcolumn
  (electric-pair-mode 1)                           ; nvim-autopairs
  (context-menu-mode 1)                            ; mouse = "a"
  (savehist-mode 1)
  (save-place-mode 1)
  (recentf-mode 1))

;; undofile = true
(use-package undo-fu :ensure t)
(use-package undo-fu-session
  :ensure t
  :config (undo-fu-session-global-mode 1))

;; ===== Modal editing (the whole point of mirroring a Neovim config) =====
(use-package evil
  :ensure t
  :demand t
  :init
  (setq evil-want-keybinding nil         ; required by evil-collection
        evil-want-integration t
        evil-want-C-u-scroll t
        evil-undo-system 'undo-fu
        evil-shift-width 4
        evil-split-window-below t        ; splitbelow
        evil-vsplit-window-right t)      ; splitright
  :config
  (evil-mode 1)
  ;; mapleader = " " — general.el's definer in keybinds.el owns SPC, so keep
  ;; SPC free of any motion binding.
  (evil-set-leader '(normal visual motion) (kbd "SPC")))

(use-package evil-collection
  :ensure t
  :after evil
  :config (evil-collection-init))

(use-package evil-surround                ; nvim-surround
  :ensure t
  :after evil
  :config (global-evil-surround-mode 1))

(use-package evil-nerd-commenter :ensure t :after evil) ; Comment.nvim

(use-package evil-escape                  ; "jk" to leave insert state
  :ensure t
  :after evil
  :init (setq evil-escape-key-sequence "jk"
              evil-escape-delay 0.15)
  :config (evil-escape-mode 1))

(use-package avy :ensure t)               ; leap.nvim

;; ===== UI =====
(use-package doom-themes                  ; onedark, "darker"
  :ensure t
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (load-theme 'doom-one t)
  (require 'doom-themes-ext-org)          ; extension file, not autoloaded
  (doom-themes-org-config))

(use-package nerd-icons :ensure t)        ; web-devicons

(use-package doom-modeline                ; lualine
  :ensure t
  :init (setq doom-modeline-height 25
              doom-modeline-buffer-file-name-style 'relative-from-project)
  :config (doom-modeline-mode 1))

(use-package centaur-tabs                 ; bufferline
  :ensure t
  :demand t
  :init (setq centaur-tabs-style "slant"
              centaur-tabs-set-icons t
              centaur-tabs-set-close-button nil
              centaur-tabs-set-modified-marker t)
  :config
  ;; Internal buffers (*Warnings*, *Messages*, compile logs…) are not files —
  ;; keep them off the tab line, like bufferline does.
  (defun viic/centaur-tabs-hide-tab (buffer)
    (let ((name (buffer-name buffer)))
      (and (string-prefix-p "*" name)
           (not (member name '("*dashboard*" "*scratch*" "*vterm*"))))))
  (setq centaur-tabs-hide-tab-function #'viic/centaur-tabs-hide-tab)
  (centaur-tabs-mode 1))

(use-package dashboard                    ; alpha
  :ensure t
  :init (setq dashboard-startup-banner 'logo
              dashboard-center-content t
              dashboard-items '((recents . 5) (projects . 5) (bookmarks . 5)))
  :config (dashboard-setup-startup-hook))

(use-package which-key
  :ensure t
  :init (setq which-key-idle-delay 0.3
              ;; Defaults to 0, which butts every column against the next one.
              which-key-add-column-padding 3
              which-key-separator " → "
              which-key-min-display-lines 6
              which-key-max-description-length 32)
  :config
  ;; Name the leader groups, so they stop rendering as a wall of "+prefix".
  (which-key-add-key-based-replacements
    "SPC c" "code"
    "SPC d" "debug"
    "SPC f" "find"
    "SPC g" "goto/git"
    "SPC gw" "worktree"
    "SPC l" "lsp"
    "SPC p" "peek"
    "SPC r" "refactor"
    "SPC x" "diagnostics")
  (which-key-mode 1))

(use-package indent-bars                  ; indent-blankline
  :ensure t
  :hook ((prog-mode . indent-bars-mode)))

(use-package rainbow-mode                 ; colorizer
  :ensure t
  :hook ((prog-mode . rainbow-mode)))

(use-package symbol-overlay               ; illuminate
  :ensure t
  :hook ((prog-mode . symbol-overlay-mode)))

(use-package treemacs                     ; snacks explorer
  :ensure t
  :config
  ;; Treemacs' workspaces accumulate every project you ever opened. Mirror the
  ;; snacks explorer instead: show the current project, and only that, tracking
  ;; whichever buffer is selected.
  (require 'treemacs-project-follow-mode) ; separate file, not autoloaded
  (treemacs-project-follow-mode 1))
(use-package treemacs-evil :ensure t :after (treemacs evil))

;; Icon theme closest to VS Code's Material Icon Theme: all-the-icons carries
;; the Material Design / Devicons / FileIcons sets with per-filetype colours.
;; The fonts are installed system-wide by the desktop preset, not by
;; `all-the-icons-install-fonts'.
(use-package all-the-icons :ensure t)
(use-package treemacs-all-the-icons
  :ensure t
  :after (treemacs all-the-icons)
  :demand t
  :config (treemacs-load-theme "all-the-icons"))

;; ===== Completion & search (telescope + nvim-cmp) =====
(use-package vertico
  :ensure t
  :config (vertico-mode 1))

(use-package orderless
  :ensure t
  :init (setq completion-styles '(orderless basic)
              completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :ensure t
  :config (marginalia-mode 1))

(use-package consult
  :ensure t
  :init (setq consult-narrow-key "<"
              ;; file_ignore_patterns, mirroring the telescope defaults
              consult-ripgrep-args
              (concat "rg --null --line-buffered --color=never --max-columns=1000 "
                      "--path-separator / --smart-case --no-heading --with-filename "
                      "--line-number --hidden "
                      "--glob !node_modules --glob !.git --glob !vendor")))

(use-package corfu                        ; cmp
  :ensure t
  :init (setq corfu-auto t
              corfu-auto-prefix 2
              corfu-cycle t
              corfu-popupinfo-delay '(0.3 . 0.2))
  :config
  (global-corfu-mode 1)
  (require 'corfu-popupinfo)              ; extension file, not autoloaded
  (corfu-popupinfo-mode 1))

(use-package cape                         ; cmp sources: path / buffer
  :ensure t
  :init
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-dabbrev))

(use-package yasnippet                    ; luasnip
  :ensure t
  :config (yas-global-mode 1))

;; ===== LSP (eglot; nixvim's `lsp.servers`) =====
;; The servers themselves are on PATH via the Nix wrapper — see flake.nix.
(use-package eglot
  :hook ((nix-mode
          typescript-ts-mode tsx-ts-mode js-ts-mode
          web-mode python-ts-mode go-ts-mode lua-mode
          sh-mode bash-ts-mode html-mode css-ts-mode
          terraform-mode markdown-mode sql-mode
          c-ts-mode c++-ts-mode zig-mode php-mode) . eglot-ensure)
  :init (setq eglot-autoshutdown t
              eglot-extend-to-xref t)
  :config
  (add-to-list 'eglot-server-programs '(nix-mode . ("nil")))
  (add-to-list 'eglot-server-programs '(zig-mode . ("zls")))
  (add-to-list 'eglot-server-programs '(terraform-mode . ("terraform-ls" "serve")))
  (add-to-list 'eglot-server-programs '(php-mode . ("phpactor" "language-server")))
  (add-to-list 'eglot-server-programs '(sql-mode . ("sqls")))
  (add-to-list 'eglot-server-programs '(web-mode . ("vue-language-server" "--stdio"))))

(use-package eldoc-box :ensure t)         ; lspsaga hover_doc (rounded float)
(use-package consult-eglot :ensure t :after (consult eglot))

(use-package treesit-auto                 ; treesitter (grammars come from Nix)
  :ensure t
  :init (setq treesit-auto-install nil)   ; auto_install is Nix's job here
  :config
  (global-treesit-auto-mode 1))

(use-package apheleia                     ; conform/eslint fix-on-save
  :ensure t
  :config (apheleia-global-mode 1))

;; ===== Git =====
(use-package magit :ensure t)             ; fugitive + lazygit
(use-package diff-hl                      ; gitsigns
  :ensure t
  :config
  (global-diff-hl-mode 1)
  (require 'diff-hl-flydiff)              ; extension file, not autoloaded
  (diff-hl-flydiff-mode 1)
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh))
(use-package git-link :ensure t)          ; gitlinker
;; git-conflict → built-in smerge-mode
(use-package smerge-mode
  :hook ((find-file . (lambda () (save-excursion
                                   (goto-char (point-min))
                                   (when (re-search-forward "^<<<<<<< " nil t)
                                     (smerge-mode 1)))))))

;; ===== Terminal (toggleterm) =====
(use-package vterm :ensure t)
(use-package vterm-toggle
  :ensure t
  :after vterm
  :init (setq vterm-toggle-fullscreen-p nil))

;; ===== Debugging (dap) =====
(use-package dape
  :ensure t
  :init (setq dape-buffer-window-arrangement 'right))

;; ===== AI (avante/copilot analogue) =====
(use-package gptel :ensure t)

;; ===== Major modes not covered by tree-sitter's built-in mode list =====
(use-package nix-mode :ensure t :mode "\\.nix\\'")
(use-package lua-mode :ensure t :mode "\\.lua\\'")
(use-package php-mode :ensure t :mode "\\.php\\'")
(use-package zig-mode :ensure t :mode "\\.zig\\'")
(use-package terraform-mode :ensure t :mode "\\.tf\\(vars\\)?\\'")
(use-package markdown-mode :ensure t :mode "\\.md\\'")
(use-package web-mode                     ; .vue / .blade.php
  :ensure t
  :mode ("\\.vue\\'" "\\.blade\\.php\\'"))
