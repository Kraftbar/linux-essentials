
;;; This is all kinds of necessary
(require 'package)
(setq package-enable-at-startup nil)


;; think i need this for gnu sign
(setq package-check-signature nil)

;;; remove SC if you are not using sunrise commander and org if you like outdated packages
(setq package-archives '(
			 ("gnu"   . "http://elpa.gnu.org/packages/")
			 ("melpa" . "https://melpa.org/packages/")))
(package-initialize)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; Bootstrapping use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; ----------------------------------------

;; saves last state 
(desktop-save-mode 1)





;; company  --- not working 
(use-package company
  :ensure t
  :config
  (setq company-idle-delay 0)
  (setq company-minimum-prefix-length 3))
(with-eval-after-load 'company
  (define-key company-active-map (kbd "M-n") nil)
  (define-key company-active-map (kbd "M-p") nil)
  (define-key company-active-map (kbd "C-n") #'company-select-next)
  (define-key company-active-map (kbd "C-p") #'company-select-previous)
  (define-key company-active-map (kbd "SPC") #'company-abort))
;; company latex
(use-package company-auctex
  :after (auctex company)
  :config (company-auctex-init))
;; company  --- not working 






;; help on what key to press next
(use-package which-key
  :ensure t
  :config
    (which-key-mode))


;; elisp parantesies matching
(show-paren-mode 1)






;; --- copy pasta helm config --- 
;; NOTE: needs  elpa-helm and elpa-async
(use-package helm
  :bind (("M-x" . helm-M-x)
	 ("C-x C-f" . 'helm-M-x-find-files)
	 ("C-x C-b" . 'helm-buffers-list)
         ("C-x C-r" . helm-recentf)))
;; --- copy pasta helm config --- 


;; main emacs latex package
(use-package auctex
  :defer t
  :ensure t)
(use-package company-auctex 
  :defer t
  :ensure t)

;; latex pls?
(ido-mode 1)









;; Now emacs will not save files and backup things
(setq make-backup-files nil)
(setq auto-save-default nil)

;; No scroll-bar
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
;; No splash screen pls
(setq inhibit-startup-message t)


;; syntax error checking on the fly
(use-package flycheck
  :ensure t
  :init
  (add-hook 'after-init-hook 'global-flycheck-mode)
  :config
  (setq-default flycheck-disabled-checkers '(emacs-lisp-checkdoc)))






;; undo-tree
(use-package undo-tree
  :ensure t
  :diminish undo-tree-mode
  :init
  (global-undo-tree-mode 1)
  :config
  (defalias 'redo 'undo-tree-redo)
  :bind (("C-z" . undo)     ; Zap to character isn't helpful
         ("C-S-z" . redo)))

(setq undo-tree-visualizer-timestamps t)








;; ________________________
;; ------ shortcuts -------

;; select region with shift rightclick
(define-key global-map (kbd "<S-down-mouse-1>") 'mouse-save-then-kill)


(global-set-key (kbd "C-M-S-q") 'kill-this-buffer)
(global-set-key (kbd "C-M-S-w") (lambda () (interactive)
                                  (kill-this-buffer)
                                  (if (equal 1 (length (window-list)))
                                      (delete-frame)
                                    (delete-window))))

;; jump to other frame (split screen)
;; (global-set-key [C-tab] 'other-frame)




;; ---------------- SHIFT TAB BUFFER START
(defun xah-user-buffer-q ()
  "Return t if current buffer is a user buffer, else nil.
Typically, if buffer name starts with *, it's not considered a user buffer.
This function is used by buffer switching command and close buffer command, so that next buffer shown is a user buffer.
You can override this function to get your idea of “user buffer”.
version 2016-06-18"
  (interactive)
  (if (string-equal "*" (substring (buffer-name) 0 1))
      nil
    (if (string-equal major-mode "dired-mode")
        nil
      t
      )))
(defun xah-next-user-buffer ()
  "Switch to the next user buffer.
“user buffer” is determined by `xah-user-buffer-q'.
URL `http://ergoemacs.org/emacs/elisp_next_prev_user_buffer.html'
Version 2016-06-19"
  (interactive)
  (next-buffer)
  (let ((i 0))
    (while (< i 20)
      (if (not (xah-user-buffer-q))
          (progn (next-buffer)
                 (setq i (1+ i)))
        (progn (setq i 100))))))

(defun xah-previous-user-buffer ()
  "Switch to the previous user buffer.
“user buffer” is determined by `xah-user-buffer-q'.
URL `http://ergoemacs.org/emacs/elisp_next_prev_user_buffer.html'
Version 2016-06-19"
  (interactive)
  (previous-buffer)
  (let ((i 0))
    (while (< i 20)
      (if (not (xah-user-buffer-q))
          (progn (previous-buffer)
                 (setq i (1+ i)))
        (progn (setq i 100))))))

(global-set-key [C-tab] 'xah-next-user-buffer)
(global-set-key [C-S-iso-lefttab] 'xah-prevoius-user-buffer)
;; ---------------- SHIFT TAB BUFFER END



(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (helm which-key use-package undo-tree flycheck company-auctex))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
