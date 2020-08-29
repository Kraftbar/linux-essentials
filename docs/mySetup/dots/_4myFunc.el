
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Promt user before ending session (want this at shutdown, not impl yet) ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



 

(defun transelate-to-chinese (start end )
  (interactive "r")
  (shell-command  (concat "~/.emacs.d/__transelate-to-chinese.sh " (buffer-substring-no-properties start end) ))    
  (insert-buffer "*Shell Command Output*")
)


