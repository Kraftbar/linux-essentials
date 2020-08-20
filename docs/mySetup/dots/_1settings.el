;; disable emacs's automatic "backup~     " files
(setq make-backup-files nil)

;; disable emacs's automatic "#auto-save# " files,
(setq auto-save-default nil)

;; saves last state, but prompts
(desktop-save-mode 1)

;; "smooth" scrolling mouse   
(setq mouse-wheel-scroll-amount '(2 ((shift) . 1) ((control) . nil)))
(setq mouse-wheel-progressive-speed nil)

;; "smooth" scrolling keyboard 
(setq scroll-step 1)

;; use esc to close minibuffers 
(define-key key-translation-map (kbd "ESC") (kbd "C-g"))	

;; start server if not running
(load "server")
(unless (server-running-p) (server-start))

;; save desktop
(desktop-save-mode 1)
