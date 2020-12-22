(tab-bar-mode 1)

(global-set-key [(control tab)] 'tab-next)
(global-set-key [(control shift tab)] 'tab-previous)



;; ------------ exit buffer ------------
;; if just one tab exit
(global-set-key (kbd "C-w") (lambda () (interactive) (kill-this-buffer) (tab-close)))



;; --------- new buffer  ------------
;; if just one tab with minibuffer, dont create new tab
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
	
(global-set-key (kbd "C-n") (lambda () (interactive)  (tab-new) (xah-new-empty-buffer)))





;; ------------ last closed ------------
(defvar killed-file-list nil
  "List of recently killed files.")

(defun add-file-to-killed-file-list ()
  "If buffer is associated with a file name, add that file to the
`killed-file-list' when killing the buffer."
  (when buffer-file-name
    (push buffer-file-name killed-file-list)))

(add-hook 'kill-buffer-hook #'add-file-to-killed-file-list)

(defun reopen-killed-file ()
  "Reopen the most recently killed file, if one exists."
  (interactive)
  (when killed-file-list
    (find-file (pop killed-file-list))))
	
	
(global-set-key (kbd "C-S-t") (lambda () (interactive) (tab-new) (reopen-killed-file)))






;; -------------- open files in tabs --------------





(defun ns-drag-n-drop (event &optional new-frame force-text)
  "Edit the files listed in the drag-n-drop EVENT.
Switch to a buffer editing the last file dropped."
  (interactive "e")
  (let* ((window (posn-window (event-start event)))
         (arg (car (cdr (cdr event))))
         (type (car arg))
         (data (car (cdr arg)))
         (url-or-string (cond ((eq type 'file)
                               (concat "file:" data))
                              (t data))))
    (set-frame-selected-window nil window)
    (when new-frame
      (select-frame (make-frame)))
    (raise-frame)
    (setq window (selected-window))
    (if force-text
        (dnd-insert-text window 'private data)
      (dnd-handle-one-url window 'private url-or-string))))


(defun ns-drag-n-drop-other-frame (event)
  "Edit the files listed in the drag-n-drop EVENT, in other frames.
May create new frames, or reuse existing ones.  The frame editing
the last file dropped is selected."
  (interactive "e")
  (ns-drag-n-drop event t))

(defun ns-drag-n-drop-as-text (event)
  "Drop the data in EVENT as text."
  (interactive "e")
  (ns-drag-n-drop event nil t))

(defun ns-drag-n-drop-as-text-other-frame (event)
  "Drop the data in EVENT as text in a new frame."
  (interactive "e")
  (ns-drag-n-drop event t t))

(global-set-key [drag-n-drop] 'ns-drag-n-drop)
(global-set-key [C-drag-n-drop] 'ns-drag-n-drop-other-frame)
(global-set-key [M-drag-n-drop] 'ns-drag-n-drop-as-text)
(global-set-key [C-M-drag-n-drop] 'ns-drag-n-drop-as-text-other-frame)


;; new tab 
 (add-hook 'find-file-hook  (lambda () (tab-new) (switch-to-prev-buffer)) )
