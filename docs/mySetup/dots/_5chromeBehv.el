;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; try to make behavior simmilar with chrome                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
