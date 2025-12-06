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
(blink-cursor-mode 0)
(fringe-mode '(0 . 0))

(setq frame-background-mode 'light)
(set-background-color "#ffffff")
(set-foreground-color "#666666")

(setq inhibit-startup-screen t)
(setq inhibit-startup-echo-area-message t)
(setq inhibit-startup-message t)   ;; Show/hide startup page
(setq initial-scratch-message nil) ;; Show/hide *scratch* buffer message
;; (menu-bar-mode 0)                  ;; Show/hide menubar
(tool-bar-mode 0)                  ;; Show/hide toolbar
(tooltip-mode  0)                  ;; Show/hide tooltip
(scroll-bar-mode 0)                ;; Show/hide scrollbar



(defun mode-line-render (left right)
  "Return a string of `window-width' length containing left, and
   right aligned respectively."
  (let* ((available-width (- (window-total-width) (length left) )))
    (format (format "%%s %%%ds" available-width) left right)))


(setq-default header-line-format
  '(:eval (mode-line-render

   (format-mode-line
    (list
     (propertize "File " 'face `(:weight regular))
     "%b "
     '(:eval (if (and buffer-file-name (buffer-modified-p))
         (propertize "(modified)" 
		     'face `(:weight light
			     :foreground "#aaaaaa"))))))
   
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
  (define-key helm-swoop-map (kbd "RET") 'helm-swoop-next-line))
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
