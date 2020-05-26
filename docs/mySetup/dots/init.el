
;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(package-initialize)

(require 'org)

(setq-default indent-tabs-mode nil)
(setq org-display-inline-images t)
(setq org-redisplay-inline-images t)
(setq org-startup-with-inline-images "inlineimages")

(setq default-frame-alist
      (append (list '(width . 72) '(height . 40))))

(setq org-confirm-elisp-link-function nil)
      
				  
(global-set-key [(control z)]         'undo)
(global-set-key "\C-x\C-x"            'execute-extended-command)

(set-frame-font "Roboto Mono Light 10")

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


(setq-default mode-line-format   "")

(set-face-attribute 'header-line nil
;;                    :weight 'regular
		    :height 140
                    :underline "black"
                    :foreground "black"
		    :background "white"
                    :box `(:line-width 3 :color "white" :style nil))
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








;; non minimal config - my config
(defconst user-init-dir
  (cond ((boundp 'user-emacs-directory)
         user-emacs-directory)
        ((boundp 'user-init-directory)
         user-init-directory)
        (t "~/.emacs.d/")))
(defun load-user-file (file)
  (interactive "f")
  "Load a file in current user's configuration directory"
  (load-file (expand-file-name file user-init-dir)))
(load-user-file "_1settings.el")
(load-user-file "_2packages.el")
(load-user-file "_3saneKeys.el")
(load-user-file "_3suppKeys.el")
(load-user-file "_4myFunc.el")
(load-user-file "_5chromeBehv.el")




(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (ctrlf command-log-mode elpy popwin which-key use-package))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
