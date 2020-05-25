;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Same as sane text eds.                                                 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; open file
(global-set-key (kbd "C-o") 'menu-find-file-existing)
;; force dialog
(defadvice find-file-read-args (around find-file-read-args-always-use-dialog-box act)
  "Simulate invoking menu item as if by the mouse; see `use-dialog-box'."
 (let ((last-nonmenu-event nil))
       ad-do-it))


;; on Linux, make Control+wheel do increase/decrease font size
(global-set-key (kbd "<C-mouse-4>") 'text-scale-increase)
(global-set-key (kbd "<C-mouse-5>") 'text-scale-decrease)
(global-set-key (kbd "C-+") 'text-scale-increase)
(global-set-key (kbd "C--") 'text-scale-decrease)


;; select all
(global-set-key (kbd "C-a") 'mark-whole-buffer)       


;; select region with shift leftclick
(define-key global-map (kbd "<S-down-mouse-1>") 'mouse-save-then-kill)


;; copy, cut, pase, 
(cua-mode 1)




;; Save buffer
(global-set-key (kbd "C-s") 'save-buffer)      


;; exit buffer
(global-set-key (kbd "C-w") (lambda () (interactive) (kill-this-buffer) (xah-next-user-buffer)))

;; exit window or emacs window
(global-set-key (kbd "C-S-w") (lambda () (interactive)
                                  (if (equal 1 (length (window-list)))
                                      (delete-frame)
                                    (delete-window))))




;;; ---------find ------------------
(global-set-key (kbd "C-f") 'isearch-edit-string)
(progn
  (define-key isearch-mode-map (kbd "<return>") 'isearch-repeat-forward)
  (define-key minibuffer-local-isearch-map (kbd "<return>") 'isearch-forward-exit-minibuffer)
  )

;;; fine
 (define-key isearch-mode-map [escape] 'isearch-exit)   ;; isearch
;;; not fine, get isearch-abort behavior
;  (define-key isearch-mode-map (kbd "<esc>") 'isearch-exit)
;  (define-key minibuffer-local-isearch-map (kbd "<esc>") 'isearch-exit)




;; ---------new buffer  ------------
(defun xah-new-empty-buffer ()
  "Create a new empty buffer.
New buffer will be named “untitled” or “untitled<2>”, “untitled<3>”, etc.
It returns the buffer (for elisp programing).
URL `http://ergoemacs.org/emacs/emacs_new_empty_buffer.html'
Version 2017-11-01"
  (interactive)
  (let (($buf (generate-new-buffer "untitled")))
    (switch-to-buffer $buf)
    (funcall initial-major-mode)
    (setq buffer-offer-save t)
    $buf))
(global-set-key (kbd "C-n") 'xah-new-empty-buffer) 



;; -----------Indent region------------
(defun indent-region-custom(numSpaces)
    (progn 
        ; default to start and end of current line
        (setq regionStart (line-beginning-position))
        (setq regionEnd (line-end-position))

        ; if there's a selection, use that instead of the current line
        (when (use-region-p)
            (setq regionStart (region-beginning))
            (setq regionEnd (region-end))
        )

        (save-excursion ; restore the position afterwards            
            (goto-char regionStart) ; go to the start of region
            (setq start (line-beginning-position)) ; save the start of the line
            (goto-char regionEnd) ; go to the end of region
            (setq end (line-end-position)) ; save the end of the line

            (indent-rigidly start end numSpaces) ; indent between start and end
            (setq deactivate-mark nil) ; restore the selected region
        )
    )
)
(defun untab-region (N)
    (interactive "p")
    (indent-region-custom -4)
)
(defun tab-region (N)
    (interactive "p")
    (if (active-minibuffer-window)
        (minibuffer-complete)    ; tab is pressed in minibuffer window -> do completion
    ; else
    (if (string= (buffer-name) "*shell*")
        (comint-dynamic-complete) ; in a shell, use tab completion
    ; else
    (if (use-region-p)    ; tab is pressed is any other buffer -> execute with space insertion
        (indent-region-custom 4) ; region was selected, call indent-region
        (insert "    ") ; else insert four spaces  expected
    )))
)
(global-set-key (kbd "<backtab>") 'untab-region)
(global-set-key (kbd "<tab>") 'tab-region)



;; TODO:
;; - S-arrows for moving text up and down. 





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; misc.                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; move window
(global-set-key [M-left] 'windmove-left)          ; move to left window
(global-set-key [M-right] 'windmove-right)        ; move to right window
(global-set-key [M-up] 'windmove-up)              ; move to upper window
(global-set-key [M-down] 'windmove-down)          ; move to lower window





