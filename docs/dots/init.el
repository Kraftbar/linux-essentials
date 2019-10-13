
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



;; comes in usefull
(defun my/bypass-confirmation-all (function &rest args)
  "Call FUNCTION with ARGS, bypassing all prompts.
This includes both `y-or-n-p' and `yes-or-no-p'."
  (my/with-advice
      ((#'y-or-n-p    :override (lambda (prompt) t))
       (#'yes-or-no-p :override (lambda (prompt) t)))
    (apply function args)))

;;; Bootstrapping use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; ----------------------------------------

;; saves last state 
(desktop-save-mode 1)


;; orgmode
(org-babel-do-load-languages
 'org-babel-load-languages '((C . t)
			     (octave . t)))

;; fontify code in code blocks
(setq org-src-fontify-natively t)



(setq org-confirm-babel-evaluate nil)


(defun org-export-as-pdf-and-open ()
  (interactive)
  (save-buffer)
  (org-open-file (org-latex-export-to-pdf) )
  (windmove-left))

(add-hook 
 'org-mode-hook
 (lambda()
   (define-key org-mode-map 
       (kbd "<f5>") 'org-export-as-pdf-and-open)))

;; dont remember what this is
(setq org-startup-truncated nil)

;; gjelder for alle filer men best for pdf
(global-auto-revert-mode t)
(setq revert-without-query '(".*"))

;; For pdf org
;; Source: http://www.emacswiki.org/emacs-en/download/misc-cmds.el
(defun revert-buffer-no-confirm ()
    "Revert buffer without confirmation."
    (interactive)
    (revert-buffer :ignore-auto :noconfirm))




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



;; open file
(global-set-key (kbd "C-o") 'menu-find-file-existing)
(defadvice find-file-read-args (around find-file-read-args-always-use-dialog-box act)
  "Simulate invoking menu item as if by the mouse; see `use-dialog-box'."
 (let ((last-nonmenu-event nil))
       ad-do-it))


;; --- copy pasta helm config --- 
;; NOTE: needs  elpa-helm and elpa-async
(use-package helm
  :bind (("M-x" . helm-M-x)
	 ("C-x C-f" . 'helm-find-files)
	 ("C-x C-b" . 'helm-buffers-list)
         ("C-r" . helm-recentf))) ;; consider changing 
;; --- copy pasta helm config --- 


;; main emacs latex package
(use-package auctex
  :defer t
  :ensure t)
(use-package company-auctex 
  :defer t
  :ensure t)
(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq-default TeX-master nil)

;; latex pls?
(ido-mode 1)


;; delete highlited text  when writing  
 (delete-selection-mode 1)






(defun xah-insert-column-az ()
  "Insert letters A to Z vertically, similar to `rectangle-number-lines'.
The commpand will prompt for a start char, and number of chars to insert.
The start char can be any char in Unicode.
URL `http://ergoemacs.org/emacs/emacs_insert-alphabets.html'
Version 2019-03-07"
  (interactive)
  (let (
        ($startChar (string-to-char (read-string "Start char: " "a")))
        ($howmany (string-to-number (read-string "How many: " "26")))
        ($colpos (- (point) (line-beginning-position))))
    (dotimes ($i $howmany )
      (progn
        (insert-char (+ $i $startChar))
        (forward-line)
        (beginning-of-line)
        (forward-char $colpos)))))









;;; move window

(global-set-key [M-left] 'windmove-left)          ; move to left window
(global-set-key [M-right] 'windmove-right)        ; move to right window
(global-set-key [M-up] 'windmove-up)              ; move to upper window
(global-set-key [M-down] 'windmove-down)          ; move to lower window


(recentf-mode 1) ; keep a list of recently opened files

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



(use-package centered-window :ensure t)



(setq undo-tree-visualizer-timestamps t)


;; remember cursor position, for emacs 25.1 or later
(save-place-mode 1)


;; on Linux, make Control+wheel do increase/decrease font size
(global-set-key (kbd "<C-mouse-4>") 'text-scale-increase)
(global-set-key (kbd "<C-mouse-5>") 'text-scale-decrease)


;; ________________________
;; ------ shortcuts -------

;; select region with shift rightclick
(define-key global-map (kbd "<S-down-mouse-1>") 'mouse-save-then-kill)


(global-set-key (kbd "C-M-S-q") 'kill-this-buffer) ; consider just C-q
(global-set-key (kbd "C-M-S-w") (lambda () (interactive)
                                  (kill-this-buffer)
                                  (if (equal 1 (length (window-list)))
                                      (delete-frame)
                                    (delete-window))))

;; jump to other frame (split screen)
;; (global-set-key [C-tab] 'other-frame)



;; SMooth scrolling
    (setq mouse-wheel-progressive-speed nil) ;; don't accelerate scrolling
    (setq mouse-wheel-follow-mouse 't) ;; scroll window under mouse
    (setq scroll-step 1) ;; keyboard scroll one line at a time




;; Toggle full-screen
(defun toggle-full-screen-and-bars ()
  "Toggles full-screen mode and bars."
  (interactive)
  (toggle-menu-bar-mode-from-frame )
  (tool-bar-mode )
  (toggle-frame-fullscreen))
;; Use F11 to switch between windowed and full-screen modes
(global-set-key [f11] 'toggle-full-screen-and-bars)
(global-set-key [f10] 'toggle-menu-bar-mode-from-frame)
(global-set-key [f12] 'tool-bar-mode)








;; ---------------- SHIFT TAB BUFFER START
(defun xah-user-buffer-q ()
  "Return t if current buffer is a user buffer, else nil.
Typically, if buffer name starts with *, it's not considered a user buffer.
This function is used by buffer switching command and close buffer command, so that next buffer shown is a user buffer.
You can override this function to get your idea of “user+ buffer”.
version 2016-06-18"
  (interactive)
  (if (or (string-equal "*" (substring (buffer-name) 0 1))
	  (string-equal "pdf" (substring (buffer-name) 0 3))
	  )
      nil
    (if (string-equal major-mode "dired-mode")
        nil
      t
      )))


(defun user-buffer-p ()
  "Return t if current buffer is a user buffer, else nil."
  (or
   (string-equal "*" (substring (buffer-name) 0 1))
   (string-equal "pdf" (substring (buffer-name) -3))
   (memq major-mode '(dired-mode magit-status-mode))))

(defun xah-next-user-buffer ()
  "Switch to the next user buffer.
“user buffer” is determined by `xah-user-buffer-q'.
URL `http://ergoemacs.org/emacs/elisp_next_prev_user_buffer.html'
Version 2016-06-19"
  (interactive)
  (next-buffer)
  (let ((i 0))
    (while (< i 20)
      (if (user-buffer-p)  ;;not (user-buffer-p))
          (progn (next-buffer)
                 (setq i (1+ i)))
        (progn (setq i 100))))))



(defun  xah-previous-emacs-buffer ()
  "Switch to the previous user buffer.
“user buffer” is determined by `xah-user-buffer-q'.
URL `http://ergoemacs.org/emacs/elisp_next_prev_user_buffer.html'
Version 2016-06-19"
  (interactive)
  (previous-buffer)
  (let ((i 0))
    (while (< i 20)
      (if (user-buffer-p)   ;;not (user-buffer-p))
          (progn (previous-buffer)
                 (setq i (1+ i)))
        (progn (setq i 100))))))



(global-set-key [C-tab] 'xah-next-user-buffer)
(global-set-key [C-iso-lefttab] 'xah-previous-emacs-buffer)

;; ---------------- SHIFT TAB BUFFER END






;; fix some org-mode shortcuts


;; esc by its own has weird behavior when
;; dealing with multiple windows
(define-key key-translation-map (kbd "ESC") (kbd "C-g"))





;; don't let the cursor go into minibuffer prompt
;; Tip taken from Xah Lee: http://ergoemacs.org/emacs/emacs_stop_cursor_enter_prompt.html
(setq minibuffer-prompt-properties
      '(read-only t point-entered minibuffer-avoid-prompt face minibuffer-prompt))



;; split window default right
(setq split-height-threshold nil)
(setq split-width-threshold 122)

;; toggle fullscreen buffer
;; NOTE: This when toggled desktopmode will not save
(defun toggle-maximize-buffer () "Maximize buffer"
  (interactive)
  (if (= 1 (length (window-list)))
      (jump-to-register '_) 
    (progn
      (window-configuration-to-register '_)
      (delete-other-windows))))


(global-set-key [f9] 'toggle-maximize-buffer)


;;     Own functions

(use-package s
    :ensure t
    )    ;; “The long lost Emacs string manipulation library”.


(defun get-selection ()
  "Get the text selected in current buffer as string"
  (interactive)
  (buffer-substring-no-properties (region-beginning) (region-end)))

(defun octavePrint ()
  "Delete highlighted text and inserts it agian."
  (interactive)
  (let(
      (beg (region-beginning))
      (end (region-end      ))
       )	  
       (when (region-active-p)
	 (goto-char end)
	 (while (> (point) beg)
	   (insert "octave(")
	   (move-end-of-line 1)
	   (insert ")")
	   (forward-line -1))
	 )
       )
 )




(defun testtest ()
  (interactive)
  (when (region-active-p)
    (insert "\begin{}")
    (dolist (line (split-string (buffer-substring (region-beginning) (region-end)) "\n")) 
      )
   )
  )







(global-set-key (kbd "C-c C-c") 'eval-buffer)




(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(cwm-centered-window-width 122)
 '(doc-view-continuous t)
 '(package-selected-packages
   (quote
    (s centered-window helm which-key use-package undo-tree flycheck company-auctex))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
