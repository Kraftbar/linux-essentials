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
;; keep region
(setq cua-keep-region-after-copy t) 

;; same as pressing X button 
(global-set-key (kbd "<M-f4>") 'save-buffers-kill-terminal) 

;; Save buffer
(global-set-key (kbd "C-s") 'save-buffer)      

    
;; exit window or emacs window
(global-set-key (kbd "C-S-w") (lambda () (interactive)
                                  (if (equal 1 (length (window-list)))
                                      (delete-frame)
                                    (delete-window))))




;;; ---------find ------------------
;; still cant edit after pressing return
;; -> replaced by CTRLF package
;(global-set-key (kbd "C-f") 'isearch-edit-string)
;(progn
;  (define-key isearch-mode-map (kbd "<return>") 'isearch-repeat-forward)
;  (define-key minibuffer-local-isearch-map (kbd "<return>") 'isearch-forward-exit-minibuffer)
;  )

;;; fine
; (define-key isearch-mode-map [escape] 'isearch-exit)   ;; isearch
;;; not fine, get isearch-abort behavior
;  (define-key isearch-mode-map (kbd "<esc>") 'isearch-exit)
;  (define-key minibuffer-local-isearch-map (kbd "<esc>") 'isearch-exit)






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







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; misc.                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; move window
(global-set-key [M-left] 'windmove-left)          ; move to left window
(global-set-key [M-right] 'windmove-right)        ; move to right window
(global-set-key [M-up] 'windmove-up)              ; move to upper window
(global-set-key [M-down] 'windmove-down)          ; move to lower window









;; https://melpa.org/#/syntax-subword
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; back and foward                                                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



(defun my-syntax-class (char)
  "Return ?s, ?w or ?p depending or whether CHAR is a white-space, word or punctuation character."
  (pcase (char-syntax char)
      (`?\s ?s)
      (`?w ?w)
      (`?_ ?w)
      (_ ?p)))

(defun my-forward-word (&optional arg)
  "Move point forward a word (simulate behavior of Far Manager's editor).
With prefix argument ARG, do it ARG times if positive, or move backwards ARG times if negative."
  (interactive "^p")
  (or arg (setq arg 1))
  (let* ((backward (< arg 0))
         (count (abs arg))
         (char-next
          (if backward 'char-before 'char-after))
         (skip-syntax
          (if backward 'skip-syntax-backward 'skip-syntax-forward))
         (skip-char
          (if backward 'backward-char 'forward-char))
         prev-char next-char)
    (while (> count 0)
      (setq next-char (funcall char-next))
      (cl-loop
       (if (or                          ; skip one char at a time for whitespace,
            (eql next-char ?\n)         ; in order to stop on newlines
            (eql (char-syntax next-char) ?\s))
           (funcall skip-char)
         (funcall skip-syntax (char-to-string (char-syntax next-char))))
       (setq prev-char next-char)
       (setq next-char (funcall char-next))
       ;; (message (format "Prev: %c %c %c Next: %c %c %c"
       ;;                   prev-char (char-syntax prev-char) (my-syntax-class prev-char)
       ;;                   next-char (char-syntax next-char) (my-syntax-class next-char)))
       (when
           (or
            (eql prev-char ?\n)         ; stop on newlines
            (eql next-char ?\n)
            (and                        ; stop on word -> punctuation
             (eql (my-syntax-class prev-char) ?w)
             (eql (my-syntax-class next-char) ?p))
            (and                        ; stop on word -> whitespace
             this-command-keys-shift-translated ; when selecting
             (eql (my-syntax-class prev-char) ?w)
             (eql (my-syntax-class next-char) ?s))
            (and                        ; stop on whitespace -> non-whitespace
             (not backward)             ; when going forward
             (not this-command-keys-shift-translated) ; and not selecting
             (eql (my-syntax-class prev-char) ?s)
             (not (eql (my-syntax-class next-char) ?s)))
            (and                        ; stop on non-whitespace -> whitespace
             backward                   ; when going backward
             (not this-command-keys-shift-translated) ; and not selecting
             (not (eql (my-syntax-class prev-char) ?s))
             (eql (my-syntax-class next-char) ?s))
            )
         (return))
       )
      (setq count (1- count)))))

(defun delete-word (&optional arg)
  "Delete characters forward until encountering the end of a word.
With argument ARG, do this that many times."
  (interactive "p")
  (delete-region (point) (progn (my-forward-word arg) (point))))

(defun backward-delete-word (arg)
  "Delete characters backward until encountering the beginning of a word.
With argument ARG, do this that many times."
  (interactive "p")
  (delete-word (- arg)))

(defun my-backward-word (&optional arg)
  (interactive "^p")
  (or arg (setq arg 1))
  (my-forward-word (- arg)))

(global-set-key (kbd "C-<left>") 'my-backward-word)
(global-set-key (kbd "C-<right>") 'my-forward-word)
(global-set-key (kbd "C-<delete>") 'delete-word)
(global-set-key (kbd "C-<backspace>") 'backward-delete-word)
