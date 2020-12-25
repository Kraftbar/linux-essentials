;; todo:
;;  -


;; disable emacs's automatic "backup~     " files
(setq make-backup-files nil)

;; disable emacs's automatic "#auto-save# " files,
(setq auto-save-default nil)

;; saves last state, but prompts
(desktop-save-mode 1)

;; "smooth" scrolling mouse   
(setq mouse-wheel-scroll-amount '(3 ((shift) . 1) ((control) . nil)))
(setq mouse-wheel-progressive-speed nil)

;; "smooth" scrolling keyboard 
(setq scroll-step 1)

;; use esc to close minibuffers 
(define-key key-translation-map (kbd "ESC") (kbd "C-g"))	

;; start server if not running
(load "server")
(unless (server-running-p) (server-start))

;; Highlight Brackets
(show-paren-mode 1)

;; Always follow symlink
(setq vc-follow-symlinks t)


;; no sound
(setq visible-bell 1)


;; no gui promt
(desktop-save-mode 0)      ;; save desktop
(defadvice save-buffers-kill-emacs (around no-y-or-n activate)
  (cl-flet ((yes-or-no-p (&rest args) t)
         (y-or-n-p (&rest args) t))
    ad-do-it))             ;; "modified buffers, are you sure?"



;; right click
(global-set-key [mouse-3] 'mouse-popup-menubar-stuff)          ; Gives right-click a context menu


