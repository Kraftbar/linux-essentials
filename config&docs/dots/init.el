
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
;; Keep Org lazy at startup; the variables below can be set before Org loads.



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
      
	

(defun my-apply-graphical-frame-settings (&optional frame)
  "Apply GUI-only appearance settings to FRAME."
  (when (display-graphic-p frame)
    (with-selected-frame (or frame (selected-frame))
      (cond
       ((eq system-type 'windows-nt)
        (ignore-errors (set-frame-font "Lucida Console 10" nil t)))
       ((eq system-type 'gnu/linux)
        (ignore-errors (set-frame-font "Noto Mono Light 10" nil t))))
      (set-frame-parameter nil 'internal-border-width 20)
      (fringe-mode '(0 . 0))
      (setq frame-background-mode 'light)
      (set-background-color "#ffffff")
      (set-foreground-color "#666666")
      (set-face-attribute 'fringe nil :background "#ffffff" :foreground "#666666")
      (when (fboundp 'tool-bar-mode)
        (tool-bar-mode 0))
      (when (fboundp 'tooltip-mode)
        (tooltip-mode 0))
      (when (fboundp 'set-scroll-bar-mode)
        (set-scroll-bar-mode 'right))
      (when (fboundp 'scroll-bar-mode)
        (scroll-bar-mode 1)))))

(my-apply-graphical-frame-settings)
(add-hook 'after-make-frame-functions #'my-apply-graphical-frame-settings)

(setq x-underline-at-descent-line t)
(setq initial-major-mode 'text-mode)
(setq-default line-spacing 0)
(set-default 'cursor-type  '(hbar . 2))
(blink-cursor-mode 1)
;; Hide fringes; we rely on margin indicators for diff-hl
(when (display-graphic-p)
  (fringe-mode '(0 . 0)))

(setq inhibit-startup-screen t)
(setq inhibit-startup-echo-area-message t)
(setq inhibit-startup-message t)   ;; Show/hide startup page
(setq initial-scratch-message nil) ;; Show/hide *scratch* buffer message
;; (menu-bar-mode 0)                  ;; Show/hide menubar



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
(defun my-apply-org-faces ()
  (set-face-attribute 'org-level-1 nil
		      :foreground "black"
		      :weight 'regular)
  (set-face-attribute 'org-link nil
		      :underline nil
		      :foreground "dark blue")
  (set-face-attribute 'org-verbatim nil
		      :foreground "dark blue"))
(when (featurep 'org)
  (my-apply-org-faces))
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
(require 'subr-x)
(defun my-ensure-private-dir (dir)
  "Create DIR if needed and keep it private for Emacs runtime files."
  (unless (file-directory-p dir)
    (make-directory dir t))
  ;; Native Windows filesystems do not always honor Unix mode bits cleanly.
  (ignore-errors (set-file-modes dir #o700))
  dir)

(setq make-backup-files nil)
(setq auto-save-default nil)
(setq mouse-wheel-scroll-amount '(6 ((shift) . 1) ((control) . nil)))
(setq mouse-wheel-progressive-speed nil)
(setq scroll-step 1)
(setq scroll-preserve-screen-position t
      scroll-error-top-bottom t)
(global-set-key [escape] 'keyboard-escape-quit)

;; Centralize runtime files under var/
(defconst user-var-dir (expand-file-name "var/" user-emacs-directory))
(my-ensure-private-dir user-var-dir)
(setq recentf-save-file (expand-file-name "recentf" user-var-dir))
(setq save-place-file (expand-file-name "places" user-var-dir))
;; Auto-save list directory
(let ((asdir (expand-file-name "auto-save-list" user-var-dir)))
  (my-ensure-private-dir asdir)
  (setq auto-save-list-file-prefix (concat asdir "/saves-")))
;; Server socket dir
(let ((server-dir (expand-file-name "server" user-var-dir)))
  (setq server-socket-dir server-dir)
  (my-ensure-private-dir server-dir))
;; Keep Custom UI writes out of init.el
(setq custom-file (expand-file-name "custom.el" user-var-dir))
(when (file-exists-p custom-file) (load custom-file))
(load "server")
(unless (or noninteractive (server-running-p))
  (condition-case err
      (server-start)
    (error
     (message "Skipping server start: %s" (error-message-string err)))))
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

(defun my-bootstrap-packages ()
  "Refresh package metadata and install any startup dependencies that are missing."
  (interactive)
  (package-refresh-contents)
  (unless (package-installed-p 'use-package)
    (package-install 'use-package))
  (when (and (not (package-installed-p 'helm-swoop))
             (fboundp 'package-vc-install))
    (package-vc-install "https://github.com/emacsorphanage/helm-swoop"))
  (when (and (boundp 'package-quickstart) package-quickstart
             (fboundp 'package-quickstart-refresh))
    (ignore-errors (package-quickstart-refresh))))

(unless (package-installed-p 'use-package)
  ;; Keep startup fast in the common case; only hit the network once when bootstrapping.
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(when (and (not (package-installed-p 'helm-swoop))
           (fboundp 'package-vc-install))
  ;; helm-swoop is sourced from Git when missing; avoid repeated archive refreshes.
  (ignore-errors (package-vc-install "https://github.com/emacsorphanage/helm-swoop")))
(when (and (boundp 'package-quickstart) package-quickstart
           (fboundp 'package-quickstart-refresh))
  (let ((qs-file (expand-file-name "package-quickstart.el" user-emacs-directory)))
    (unless (file-exists-p qs-file)
      (ignore-errors (package-quickstart-refresh)))))
;; which-key: show possible key continuations
(use-package which-key
  :ensure t
  :defer 1
  :config (which-key-mode))
;; command-log-mode: log commands (handy for demos/debug)
(use-package command-log-mode
  :ensure t
  :commands (command-log-mode global-command-log-mode clm/open-command-log-buffer))
(defun xah-start-command-log ()
  (interactive)
  (command-log-mode)
  (global-command-log-mode)
  (clm/open-command-log-buffer)
  (delete-window))
;; helm: completion and narrowing UI
(use-package helm
  :ensure t
  :defer 1
  :init (setq helm-candidate-number-limit 100
              helm-ff-skip-boring-files t)
  :config (helm-mode 1)
  :bind (("M-x" . helm-M-x)
         ("C-x f" . helm-for-files)
         ("C-r" . helm-recentf)))
;; undo-tree: linear+tree undo with persistent history
(use-package undo-tree
  :ensure t
  :defer 1
  :diminish undo-tree-mode
  :init
  (let ((dir (expand-file-name "var/undo-tree-history" user-emacs-directory)))
    (setq undo-tree-history-directory-alist `(("." . ,dir)))
    (setq undo-tree-auto-save-history t)
    (unless (file-directory-p dir) (make-directory dir t)))
  :config
  (global-undo-tree-mode 1)
  (defalias 'redo 'undo-tree-redo)
  :bind (("C-z" . undo) ("C-S-z" . redo)))
;; popwin: tame special buffers into popups
(use-package popwin
  :ensure t
  :defer 1
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
;; - git-gutter is the ONLY auto-enabled gutter. diff-hl stays installed and
;;   configured but is opt-in: run `my-diff-hl-use-margin` or
;;   `my-diff-hl-use-fringe` to try it in a buffer. Previously both gutters
;;   auto-enabled on find-file, giving double indicators (left | and right ||).
;; - Toggle `my-diff-hl-debug` to `t` to log state.
;; - LF/CRLF prompts are unrelated to the gutter and can be tuned later.
;; Shows green for added lines, blue for modified, red for deleted
(use-package diff-hl
  :ensure t
  :defer 1
  :config
  ;; Ensure flydiff is active whenever diff-hl-mode is enabled
  (add-hook 'diff-hl-mode-hook #'diff-hl-flydiff-mode)
  ;; Prefer margins for reliability across ports; use RIGHT margin to avoid line-number collisions
  (setq diff-hl-margin-side 'right)
  ;; Use visible ASCII glyphs (not spaces) so color shows reliably in margins
  (setq diff-hl-margin-symbols-alist
        '((insert . "||") (change . "||") (delete . "||") (unknown . "?") (ignored . " ")))
  ;; Margin mode is enabled on demand by `my-diff-hl-use-margin' (git-gutter is
  ;; the primary gutter; enabling this globally reserved a right margin in
  ;; every window and doubled the indicators).
  ;; Make fringe rendering (if used) cleaner and remove gray borders
  (setq diff-hl-fringe-bmp-function 'diff-hl-fringe-bmp-from-type)
  (setq diff-hl-draw-borders nil)
  ;; Allow diff-hl on TRAMP/remote files (use at your own risk performance-wise)
  (setq diff-hl-disable-on-remote nil)
  ;; Make sure VC recognizes Git; some setups clear this variable
  (when (boundp 'vc-handled-backends)
    (unless (memq 'Git vc-handled-backends)
      (push 'Git vc-handled-backends)))
  ;; No find-file auto-enable: git-gutter owns the gutter by default.
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
    ;; Keep RIGHT side: left margin would collide with git-gutter/line numbers
    (setq diff-hl-margin-side 'right)
    (diff-hl-margin-mode 1)
    (diff-hl-mode 1)
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
  :defer 1
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
  (when buffer-file-name
    (my--git-gutter-maybe-enable))
  ;; Helpful diagnostics
  (defun my-git-gutter-diagnose ()
    (interactive)
    (message "git-gutter: on=%s, vc=%s, signs=(%s %s %s)"
             (bound-and-true-p git-gutter-mode)
             (and buffer-file-name (vc-backend buffer-file-name))
             git-gutter:added-sign git-gutter:modified-sign git-gutter:deleted-sign))
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

;; Proactively refresh indicators on save and focus (only where diff-hl is on)
(defun my--diff-hl-update-if-enabled ()
  (when (bound-and-true-p diff-hl-mode)
    (diff-hl-update)))
(with-eval-after-load 'diff-hl
  (add-hook 'after-save-hook #'my--diff-hl-update-if-enabled)
  (add-hook 'after-revert-hook #'my--diff-hl-update-if-enabled)
  (add-hook 'focus-in-hook #'my--diff-hl-update-if-enabled))

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Minimap (VSCode-like code overview, with edit marks)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; - Right-hand miniature of the buffer; toggle with C-c m (or M-x minimap-mode).
;;   OFF by default — see the edit overview ruler below for whole-file marks.
;; - Changed lines (from git-gutter's hunk data) are tinted in the minimap:
;;   green = added, blue = modified, red = hunks with deletions. The minimap is
;;   an indirect buffer, so gutter margins/overlays don't carry over — we mirror
;;   the hunks as our own overlays inside the minimap buffer.
(use-package minimap
  :ensure t
  :defer 1
  :init
  (setq minimap-window-location 'right
        minimap-width-fraction 0.10
        minimap-minimum-width 14
        minimap-update-delay 0.3
        minimap-hide-fringes t
        minimap-major-modes '(prog-mode text-mode conf-mode))
  :config
  (ignore-errors
    (set-face-attribute 'minimap-active-region-background nil
                        :background "#f0f0f0"))
  (defvar-local my-minimap--last-hunks 'unset
    "Hunk list last rendered in the minimap buffer, to skip redundant refreshes.")
  (defun my-minimap--edit-face (type)
    (pcase type
      ('added   '(:background "#c6f0cd" :extend t))
      ('deleted '(:background "#ffd0cc" :extend t))
      (_        '(:background "#cfe3ff" :extend t))))
  (defun my-minimap-refresh-edit-marks (&rest _)
    "Tint lines changed per git-gutter inside the minimap buffer."
    (when (and (boundp 'minimap-buffer-name)
               (fboundp 'git-gutter-hunk-start-line))
      (let ((mmbuf (get-buffer minimap-buffer-name)))
        (when (buffer-live-p mmbuf)
          (let* ((base (buffer-base-buffer mmbuf))
                 (hunks (and base (buffer-local-value 'git-gutter:diffinfos base))))
            (with-current-buffer mmbuf
              (unless (equal hunks my-minimap--last-hunks)
                (setq my-minimap--last-hunks hunks)
                (remove-overlays (point-min) (point-max) 'my-minimap-edit t)
                (save-excursion
                  (dolist (h hunks)
                    (let* ((sl (git-gutter-hunk-start-line h))
                           (el (max sl (or (git-gutter-hunk-end-line h) sl)))
                           (beg (progn (goto-char (point-min))
                                       (forward-line (1- sl))
                                       (point)))
                           (end (progn (goto-char (point-min))
                                       (forward-line el)
                                       (point)))
                           (ov (make-overlay beg end)))
                      (overlay-put ov 'my-minimap-edit t)
                      (overlay-put ov 'priority 100)
                      (overlay-put ov 'face
                                   (my-minimap--edit-face (git-gutter-hunk-type h)))))))))))))
  (advice-add 'minimap-update :after #'my-minimap-refresh-edit-marks)
  (add-hook 'after-save-hook #'my-minimap-refresh-edit-marks)
  (add-hook 'after-revert-hook #'my-minimap-refresh-edit-marks))
;; Minimap is OFF by default (it scrolls with long files, so far-away edits
;; vanish from it — the edit ruler below solves that). Toggle with C-c m.
(global-set-key (kbd "C-c m") 'minimap-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Edit overview ruler (VSCode scrollbar-marks style)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Colored marks in the RIGHT margin showing where your edits are in the WHOLE
;; file, scaled like VSCode's overview ruler — visible no matter where you are
;; scrolled. Data comes from git-gutter's hunks (updates on save/revert/open).
;; C-c n / C-c p jump to the next/previous edited hunk.
(defvar my-edit-ruler-width 1
  "Right-margin columns reserved for the edit overview ruler.")
(defface my-edit-ruler-added    '((t :foreground "#2ea043")) "Ruler mark for added lines.")
(defface my-edit-ruler-modified '((t :foreground "#388bfd")) "Ruler mark for modified lines.")
(defface my-edit-ruler-deleted  '((t :foreground "#f85149")) "Ruler mark for deleted lines.")

(defun my-edit-ruler--face (type)
  (pcase type
    ('added 'my-edit-ruler-added)
    ('deleted 'my-edit-ruler-deleted)
    (_ 'my-edit-ruler-modified)))

(defun my-edit-ruler--clear-window (win buf)
  (with-current-buffer buf
    (dolist (ov (overlays-in (point-min) (point-max)))
      (when (and (overlay-get ov 'my-edit-ruler)
                 (eq (overlay-get ov 'window) win))
        (delete-overlay ov)))))

(defun my-edit-ruler-refresh-window (win &optional start)
  "Redraw whole-file edit marks in WIN's right margin.
START overrides `window-start' — required when called from
`window-scroll-functions', where `window-start' is not yet updated."
  (when (and (window-live-p win)
             (fboundp 'git-gutter-hunk-start-line))
    (let ((buf (window-buffer win)))
      (when (buffer-local-value 'git-gutter-mode buf)
        (my-edit-ruler--clear-window win buf)
        (with-current-buffer buf
          (let ((hunks (bound-and-true-p git-gutter:diffinfos)))
            (when hunks
              ;; Reserve a slim right margin in this window
              (let ((m (window-margins win)))
                (when (< (or (cdr m) 0) my-edit-ruler-width)
                  (set-window-margins win (car m) my-edit-ruler-width)))
              ;; Marks can only render on rows that contain buffer lines, so
              ;; when end-of-buffer is on screen (fewer lines than window rows)
              ;; compress the whole-file scale into the rows that exist —
              ;; otherwise marks below EOB would silently vanish.
              (save-excursion
                (goto-char (or start (window-start win)))
                (forward-line 0)
                (let* ((total (max 1 (count-lines (point-min) (point-max))))
                       (h (max 1 (window-body-height win)))
                       (nrows (max 1 (min h (count-lines (point) (point-max)))))
                       (rows (make-vector nrows nil)))
                  ;; Map each hunk's buffer lines onto ruler rows (whole-file scale)
                  (dolist (hk hunks)
                    (let* ((sl (git-gutter-hunk-start-line hk))
                           (el (max sl (or (git-gutter-hunk-end-line hk) sl)))
                           (type (git-gutter-hunk-type hk))
                           (r1 (min (1- nrows) (/ (* (1- sl) nrows) total)))
                           (r2 (min (1- nrows) (/ (* (1- el) nrows) total))))
                      (cl-loop for r from r1 to r2
                               do (aset rows r (or (aref rows r) type)))))
                  ;; Attach one margin mark per marked row, on the visible lines
                  (cl-loop for r from 0 below nrows
                           do (let ((type (aref rows r)))
                                (when type
                                  (let ((ov (make-overlay (point) (point))))
                                    (overlay-put ov 'my-edit-ruler t)
                                    (overlay-put ov 'window win)
                                    (overlay-put ov 'priority 200)
                                    (overlay-put ov 'before-string
                                                 (propertize " " 'display
                                                             `((margin right-margin)
                                                               ,(propertize "▐" 'face (my-edit-ruler--face type))))))))
                              (unless (zerop (forward-line 1))
                                (cl-return))))))))))))

(defun my-edit-ruler-refresh (&rest _)
  "Refresh the edit ruler in all windows."
  (dolist (win (window-list nil 'no-mini))
    (my-edit-ruler-refresh-window win)))

;; Redraw on scroll/resize. Hunk-data refreshes come straight from git-gutter:
;; it computes hunks in an ASYNC process, so save/open/revert hooks would run
;; before `git-gutter:diffinfos' is updated — advise its update function
;; instead, which the async sentinel calls with the target buffer current.
(add-hook 'window-scroll-functions #'my-edit-ruler-refresh-window)
(add-hook 'window-configuration-change-hook #'my-edit-ruler-refresh)
(defun my-edit-ruler--after-gutter-update (&rest _)
  "Refresh the ruler in every window showing the buffer whose hunks updated."
  (dolist (win (get-buffer-window-list (current-buffer) nil t))
    (my-edit-ruler-refresh-window win)))
(with-eval-after-load 'git-gutter
  (advice-add 'git-gutter:update-diffinfo :after #'my-edit-ruler--after-gutter-update))

;; Jump between edits (works anywhere in the file)
(with-eval-after-load 'git-gutter
  (global-set-key (kbd "C-c n") 'git-gutter:next-hunk)
  (global-set-key (kbd "C-c p") 'git-gutter:previous-hunk))

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
(defvar my-select-all-overlay nil
  "Overlay used to emulate whole-buffer selection without moving point.")
(defun my-select-all-active-p ()
  (and (overlayp my-select-all-overlay)
       (eq (overlay-buffer my-select-all-overlay) (current-buffer))))
(defun my-clear-select-all-state ()
  (when (overlayp my-select-all-overlay)
    (delete-overlay my-select-all-overlay))
  (setq my-select-all-overlay nil))
(defun my-select-all-copy ()
  (interactive)
  (when (my-select-all-active-p)
    (kill-ring-save (point-min) (point-max))))
(defun my-select-all-cut ()
  (interactive)
  (when (my-select-all-active-p)
    (my-clear-select-all-state)
    (kill-region (point-min) (point-max))))
(defun my-select-all-delete ()
  (interactive)
  (when (my-select-all-active-p)
    (my-clear-select-all-state)
    (delete-region (point-min) (point-max))
    (goto-char (point-min))))
(defun my-select-all-quit ()
  (interactive)
  (my-clear-select-all-state)
  (keyboard-quit))
(defun my-select-all-replace-command-p (cmd)
  (or (eq cmd 'self-insert-command)
      (get cmd 'delete-selection)
      (memq cmd '(newline newline-and-indent
                  yank yank-pop clipboard-yank cua-paste quoted-insert
                  org-self-insert-command))))
(defun my-select-all-dispatch ()
  (interactive)
  (let* ((keys (this-command-keys-vector))
         (cmd (let ((overriding-terminal-local-map nil)
                    (overriding-local-map nil))
                (key-binding keys t))))
    (my-clear-select-all-state)
    (cond
     ((null cmd) nil)
     ((my-select-all-replace-command-p cmd)
      (delete-region (point-min) (point-max))
      (goto-char (point-min))
      (call-interactively cmd))
     ((commandp cmd)
      (call-interactively cmd)))))
(defvar my-select-all-transient-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c") #'my-select-all-copy)
    (define-key map (kbd "C-x") #'my-select-all-cut)
    (define-key map (kbd "C-v") #'my-select-all-dispatch)
    (define-key map (kbd "<S-insert>") #'my-select-all-dispatch)
    (define-key map (kbd "<delete>") #'my-select-all-delete)
    (define-key map (kbd "<backspace>") #'my-select-all-delete)
    (define-key map (kbd "DEL") #'my-select-all-delete)
    (define-key map (kbd "<left>") #'my-left-or-clear-selection)
    (define-key map (kbd "<right>") #'my-right-or-clear-selection)
    (define-key map (kbd "<up>") #'my-up-or-clear-selection)
    (define-key map (kbd "<down>") #'my-down-or-clear-selection)
    (define-key map (kbd "<prior>") #'my-page-up-or-clear-selection)
    (define-key map (kbd "<next>") #'my-page-down-or-clear-selection)
    (define-key map (kbd "C-g") #'my-select-all-quit)
    (define-key map [escape] #'my-select-all-quit)
    (define-key map [t] #'my-select-all-dispatch)
    map)
  "Transient keymap active while the custom whole-buffer selection is shown.")
(defun my-select-all ()
  (interactive)
  (my-clear-select-all-state)
  (setq my-select-all-overlay (make-overlay (point-min) (point-max) (current-buffer) nil t))
  (overlay-put my-select-all-overlay 'face 'region)
  (overlay-put my-select-all-overlay 'priority 1000)
  (overlay-put my-select-all-overlay 'evaporate t)
  (set-transient-map my-select-all-transient-map #'my-select-all-active-p #'my-clear-select-all-state))
;; Windows-style select all for C-a, keeping the viewport steady on selection.
(global-set-key (kbd "C-a") 'my-select-all)
;; Keep Shift+mouse selection behavior native
(define-key global-map (kbd "<S-down-mouse-1>") nil)
(cua-mode 1)
(setq cua-keep-region-after-copy t
      ;; A tiny positive delay keeps CUA cut/copy reliable on current Emacs builds.
      cua-prefix-override-inhibit-delay 0.05
      ;; Avoid extra Windows clipboard readback before replacing it.
      save-interprogram-paste-before-kill nil)
(defun my-begin-shift-selection ()
  (when (and cua-mode (not (use-region-p)))
    (cua-set-mark)))
(defun my-deactivate-selection ()
  (cond
   ((my-select-all-active-p)
    (my-clear-select-all-state)
    (goto-char (point-min)))
   ((use-region-p)
    (deactivate-mark))))
(defun my-collapse-selection-and-move (_direction fallback)
  (cond
   (this-command-keys-shift-translated
    (when (my-select-all-active-p)
      (my-clear-select-all-state))
    (my-begin-shift-selection)
    (call-interactively fallback))
   ((or (my-select-all-active-p) (use-region-p))
    (my-deactivate-selection))
   (t
    (call-interactively fallback))))
(defun my-left-or-clear-selection ()
  (interactive)
  (my-collapse-selection-and-move 'left #'left-char))
(defun my-right-or-clear-selection ()
  (interactive)
  (my-collapse-selection-and-move 'right #'right-char))
(defun my-up-or-clear-selection ()
  (interactive)
  (my-collapse-selection-and-move 'up #'previous-line))
(defun my-down-or-clear-selection ()
  (interactive)
  (my-collapse-selection-and-move 'down #'next-line))
(defun my-page-up-command ()
  (interactive)
  (condition-case nil
      (progn
        (scroll-down-command)
        (when (= (window-start) (point-min))
          (goto-char (point-min))))
    (beginning-of-buffer
     (goto-char (point-min)))))
(defun my-page-down-command ()
  (interactive)
  (condition-case nil
      (progn
        (scroll-up-command)
        (when (>= (window-end nil t) (point-max))
          (goto-char (point-max))))
    (end-of-buffer
     (goto-char (point-max)))))
(defun my-page-up-or-clear-selection ()
  (interactive)
  (my-collapse-selection-and-move 'page-up #'my-page-up-command))
(defun my-page-down-or-clear-selection ()
  (interactive)
  (my-collapse-selection-and-move 'page-down #'my-page-down-command))
(global-set-key [left] #'my-left-or-clear-selection)
(global-set-key [right] #'my-right-or-clear-selection)
(global-set-key [up] #'my-up-or-clear-selection)
(global-set-key [down] #'my-down-or-clear-selection)
(global-set-key [prior] #'my-page-up-or-clear-selection)
(global-set-key [next] #'my-page-down-or-clear-selection)
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
        (completion-at-point)
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
  ;; CHAR is nil at buffer edges (char-before at BOB / char-after at EOB)
  (pcase (and char (char-syntax char))
    (`?\s ?s) (`?w ?w) (`?_ ?w) (_ ?p)))
(defun my-forward-word (&optional arg)
  (interactive "^p")
  (or arg (setq arg 1))
  (when this-command-keys-shift-translated
    (my-begin-shift-selection))
  (let* ((backward (< arg 0)) (count (abs arg))
         (char-next (if backward 'char-before 'char-after))
         (skip-syntax (if backward 'skip-syntax-backward 'skip-syntax-forward))
         (skip-char (if backward 'backward-char 'forward-char))
         prev-char next-char)
    (while (> count 0)
      (setq next-char (funcall char-next))
      (cl-loop
       ;; nil = at buffer edge; nothing further to move over
       (unless next-char (cl-return))
       (if (or (eql next-char ?\n) (eql (char-syntax next-char) ?\s))
           (funcall skip-char)
         (funcall skip-syntax (char-to-string (char-syntax next-char))))
       (setq prev-char next-char)
       (setq next-char (funcall char-next))
       (when (or (null next-char)
                 (eql prev-char ?\n)
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
    ;; Prefer right neighbor; if none, go left. Then kill current.
    (let* ((win (selected-window))
           (cur (current-buffer))
           (buffers (my-tab-line--buffers))
           (len (length buffers))
           (idx (or (cl-position cur buffers) 0))
           (target (cond
                    ((and (> len 1) (< idx (1- len))) (nth (1+ idx) buffers))
                    ((> len 1) (nth (1- idx) buffers))
                    (t nil))))
      (when (buffer-live-p target)
        (set-window-buffer win target))
      (when (buffer-live-p cur)
        (kill-buffer cur))
      ;; Clean window-local order so wrap indices stay correct
      (let ((ordered (window-parameter win 'my-tab-ordered)))
        (when ordered
          (set-window-parameter win 'my-tab-ordered
                                 (cl-remove-if (lambda (b)
                                                 (or (eq b cur)
                                                     (not (buffer-live-p b))))
                                               ordered))))))))
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
(with-eval-after-load 'org
  (my-apply-org-faces)
  (advice-add 'org-call-for-shift-select :before #'my--org-shift-select-cua)
  (define-key org-mode-map (kbd "<C-tab>") nil))


;; Custom UI writes go to var/custom.el (see custom-file above)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Git helpers: quick diff, commit, push (simple)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Resolve repository root for current buffer/default-directory
(defun my-git--actual-repo-root ()
  "Return the real Git root for the current buffer/default-directory, or nil."
  (when (executable-find "git")
    (let ((default-directory
            (or (and buffer-file-name
                     (file-name-directory (file-truename buffer-file-name)))
                default-directory)))
      (with-temp-buffer
        (when (zerop (process-file "git" nil t nil "rev-parse" "--show-toplevel"))
          (file-name-as-directory (string-trim (buffer-string))))))))

(defun my-git--repo-root ()
  (or (my-git--actual-repo-root)
      (and (fboundp 'magit-toplevel) (ignore-errors (magit-toplevel)))
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
        ;; Re-run git-gutter so gutter + edit ruler drop hunks that were
        ;; committed (its async update then refreshes the ruler via advice)
        (when (bound-and-true-p git-gutter-mode)
          (ignore-errors (git-gutter)))
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
