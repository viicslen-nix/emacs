;;; keybinds.el --- Keybinds mirroring flakes/nixvim/config/keybinds.nix -*- lexical-binding: t; -*-

;; Same keys, same descriptions, Emacs commands behind them.  Concatenated onto
;; init.el by flake.nix, so `:ensure t` here is scraped by Nix too.

;;; Code:

(use-package general
  :ensure t
  :demand t
  :after evil
  :config
  (general-evil-setup))

(defun viic/leader (&rest args)
  "Bind ARGS under the SPC leader, as `general-define-key' would.
A function, not a `general-create-definer' macro: this file is byte-compiled
by Nix, and a definer macro only exists once the file has been *loaded*, so
compiling a call to one yields \"Invalid function: viic/leader\"."
  (apply #'general-define-key
         :states '(normal visual motion)
         :keymaps 'override
         :prefix "SPC"
         :global-prefix "M-SPC"
         args))

;; ===== Helper commands (the nixvim `action.__raw` blocks) =====

(defun viic/copy-relative-path ()
  "Copy the current file's path relative to the project root."
  (interactive)
  (let* ((file (or buffer-file-name (user-error "Buffer is not visiting a file")))
         (root (or (when-let ((proj (project-current))) (project-root proj))
                   default-directory))
         (rel (file-relative-name file root)))
    (kill-new rel)
    (message "Copied: %s" rel)))

(defun viic/append-semicolon ()
  "Append a semicolon at the end of the line, staying in normal state."
  (interactive)
  (save-excursion (end-of-line) (insert ";")))

(defun viic/append-comma ()
  "Append a comma at the end of the line, staying in normal state."
  (interactive)
  (save-excursion (end-of-line) (insert ",")))

(defun viic/visual-shift-right ()
  "Indent the selection and keep it selected (`>gv')."
  (interactive)
  (evil-shift-right (region-beginning) (region-end))
  (evil-normal-state)
  (evil-visual-restore))

(defun viic/visual-shift-left ()
  "Unindent the selection and keep it selected (`<gv')."
  (interactive)
  (evil-shift-left (region-beginning) (region-end))
  (evil-normal-state)
  (evil-visual-restore))

(defun viic/clear-search-highlight ()
  "Drop search highlighting (`:noh')."
  (interactive)
  (evil-ex-nohighlight))

;; ===== Non-leader keys =====

;; File operations
(general-define-key
 :states '(normal visual insert)
 :keymaps 'override
 "C-s" #'save-buffer)

;; Visual mode indentation — keep the selection
(general-define-key
 :states 'visual
 ">" #'viic/visual-shift-right
 "<" #'viic/visual-shift-left)

;; Buffer navigation
(general-define-key
 :states 'normal
 :keymaps 'override
 "TAB" #'centaur-tabs-forward
 "<tab>" #'centaur-tabs-forward
 "<backtab>" #'centaur-tabs-backward)

;; LSP / xref
(general-define-key
 :states 'normal
 "gd" #'xref-find-definitions
 "K" #'eldoc-box-help-at-point)

;; Comment toggle (terminals send C-/ as C-_)
(general-define-key
 :states '(normal visual)
 :keymaps 'override
 "C-/" #'evilnc-comment-or-uncomment-lines
 "C-_" #'evilnc-comment-or-uncomment-lines)

;; Window navigation
(general-define-key
 :states '(normal visual motion)
 :keymaps 'override
 "C-h" #'evil-window-left
 "C-j" #'evil-window-down
 "C-k" #'evil-window-up
 "C-l" #'evil-window-right)

;; Clear search highlight
(general-define-key
 :states 'normal
 "<escape>" #'viic/clear-search-highlight)

;; Terminal (toggleterm's <C-\>)
(general-define-key
 :states '(normal insert visual emacs)
 :keymaps 'override
 "C-\\" #'vterm-toggle)

;; Completion popup (nvim-cmp mappings)
(general-define-key
 :states 'insert
 "C-SPC" #'completion-at-point)

(with-eval-after-load 'corfu
  (general-define-key
   :keymaps 'corfu-map
   "C-e" #'corfu-quit
   "RET" #'corfu-insert
   "TAB" #'corfu-next
   "<tab>" #'corfu-next
   "<backtab>" #'corfu-previous
   "C-d" #'corfu-popupinfo-scroll-down
   "C-f" #'corfu-popupinfo-scroll-up))

;; ===== Leader (SPC) =====

(viic/leader
  ";" '(viic/append-semicolon :which-key "Insert semicolon")
  "," '(viic/append-comma :which-key "Insert comma")
  "q" '(kill-current-buffer :which-key "Close buffer")
  "e" '(treemacs :which-key "Explorer")
  "h" '(eldoc-box-help-at-point :which-key "Hover documentation")
  "k" '(flymake-goto-prev-error :which-key "Previous diagnostic")
  "j" '(flymake-goto-next-error :which-key "Next diagnostic")
  "ca" '(eglot-code-actions :which-key "Code action")
  "cf" '(viic/copy-relative-path :which-key "Copy relative file path")
  "rn" '(eglot-rename :which-key "Rename symbol")
  "pd" '(xref-find-definitions-other-window :which-key "Peek definition"))

;; Goto (LSP navigation)
(viic/leader
  "gD" '(eglot-find-declaration :which-key "Go to declaration")
  "gd" '(xref-find-definitions :which-key "Go to definition")
  "gt" '(eglot-find-typeDefinition :which-key "Go to type definition")
  "gi" '(eglot-find-implementation :which-key "List implementations")
  "gr" '(xref-find-references :which-key "LSP finder / references")
  ;; Git
  "gg" '(magit-status :which-key "Open Magit")
  "gs" '(magit-status :which-key "Git status")
  "gl" '(git-link :which-key "Copy git link")
  ;; Worktrees
  "gws" '(magit-worktree :which-key "Worktrees menu")
  "gwc" '(magit-worktree-branch :which-key "New worktree")
  "gwa" '(magit-worktree-checkout :which-key "Worktree for existing branch"))

;; LSP lifecycle
(viic/leader
  "lx" '(eglot-shutdown :which-key "Stop LSP")
  "ls" '(eglot :which-key "Start LSP")
  "lr" '(eglot-reconnect :which-key "Restart LSP"))

;; Find (telescope)
(viic/leader
  "ff" '(consult-fd :which-key "Find files")
  "fg" '(consult-ripgrep :which-key "Live grep")
  "fb" '(consult-buffer :which-key "Buffers")
  "fh" '(consult-info :which-key "Help tags")
  "fr" '(consult-recent-file :which-key "Recent files")
  "fc" '(execute-extended-command :which-key "Commands")
  "fd" '(consult-flymake :which-key "Diagnostics"))

;; Diagnostics lists (trouble)
(viic/leader
  "xx" '(flymake-show-project-diagnostics :which-key "Toggle diagnostics")
  "xd" '(flymake-show-buffer-diagnostics :which-key "Document diagnostics")
  "xq" '(consult-compile-error :which-key "Quickfix list")
  "xl" '(consult-flymake :which-key "Location list")
  "xs" '(consult-imenu :which-key "Symbols")
  "xL" '(consult-eglot-symbols :which-key "LSP symbols"))

;; Debugging (dape)
(viic/leader
  "db" '(dape-breakpoint-toggle :which-key "Toggle breakpoint")
  "dc" '(dape :which-key "Continue/Start debugging")
  "di" '(dape-step-in :which-key "Step into")
  "do" '(dape-next :which-key "Step over")
  "du" '(dape-info :which-key "Toggle DAP UI"))

;;; keybinds.el ends here
