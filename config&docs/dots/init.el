;; =============================================================================
;; Emacs Config (single-file)
;; - Minimal UI, Windows-like word nav/delete
;; - Notepad++-style keys where sensible
;; - Chrome-like tabs (C-Tab/CS-Tab, C-n new tab, C-w close)
;; - Helm + helm-swoop (C-f), undo-tree (C-z/C-S-z), popwin
;; - Org shift-select integration with CUA
;; - Runtime files under var/ (recentf, places, server, autosaves, undo)
;; - Custom UI writes to var/custom.el (keeps init.el clean)
;; =============================================================================

;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.



;; TODO: verify the ctrl+f functionallity. Suspecting that it might be buggy now
;; TODO: the git-sidebar thing status, does not check when git status changes 

;;(package-initialize)
(require 'org)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Minimal UI                                                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setq-default indent-tabs-mode nil)
(setq org-display-inline-images t)
(setq org-redisplay-inline-images t)
(setq org-startup-with-inline-images "inlineimages")

(setq default-frame-alist
      (append (list '(width . 72) '(height . 40))))

(setq org-confirm-elisp-link-function nil)
      
	

(cond
 ((string-equal system-type "windows-nt")
  (progn
    (set-frame-font "Lucida Console 10")))
 ((string-equal system-type "gnu/linux")
  (progn
    (set-frame-font "Noto Mono Light 10"))))



(set-frame-parameter (selected-frame) 'internal-border-width 20)
(setq x-underline-at-descent-line t)
(setq initial-major-mode 'text-mode)
(setq-default line-spacing 0)
(set-default 'cursor-type  '(hbar . 2))
(blink-cursor-mode 1)
;; Hide fringes; we rely on margin indicators for diff-hl
(fringe-mode '(0 . 0))

(setq frame-background-mode 'light)
(set-background-color "#ffffff")
(set-foreground-color "#666666")
(set-face-attribute 'fringe nil :background "#ffffff" :foreground "#666666")

(setq inhibit-startup-screen t)
(setq inhibit-startup-echo-area-message t)
(setq inhibit-startup-message t)   ;; Show/hide startup page
(setq initial-scratch-message nil) ;; Show/hide *scratch* buffer message
;; (menu-bar-mode 0)                  ;; Show/hide menubar
(tool-bar-mode 0)                  ;; Show/hide toolbar
(tooltip-mode  0)                  ;; Show/hide tooltip
;; Enable a right-hand scroll bar for quick navigation
(set-scroll-bar-mode 'right)
(scroll-bar-mode 1)



(defun mode-line-render (left right)
  "Return a string of `window-width' length containing left, and
   right aligned respectively."
  (let* ((available-width (- (window-total-width) (length left) )))
    (format (format "%%s %%%ds" available-width) left right)))


;; Helper: detect if current buffer differs from Git (vc) state
(defun my--buffer-vc-dirty-p ()
  (when (and buffer-file-name (vc-backend buffer-file-name))
    (let ((st (vc-state buffer-file-name)))
      (memq st '(edited added removed needs-merge needs-update needs-checkin conflicting)))))

;; Helper: propertize buffer name by state
(defun my--buffer-name-with-state-face ()
  (let* ((name (buffer-name))
         (face (cond
                ((and buffer-file-name (buffer-modified-p))
                 '(:weight regular :foreground "#cc3333"))  ;; unsaved to disk => red
                ((my--buffer-vc-dirty-p)
                 '(:weight regular :foreground "#ff8800"))  ;; differs from Git => orange
                (t '(:weight regular :foreground "black")))))
    (propertize name 'face face)))

(setq-default header-line-format
  '(:eval (mode-line-render

   (format-mode-line
    (list
     (propertize "File " 'face `(:weight regular))
     '(:eval (my--buffer-name-with-state-face))
     " "
     '(:eval (if (and buffer-file-name (buffer-modified-p))
                 (propertize "(modified)"
                             'face `(:weight light :foreground "#aaaaaa"))))))

   (format-mode-line
    (propertize "%3l:%2c "
	'face `(:weight light :foreground "#aaaaaa"))))))

(set-face-attribute 'region nil
		    :background "#f0f0f0")
(set-face-attribute 'highlight nil
		    :foreground "black"
		    :background "#f0f0f0")
(set-face-attribute 'org-level-1 nil
		    :foreground "black"
		    :weight 'regular)
(set-face-attribute 'org-link nil
		    :underline nil
		    :foreground "dark blue")
(set-face-attribute 'org-verbatim nil
		    :foreground "dark blue")
(set-face-attribute 'bold nil
		    :foreground "black"
		    :weight 'regular)
;; Dim line numbers to reduce visual weight vs code
(set-face-attribute 'line-number nil
                    :foreground "#cccccc"
                    :background "#ffffff"
                    :weight 'light)
(set-face-attribute 'line-number-current-line nil
                    :foreground "#888888"
                    :background "#ffffff"
                    :weight 'regular)


(setq-default mode-line-format   "")

(set-face-attribute 'header-line nil
;;                    :weight 'regular
		    :height 140
                    :underline "black"
                    :foreground "black"
		    :background "white"
                    :box `(:line-width 3 :color "white" :style nil))
(global-display-line-numbers-mode 1)
(set-face-attribute 'mode-line nil
                    :height 10
                    :underline "black"
                    :background "white"
		                :foreground "white"
                    :box nil)
(set-face-attribute 'mode-line-inactive nil
                    :box nil
                    :inherit 'mode-line)
(set-face-attribute 'mode-line-buffer-id nil 
                    :weight 'light)
(setq org-hide-emphasis-markers t)







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Consolidated Config (single-file)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Lightweight settings previously in _1settings.el
(require 'cl-lib)
(setq make-backup-files nil)
(setq auto-save-default nil)
(setq mouse-wheel-scroll-amount '(6 ((shift) . 1) ((control) . nil)))
(setq mouse-wheel-progressive-speed nil)
(setq scroll-step 1)
(global-set-key [escape] 'keyboard-escape-quit)

;; Centralize runtime files under var/
(defconst user-var-dir (expand-file-name "var/" user-emacs-directory))
(unless (file-directory-p user-var-dir) (make-directory user-var-dir t))
(setq recentf-save-file (expand-file-name "recentf" user-var-dir))
(setq save-place-file (expand-file-name "places" user-var-dir))
;; Auto-save list directory
(let ((asdir (expand-file-name "auto-save-list" user-var-dir)))
  (unless (file-directory-p asdir) (make-directory asdir t))
  (setq auto-save-list-file-prefix (concat asdir "/saves-")))
;; Server socket dir
(let ((server-dir (expand-file-name "server" user-var-dir)))
  (setq server-socket-dir server-dir)
  (unless (file-directory-p server-dir) (make-directory server-dir t)))
;; Keep Custom UI writes out of init.el
(setq custom-file (expand-file-name "custom.el" user-var-dir))
(when (file-exists-p custom-file) (load custom-file))
(load "server")
(unless (server-running-p) (server-start))
(show-paren-mode 1)
(setq vc-follow-symlinks t)
(setq visible-bell 1)
(desktop-save-mode 0)
(global-set-key [mouse-3] 'mouse-popup-menubar-stuff)
(recentf-mode 1)
(setq recentf-max-saved-items 200)
(save-place-mode 1)
(delete-selection-mode 1)

;; Auto-revert also checks VC info to reflect Git changes
(setq auto-revert-verbose nil)
(setq auto-revert-check-vc-info t)
(setq auto-revert-interval 2)
(global-auto-revert-mode 1)

;; Packages (from _2packages.el)
(require 'package)
(unless package-archive-contents (package-refresh-contents))
(unless (assoc 'helm-swoop package-archive-contents)
  (ignore-errors (package-refresh-contents)))
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(when (and (not (package-installed-p 'helm-swoop))
           (fboundp 'package-vc-install))
  (ignore-errors (package-vc-install "https://github.com/emacsorphanage/helm-swoop")))
(when (and (boundp 'package-quickstart) package-quickstart
           (fboundp 'package-quickstart-refresh))
  (let ((qs-file (expand-file-name "package-quickstart.el" user-emacs-directory)))
    (unless (file-exists-p qs-file)
      (ignore-errors (package-quickstart-refresh)))))
;; which-key: show possible key continuations
(use-package which-key :ensure t :config (which-key-mode))
;; command-log-mode: log commands (handy for demos/debug)
(use-package command-log-mode :ensure t)
(defun xah-start-command-log ()
  (interactive)
  (command-log-mode)
  (global-command-log-mode)
  (clm/open-command-log-buffer)
  (delete-window))
;; helm: completion and narrowing UI
(use-package helm
  :ensure t
  :init (setq helm-candidate-number-limit 100
              helm-ff-skip-boring-files t)
  :config (helm-mode 1)
  :bind (("M-x" . helm-M-x)
         ("C-x f" . helm-for-files)
         ("C-r" . helm-recentf)))
;; undo-tree: linear+tree undo with persistent history
(use-package undo-tree
  :ensure t
  :diminish undo-tree-mode
  :init
  (let ((dir (expand-file-name "var/undo-tree-history" user-emacs-directory)))
    (setq undo-tree-history-directory-alist `(("." . ,dir)))
    (setq undo-tree-auto-save-history t)
    (unless (file-directory-p dir) (make-directory dir t)))
  (global-undo-tree-mode 1)
  :config (defalias 'redo 'undo-tree-redo)
  :bind (("C-z" . undo) ("C-S-z" . redo)))
;; popwin: tame special buffers into popups
(use-package popwin
  :ensure t
  :config (progn
            (push '("*Warnings*" :position bottom :height .3) popwin:special-display-config)
            (push '("*Diff*" :position bottom :height .6) popwin:special-display-config)
            (popwin-mode 1)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VCS Gutter Indicators (diff-hl + git-gutter)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; STATUS NOTE (read me):
;; - On this Windows build, diff-hl's fringe colors render gray (faces nil) and
;;   margin backgrounds can be ignored; this made diff-hl unreliable/blank.
;; - We keep diff-hl configured (margin mode, right side, ASCII glyphs) but we
;;   rely on git-gutter as the primary, reliable gutter.
;; - To try diff-hl in GUI: enable fringes `(fringe-mode '(8 . 8))`, then
;;   `(diff-hl-margin-mode -1)`. Toggle `my-diff-hl-debug` to `t` to log state.
;; - To stick with margins: keep fringes hidden and `(diff-hl-margin-mode 1)`.
;; - LF/CRLF prompts are unrelated to the gutter and can be tuned later.
;; Shows green for added lines, blue for modified, red for deleted
(use-package diff-hl
  :ensure t
  :init
  ;; Enable globally at init and after init; also enable immediately if reloading
  (global-diff-hl-mode 1)
  (add-hook 'after-init-hook #'global-diff-hl-mode)
  (when (boundp 'after-init-time)
    (when after-init-time (global-diff-hl-mode 1)))
  :config
  ;; Ensure flydiff is active whenever diff-hl-mode is enabled
  (add-hook 'diff-hl-mode-hook #'diff-hl-flydiff-mode)
  ;; Prefer margins for reliability across ports; use RIGHT margin to avoid line-number collisions
  (setq diff-hl-margin-side 'right)
  ;; Use visible ASCII glyphs (not spaces) so color shows reliably in margins
  (setq diff-hl-margin-symbols-alist
        '((insert . "||") (change . "||") (delete . "||") (unknown . "?") (ignored . " ")))
  (diff-hl-margin-mode 1)
  ;; Make fringe rendering (if used) cleaner and remove gray borders
  (setq diff-hl-fringe-bmp-function 'diff-hl-fringe-bmp-from-type)
  (setq diff-hl-draw-borders nil)
  ;; Allow diff-hl on TRAMP/remote files (use at your own risk performance-wise)
  (setq diff-hl-disable-on-remote nil)
  ;; Make sure VC recognizes Git; some setups clear this variable
  (when (boundp 'vc-handled-backends)
    (unless (memq 'Git vc-handled-backends)
      (push 'Git vc-handled-backends)))
  ;; Ensure mode is active in file buffers; reserve chosen margin; refresh
  (add-hook 'find-file-hook (lambda ()
                              (when buffer-file-name
                                (diff-hl-mode 1)
                                (when (vc-backend buffer-file-name)
                                  (my--ensure-margin-for-diff-hl)
                                  (diff-hl-update)
                                  (when (bound-and-true-p my-diff-hl-debug)
                                    (my-diff-hl-diagnose "find-file"))))))
  (add-hook 'window-setup-hook #'my--ensure-margin-for-diff-hl)
  (add-hook 'window-size-change-functions #'my--ensure-margin-for-diff-hl)
  ;; Colors similar to VSCode
  (set-face-attribute 'diff-hl-insert nil :inherit nil :foreground "#2ea043")
  (set-face-attribute 'diff-hl-change nil :inherit nil :foreground "#388bfd")
  (set-face-attribute 'diff-hl-delete nil :inherit nil :foreground "#f85149")
  ;; Style margin faces with strong foreground colors (background may be ignored in margins)
  (ignore-errors
    (set-face-attribute 'diff-hl-margin-insert nil :inherit nil :foreground "#2ea043" :background 'unspecified :weight 'bold)
    (set-face-attribute 'diff-hl-margin-change nil :inherit nil :foreground "#388bfd" :background 'unspecified :weight 'bold)
    (set-face-attribute 'diff-hl-margin-delete nil :inherit nil :foreground "#f85149" :background 'unspecified :weight 'bold))
  ;; And the fringe faces when using fringes
  (ignore-errors
    (set-face-attribute 'diff-hl-fringe-insert nil :inherit nil :foreground "#2ea043" :background "#2ea043")
    (set-face-attribute 'diff-hl-fringe-change nil :inherit nil :foreground "#388bfd" :background "#388bfd")
    (set-face-attribute 'diff-hl-fringe-delete nil :inherit nil :foreground "#f85149" :background "#f85149"))

  ;; Diagnostics and quick toggles to help troubleshoot themes/TTY
  (defun my-diff-hl--face-summary (face)
    (list face
          :fg (ignore-errors (face-attribute face :foreground nil))
          :bg (ignore-errors (face-attribute face :background nil))
          :inh (ignore-errors (face-attribute face :inherit nil))))

  (defun my-diff-hl-diagnose (&optional ctx)
    "Show current diff-hl/margin/VC state for debugging. Optional CTX notes where it ran."
    (interactive)
    (let* ((vc (and buffer-file-name (vc-backend buffer-file-name)))
           (state (and buffer-file-name vc (ignore-errors (vc-state buffer-file-name))))
           (wm (window-margins))
           (fr (fringe-mode))
           (msg (format "diff-hl%s: global=%s, buffer=%s, margin=%s/%s, vc=%s, state=%s, margins=%S, graphic=%s, fringe=%S, bmp=%S, borders=%s, fringe-face=%S"
                        (if ctx (format "[%s]" ctx) "")
                        (bound-and-true-p global-diff-hl-mode)
                        (bound-and-true-p diff-hl-mode)
                        (bound-and-true-p diff-hl-margin-mode)
                        diff-hl-margin-side vc state wm (display-graphic-p)
                        fr (and (boundp 'diff-hl-fringe-bmp-function) diff-hl-fringe-bmp-function)
                        (and (boundp 'diff-hl-draw-borders) diff-hl-draw-borders)
                        (my-diff-hl--face-summary 'fringe))))
      (message "%s" msg)
      (message "faces: %S %S %S | fringe: %S %S %S"
               (my-diff-hl--face-summary 'diff-hl-fringe-insert)
               (my-diff-hl--face-summary 'diff-hl-fringe-change)
               (my-diff-hl--face-summary 'diff-hl-fringe-delete)
               (my-diff-hl--face-summary 'diff-hl-margin-insert)
               (my-diff-hl--face-summary 'diff-hl-margin-change)
               (my-diff-hl--face-summary 'diff-hl-margin-delete))))

  (defvar my-diff-hl-debug nil "If non-nil, log diff-hl updates to *Messages*.")
  (defun my--diff-hl-update-log (&rest _)
    (when my-diff-hl-debug
      (my-diff-hl-diagnose "update")))
  (advice-add 'diff-hl-update :after #'my--diff-hl-update-log)

  (defun my-diff-hl-use-fringe ()
    "Disable margin mode and enable fringes for diff-hl to test visibility."
    (interactive)
    (diff-hl-margin-mode -1)
    (fringe-mode '(8 . 8))
    ;; Use stock bitmaps and remove borders so color stands out
    (setq diff-hl-fringe-bmp-function 'diff-hl-fringe-bmp-from-type)
    (setq diff-hl-draw-borders nil)
    (when (bound-and-true-p my-diff-hl-debug)
      (my-diff-hl-diagnose "use-fringe-before"))
    (diff-hl-mode 1)
    (diff-hl-update)
    (when (bound-and-true-p my-diff-hl-debug)
      (my-diff-hl-diagnose "use-fringe-after")))

  (defun my-diff-hl-use-margin ()
    "Enable margin mode and ensure right margin is visible."
    (interactive)
    (diff-hl-margin-mode 1)
    (setq diff-hl-margin-side 'left)
    (my--ensure-margin-for-diff-hl)
    (when (bound-and-true-p my-diff-hl-debug)
      (my-diff-hl-diagnose "use-margin-before"))
    (diff-hl-update)
    (when (bound-and-true-p my-diff-hl-debug)
      (my-diff-hl-diagnose "use-margin-after")))
  ;; Keep in sync with Magit refreshes if Magit is used
  (with-eval-after-load 'magit
    (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Primary Gutter: git-gutter
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; - Rationale: diff-hl's fringe faces stayed nil; margin backgrounds were
;;   ignored on this Windows build, making markers gray/invisible. git-gutter
;;   draws consistent signs across ports.
;; - Colors: green added, blue modified, red deleted.
;; - Noise control: update calls are silenced to avoid write-region spam.
;; - To revert to diff-hl: disable `global-git-gutter-mode`, enable fringes, and
;;   disable diff-hl margin mode.
(use-package git-gutter
  :ensure t
  :init
  ;; Performance: disable live idle-timer updates; we'll update on events
  (setq git-gutter:live-update nil)
  ;; Only use Git backend to avoid calling external "diff" for other VCs
  (setq git-gutter:handled-backends '(git))
  ;; Do NOT enable globally — only enable in Git buffers to avoid calling `diff`
  ;; on non-repo files (Windows often lacks a `diff` program)
  :config
  ;; Belt-and-suspenders: prevent the live-update timer from ever starting,
  ;; and make the live-update callback a no-op if some timer still fires.
  (with-eval-after-load 'git-gutter
    (advice-add 'git-gutter:start-update-timer :override (lambda (&rest _) nil))
    (defun git-gutter:live-update () "Disabled live update callback." nil)
    (when (boundp 'git-gutter:update-timer)
      (ignore-errors (cancel-timer git-gutter:update-timer))))
  ;; If any timer started before, cancel it explicitly
  (when (fboundp 'git-gutter:cancel-update-timer)
    (ignore-errors (git-gutter:cancel-update-timer)))
  ;; Use simple, visible signs; color by face
  (setq git-gutter:added-sign "|"
        git-gutter:modified-sign "|"
        git-gutter:deleted-sign "|"
        git-gutter:ask-p nil
        git-gutter:verbosity 0
        git-gutter:update-interval 0.5)
  (set-face-foreground 'git-gutter:added   "#2ea043")
  (set-face-foreground 'git-gutter:modified "#388bfd")
  (set-face-foreground 'git-gutter:deleted  "#f85149")
  ;; Windows: ensure a usable diff executable if anything falls back to it
  (when (eq system-type 'windows-nt)
    (let ((git-diff "C:/Program Files/Git/usr/bin/diff.exe"))
      (when (file-executable-p git-diff)
        (setq diff-command git-diff))))
  ;; Silence temp-file write-region spam during gutter updates
  (defun my--silence-messages-around (fn &rest args)
    (let ((inhibit-message t)
          (message-log-max nil))
      (apply fn args)))
  ;; NOTE: This suppresses messages emitted during background updates.
  ;; Disable these advices if you need to debug gutter issues.
  (dolist (f '(git-gutter:update-all-windows
               git-gutter:update-buffer
               git-gutter:update-current-buffer
               git-gutter))
    (advice-add f :around #'my--silence-messages-around))

  ;; Helper: enable git-gutter only in Git repos
  (defun my--buffer-in-git-repo-p ()
    (and buffer-file-name
         (or (and (fboundp 'vc-backend) (eq (vc-backend buffer-file-name) 'Git))
             (locate-dominating-file default-directory ".git"))))
  (defun my--git-gutter-maybe-enable ()
    (when buffer-file-name
      (if (my--buffer-in-git-repo-p)
          (progn (git-gutter-mode 1) (ignore-errors (git-gutter)))
        (when (bound-and-true-p git-gutter-mode)
          (git-gutter-mode -1)))))
  ;; Update strategy without timer: on find-file, save, and revert
  (add-hook 'find-file-hook #'my--git-gutter-maybe-enable)
  (add-hook 'after-save-hook (lambda () (when (bound-and-true-p git-gutter-mode) (git-gutter))))
  (add-hook 'after-revert-hook (lambda () (when (bound-and-true-p git-gutter-mode) (git-gutter))))
  ;; Helpful diagnostics
  (defun my-git-gutter-diagnose ()
    (interactive)
    (message "git-gutter: on=%s, vc=%s, signs=(%s %s %s)"
             (bound-and-true-p git-gutter-mode)
             (and buffer-file-name (vc-backend buffer-file-name))
             git-gutter:added-sign git-gutter:modified-sign git-gutter:deleted-sign))
  (add-hook 'find-file-hook (lambda ()
                              (when buffer-file-name
                                (when (fboundp 'git-gutter)
                                  (git-gutter-mode 1)
                                  (git-gutter)))))
  ;; No startup message; keep quiet
  )

;; Reapply diff-hl faces after theme changes so colors don't get reset
  (defun my-diff-hl-apply-faces ()
    (interactive)
    (ignore-errors
    (set-face-attribute 'diff-hl-insert nil :inherit nil :foreground "#2ea043")
    (set-face-attribute 'diff-hl-change nil :inherit nil :foreground "#388bfd")
    (set-face-attribute 'diff-hl-delete nil :inherit nil :foreground "#f85149")
    (set-face-attribute 'diff-hl-margin-insert nil :foreground "#2ea043" :weight 'bold)
    (set-face-attribute 'diff-hl-margin-change nil :foreground "#388bfd" :weight 'bold)
    (set-face-attribute 'diff-hl-margin-delete nil :foreground "#f85149" :weight 'bold)
    (set-face-attribute 'diff-hl-fringe-insert nil :inherit nil :foreground "#2ea043" :background "#2ea043")
    (set-face-attribute 'diff-hl-fringe-change nil :inherit nil :foreground "#388bfd" :background "#388bfd")
    (set-face-attribute 'diff-hl-fringe-delete nil :inherit nil :foreground "#f85149" :background "#f85149"))
    (when (featurep 'diff-hl)
      (diff-hl-update))
    )

(when (boundp 'after-load-theme-hook)
  (add-hook 'after-load-theme-hook #'my-diff-hl-apply-faces))
(advice-add 'load-theme :after (lambda (&rest _) (my-diff-hl-apply-faces)))
;; Apply faces once after init too, and log
(add-hook 'after-init-hook (lambda ()
                             (my-diff-hl-apply-faces)
                             (when (and (featurep 'diff-hl) (bound-and-true-p my-diff-hl-debug))
                               (my-diff-hl-diagnose "after-init"))))

;; Proactively refresh indicators on save and focus
(with-eval-after-load 'diff-hl
  (add-hook 'after-save-hook #'diff-hl-update)
  (add-hook 'after-revert-hook #'diff-hl-update)
  (add-hook 'focus-in-hook #'diff-hl-update))

;; Ensure the right margin exists so indicators are visible even when
;; other packages resize margins. Keeps left margin untouched (line numbers).
(defvar my-diff-hl-margin-width 3
  "Minimum width to reserve for diff-hl in the selected margin.")
(defun my--ensure-margin-for-diff-hl (&rest _)
  (when (bound-and-true-p diff-hl-margin-mode)
    (walk-windows
     (lambda (w)
       (with-selected-window w
         (let* ((m (window-margins w))
                (lm (or (car m) 0))
                (rm (or (cdr m) 0)))
           (pcase diff-hl-margin-side
             ('left  (when (< lm my-diff-hl-margin-width)
                       (set-window-margins w my-diff-hl-margin-width rm)))
             ('right (when (< rm my-diff-hl-margin-width)
                       (set-window-margins w lm my-diff-hl-margin-width)))))))
     nil t)))
(add-hook 'window-configuration-change-hook #'my--ensure-margin-for-diff-hl)
(add-hook 'buffer-list-update-hook #'my--ensure-margin-for-diff-hl)

;; Keybindings: file dialogs, save, zoom
(global-set-key (kbd "C-o") 'menu-find-file-existing)
(defun my--find-file-read-args-dialog (orig-fun &rest args)
  (let ((last-nonmenu-event nil)) (apply orig-fun args)))
(advice-add 'find-file-read-args :around #'my--find-file-read-args-dialog)
(global-set-key (kbd "C-s") 'save-buffer)
(defun my--write-file-dialog (orig-fun &rest args)
  (let ((last-nonmenu-event nil)) (apply orig-fun args)))
(advice-add 'write-file :around #'my--write-file-dialog)
(global-set-key (kbd "<C-mouse-4>") 'text-scale-increase)
(global-set-key (kbd "<C-mouse-5>") 'text-scale-decrease)
(global-set-key (kbd "C-+") 'text-scale-increase)
(global-set-key (kbd "C--") 'text-scale-decrease)
;; Use built-in whole-buffer selection for C-a
(global-set-key (kbd "C-a") 'mark-whole-buffer)
;; Keep Shift+mouse selection behavior native
(define-key global-map (kbd "<S-down-mouse-1>") nil)
(cua-mode 1)
(setq cua-keep-region-after-copy t)
(global-set-key (kbd "<M-f4>") 'save-buffers-kill-terminal)
(global-set-key (kbd "C-S-w")
                (lambda ()
                  (interactive)
                  (cond
                   ;; In minibuffer/helm, keep editing semantics
                   ((or (minibufferp (current-buffer))
                        (bound-and-true-p helm-major-mode))
                    (call-interactively 'backward-kill-word))
                   ;; If there is another window in this frame, close just this split
                   ((> (length (window-list)) 1)
                    (delete-window))
                   ;; Otherwise, don't nuke the frame; just close the buffer
                   (t (kill-this-buffer)))))
(defun indent-region-custom (numSpaces)
  (setq regionStart (line-beginning-position))
  (setq regionEnd (line-end-position))
  (when (use-region-p)
    (setq regionStart (region-beginning))
    (setq regionEnd (region-end)))
  (save-excursion
    (goto-char regionStart)
    (setq start (line-beginning-position))
    (goto-char regionEnd)
    (setq end (line-end-position))
    (indent-rigidly start end numSpaces)
    (setq deactivate-mark nil)))
(defun untab-region (N) (interactive "p") (indent-region-custom -4))
(defun tab-region (N)
  (interactive "p")
  (if (active-minibuffer-window)
      (minibuffer-complete)
    (if (string= (buffer-name) "*shell*")
        (comint-dynamic-complete)
      (if (use-region-p)
          (indent-region-custom 4)
        (insert "    ")))))
(global-set-key (kbd "<backtab>") 'untab-region)
(global-set-key (kbd "<tab>") 'tab-region)
(global-set-key [M-left] 'windmove-left)
(global-set-key [M-right] 'windmove-right)
(global-set-key [M-up] 'windmove-up)
(global-set-key [M-down] 'windmove-down)
(defun my-syntax-class (char)
  (pcase (char-syntax char)
    (`?\s ?s) (`?w ?w) (`?_ ?w) (_ ?p)))
(defun my-forward-word (&optional arg)
  (interactive "^p")
  (or arg (setq arg 1))
  (let* ((backward (< arg 0)) (count (abs arg))
         (char-next (if backward 'char-before 'char-after))
         (skip-syntax (if backward 'skip-syntax-backward 'skip-syntax-forward))
         (skip-char (if backward 'backward-char 'forward-char))
         prev-char next-char)
    (while (> count 0)
      (setq next-char (funcall char-next))
      (cl-loop
       (if (or (eql next-char ?\n) (eql (char-syntax next-char) ?\s))
           (funcall skip-char)
         (funcall skip-syntax (char-to-string (char-syntax next-char))))
       (setq prev-char next-char)
       (setq next-char (funcall char-next))
       (when (or (eql prev-char ?\n)
                 (eql next-char ?\n)
                 (and (eql (my-syntax-class prev-char) ?w) (eql (my-syntax-class next-char) ?p))
                 (and this-command-keys-shift-translated (eql (my-syntax-class prev-char) ?w) (eql (my-syntax-class next-char) ?s))
                 (and (not backward) (not this-command-keys-shift-translated) (eql (my-syntax-class prev-char) ?s) (not (eql (my-syntax-class next-char) ?s)))
                 (and backward (not this-command-keys-shift-translated) (not (eql (my-syntax-class prev-char) ?s)) (eql (my-syntax-class next-char) ?s)))
         (cl-return)))
      (setq count (1- count)))))
(defun delete-word (&optional arg) (interactive "p") (delete-region (point) (progn (my-forward-word arg) (point))))
(defun backward-delete-word (arg) (interactive "p") (delete-word (- arg)))
(defun my-backward-word (&optional arg) (interactive "^p") (or arg (setq arg 1)) (my-forward-word (- arg)))
(global-set-key (kbd "C-<left>") 'my-backward-word)
(global-set-key (kbd "C-<right>") 'my-forward-word)
(global-set-key (kbd "C-<delete>") 'delete-word)
(global-set-key (kbd "C-<backspace>") 'backward-delete-word)
;; helm-swoop: inline search, bound to C-f
(use-package helm-swoop :ensure t :bind (("C-f" . helm-swoop)))
(with-eval-after-load 'helm-swoop
  (define-key helm-swoop-map (kbd "C-g") 'helm-maybe-exit-minibuffer)
  ;; Enter should just close and keep point where it was
  (define-key helm-swoop-map (kbd "RET") 'helm-keyboard-quit))
(setq helm-move-to-line-cycle-in-source t)

;; Tabs per pane (Notepad++-like) using tab-line
;; Shows buffer tabs in each window; Ctrl-Tab cycles within the pane.
(global-tab-line-mode 1)
;; Filter tabs to "real" buffers (no star buffers) and keep a stable order
(defun my-tab--filtered-window-buffers ()
  (let ((bufs (tab-line-tabs-window-buffers)))
    (cl-remove-if (lambda (b)
                    (let ((n (buffer-name b)))
                      (or (null n) (string-prefix-p "*" n))))
                  bufs)))

(defun my-tab--get-ordered-list ()
  "Return window-local ordered buffer list for tab-line, keeping order stable."
  (let* ((win (selected-window))
         (ordered (window-parameter win 'my-tab-ordered))
         (filtered (my-tab--filtered-window-buffers)))
    ;; Initialize on first use
    (unless ordered
      (setq ordered (copy-sequence filtered)))
    ;; Remove dead or no longer filtered buffers
    (setq ordered (cl-remove-if (lambda (b) (or (not (buffer-live-p b)) (not (memq b filtered)))) ordered))
    ;; Append any new filtered buffers at the end
    (dolist (b filtered)
      (unless (memq b ordered)
        (setq ordered (append ordered (list b)))))
    ;; Ensure current buffer is present
    (unless (memq (current-buffer) ordered)
      (setq ordered (append ordered (list (current-buffer)))))
    (set-window-parameter win 'my-tab-ordered ordered)
    ordered))

(defun my-tab-line-tabs-ordered ()
  (my-tab--get-ordered-list))

(setq tab-line-tabs-function #'my-tab-line-tabs-ordered)
;; Slightly wider tabs by padding names and adding a wider separator
(defun my-tab-line-tab-name-buffer (buffer &optional _buffers)
  (concat " " (buffer-name buffer) " "))
(setq tab-line-tab-name-function #'my-tab-line-tab-name-buffer)
(setq tab-line-separator "  ")
;; Make tab line visually taller and clearer
(set-face-attribute 'tab-line nil :height 100 :background "white" :foreground "#666666")
(set-face-attribute 'tab-line-tab-current nil :foreground "black" :background "#f0f0f0" :weight 'regular)
(set-face-attribute 'tab-line-tab-inactive nil :foreground "#aaaaaa" :background "white" :weight 'light)
;; Custom wrap-around tab cycling to avoid odd edge behavior
(defun my-tab-line--buffers ()
  (my-tab--get-ordered-list))
(defun my-tab-line-next ()
  (interactive)
  (let* ((buffers (my-tab-line--buffers))
         (len (length buffers)))
    (when (> len 1)
      (let* ((cur (current-buffer))
             (idx (or (cl-position cur buffers) 0))
             (next (nth (mod (1+ idx) len) buffers)))
        (set-window-buffer (selected-window) next)
        ;; Keep order stable; no rotation needed
        (my-tab--get-ordered-list)))))
(defun my-tab-line-prev ()
  (interactive)
  (let* ((buffers (my-tab-line--buffers))
         (len (length buffers)))
    (when (> len 1)
      (let* ((cur (current-buffer))
             (idx (or (cl-position cur buffers) 0))
             (prev (nth (mod (1- idx) len) buffers)))
        (set-window-buffer (selected-window) prev)
        (my-tab--get-ordered-list)))))
;; Bind Ctrl-Tab in multiple forms for compatibility
(global-set-key [(control tab)] 'my-tab-line-next)
(global-set-key (kbd "<C-tab>") 'my-tab-line-next)
(global-set-key [(control shift tab)] 'my-tab-line-prev)
(global-set-key (kbd "<C-S-tab>") 'my-tab-line-prev)
(global-set-key (kbd "<C-S-iso-lefttab>") 'my-tab-line-prev)
;; Also match Chrome/Notepad++ Ctrl-PageDown/Up
(global-set-key (kbd "<C-next>") 'my-tab-line-next)     ;; PageDown
(global-set-key (kbd "<C-prior>") 'my-tab-line-prev)    ;; PageUp

;; Close current tab (buffer) only — but be polite in minibuffer/helm
(defun my-close-buffer-smart ()
  (interactive)
  (cond
   ;; In minibuffer or prompts, keep editing behavior (delete word)
   ((minibufferp (current-buffer))
    (call-interactively 'backward-kill-word))
   ;; In Helm/completion UIs, don't kill buffers; treat as word delete
   ((or (bound-and-true-p helm-major-mode)
        (string-match-p "^\*Completions\*$" (buffer-name (current-buffer))))
    (call-interactively 'backward-kill-word))
   (t
    (kill-this-buffer))))
(global-set-key (kbd "C-w") 'my-close-buffer-smart)

;; New empty buffer as a new tab in the current pane
(defun xah-new-empty-buffer ()
  (interactive)
  (let (($buf (generate-new-buffer "untitled")))
    (switch-to-buffer $buf)
    (funcall initial-major-mode)
    (setq buffer-offer-save t)
    $buf))
(global-set-key (kbd "C-n") 'xah-new-empty-buffer)
(defvar killed-file-list nil "List of recently killed files.")
(defun add-file-to-killed-file-list () (when buffer-file-name (push buffer-file-name killed-file-list)))
(add-hook 'kill-buffer-hook #'add-file-to-killed-file-list)
(defun reopen-killed-file () (interactive) (when killed-file-list (find-file (pop killed-file-list))))
(global-set-key (kbd "C-S-t") 'reopen-killed-file)
;; No special tab-bar open behavior; use pane-local tabs now

;; Org tweaks (from _6org.el)
(setq org-support-shift-select t)
(defun my--org-shift-select-cua (&rest _args)
  (ignore _args)
  (when (and cua-mode org-support-shift-select (not (use-region-p)))
    (cua-set-mark)))
(advice-add 'org-call-for-shift-select :before #'my--org-shift-select-cua)
(with-eval-after-load 'org (define-key org-mode-map (kbd "<C-tab>") nil))


;; Custom UI writes go to var/custom.el (see custom-file above)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Git helpers: quick diff, commit, push (simple)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Resolve repository root for current buffer/default-directory
(defun my-git--repo-root ()
  (or (and (fboundp 'magit-toplevel) (ignore-errors (magit-toplevel)))
      (and (fboundp 'vc-root-dir) (vc-root-dir))
      (locate-dominating-file default-directory ".git")
      default-directory))

(defun my-git-status ()
  "Open Git status for the current repo (Magit if available, else vc-dir)."
  (let ((root (my-git--repo-root)))
    (cond
     ((and (fboundp 'magit-status) root)
      (magit-status root))
     (root (vc-dir root))
     (t (user-error "Not in a Git repo")))))

(defun my-git-diff ()
  "Show working tree diff (Magit if available, else vc-diff)."
  (if (and (fboundp 'magit-diff-working-tree) (my-git--repo-root))
      (magit-diff-working-tree)
    (vc-diff)))

(defun my-git--call-sync (root &rest args)
  "Run git ARGS in ROOT, returning (exit-code . output)."
  (let ((default-directory root))
    (with-temp-buffer
      (let ((code (apply #'process-file "git" nil t nil args))
            (out (buffer-string)))
        (cons code out)))))

(defun my-git--changes-p (root)
  "Return non-nil if there are staged/unstaged changes."
  (let* ((res (my-git--call-sync root "status" "--porcelain"))
         (out (cdr res)))
    (and out (> (length (string-trim out)) 0))))

;; Refresh VC state and header line for all buffers in ROOT
(defun my-git--refresh-all-buffers (root)
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (and buffer-file-name
                 (ignore-errors (string-prefix-p (file-truename root)
                                                 (file-truename buffer-file-name))))
        (when (fboundp 'vc-file-clearprops) (vc-file-clearprops buffer-file-name))
        (when (fboundp 'vc-refresh-state) (ignore-errors (vc-refresh-state)))
        (force-mode-line-update t)))))

(defun my-git-commit-all (msg)
  "Commit all changes in repo with message MSG."
  (let ((root (my-git--repo-root)))
    (unless root (user-error "Not in a Git repo"))
    (save-some-buffers t)
    (when (my-git--changes-p root)
      (my-git--call-sync root "add" "-A"))
    (let* ((res (my-git--call-sync root "commit" "-m" msg))
           (code (car res)) (out (cdr res)))
      (if (= code 0)
          (progn
            (my-git--refresh-all-buffers root)
            (message "Committed: %s" msg))
        (if (string-match-p "nothing to commit" out)
            (progn
              (my-git--refresh-all-buffers root)
              (message "Nothing to commit"))
          (user-error "git commit failed: %s" (string-trim out)))))))

(defun my-git-push ()
  "Push current branch to its upstream."
  (let ((root (my-git--repo-root)))
    (unless root (user-error "Not in a Git repo"))
    (let* ((res (my-git--call-sync root "push"))
           (code (car res)) (out (cdr res)))
      (if (= code 0)
          (progn
            (my-git--refresh-all-buffers root)
            (message "Pushed successfully"))
        (user-error "git push failed: %s" (string-trim out))))))

(defun my-git-review-commit-push ()
  "Review diff, then commit all and push if confirmed."
  (interactive)
  (let ((root (my-git--repo-root)))
    (unless root (user-error "Not in a Git repo"))
    ;; Show diff for review
    (my-git-diff)
    (when (y-or-n-p "Commit and push these changes? ")
      (let ((msg (read-string "Commit message: ")))
        (my-git-commit-all msg)
        (my-git-push)))))

;; Also refresh VC/cache when Emacs regains focus (external tools might change repo)
(defun my-git--refresh-on-focus-in ()
  (let ((root (ignore-errors (my-git--repo-root))))
    (when root (my-git--refresh-all-buffers root))))
(add-hook 'focus-in-hook #'my-git--refresh-on-focus-in)

;; Simple alias for easy M-x access
(defalias 'git-review-commit-push 'my-git-review-commit-push)







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Side-by-side diff (VSCode-like in one go)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Clean, single-purpose diff against Git HEAD
(defun my--git-head-buffer-for-current (&optional rev)
  "Return a read-only buffer with current file at Git REV (default HEAD)."
  (unless buffer-file-name
    (user-error "Not visiting a file"))
  (let* ((root (ignore-errors (my-git--repo-root)))
         (revision (or rev "HEAD")))
    (unless (and root (file-directory-p (expand-file-name ".git" root)))
      (user-error "Not in a Git repository"))
    (unless (executable-find "git")
      (user-error "git is not available on PATH"))
    (let* ((mm-left major-mode)
           (rel (file-relative-name (file-truename buffer-file-name)
                                    (file-truename root)))
           (buf (generate-new-buffer
                 (format "%s <%s>"
                         (file-name-nondirectory buffer-file-name) revision)))
           (default-directory root)
           (status (process-file "git" nil buf nil "show"
                                 (format "%s:%s" revision rel))))
      (when (not (zerop status))
        (kill-buffer buf)
        (user-error "git show failed for %s:%s" revision rel))
      (with-current-buffer buf
        (setq buffer-read-only t)
        (setq-local truncate-lines t)
        (when (functionp mm-left)
          (funcall mm-left)))
      buf)))

(defun my--ediff-apply-vscode-like-faces ()
  "Set Ediff faces to VSCode-like green/red highlights for light theme."
  ;; Ensure Ediff faces exist before styling them
  (require 'ediff nil t)
  (dolist (spec '((ediff-current-diff-A . (:background "#e6ffed" :foreground "#000000"))
                  (ediff-current-diff-B . (:background "#ffebe9" :foreground "#000000"))
                  (ediff-fine-diff-A    . (:background "#bbf7c1" :foreground "#000000"))
                  (ediff-fine-diff-B    . (:background "#ffb8b0" :foreground "#000000"))
                  (ediff-even-diff-A    . (:background "#f6fff8"))
                  (ediff-even-diff-B    . (:background "#fff7f6"))
                  (ediff-odd-diff-A     . (:background "#f6fff8"))
                  (ediff-odd-diff-B     . (:background "#fff7f6"))))
    (let ((face (car spec))
          (attrs (cdr spec)))
      (when (facep face)
        (apply #'set-face-attribute face nil (flatten-list attrs))))))

(defun my--ediff-cleanup-scroll-sync ()
  (when (bound-and-true-p scroll-all-mode)
    (scroll-all-mode -1)))

(defun my-diff-against-git-head ()
  "Compare the current buffer with its Git HEAD using Ediff side-by-side.

No prompts. Opens a single-frame, horizontal split with auto-refined
intra-line highlights and synchronized scrolling."
  (interactive)
  (let* ((head-buf (my--git-head-buffer-for-current "HEAD"))
         (ediff-window-setup-function 'ediff-setup-windows-plain)
         (ediff-split-window-function 'split-window-horizontally)
         (ediff-auto-refine t))
    (require 'ediff nil t)
    (my--ediff-apply-vscode-like-faces)
    ;; Sync scrolling across windows during the session
    (scroll-all-mode 1)
    (add-hook 'ediff-after-quit-hook-internal #'my--ediff-cleanup-scroll-sync)
    (ediff-buffers (current-buffer) head-buf)))

;; Ensure Ediff has a diff program on Windows
(when (eq system-type 'windows-nt)
  (let ((git-diff "C:/Program Files/Git/usr/bin/diff.exe"))
    (when (file-executable-p git-diff)
      (setq ediff-diff-program git-diff))))
