
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;               useful cnlang functions                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



 

(defun transelate-to-chinese (start end )
    "missing:
        - multiline region
        - no highlight
"
    (interactive "r")

    (goto-char end)
    (forward-line 1)
    (while (>= (point) start)
      (shell-command  (concat
                        "~/.emacs.d/__transelate-to-chinese.sh \""
                        (buffer-substring-no-properties       (line-beginning-position)       (line-end-position)     )
                        "\""      ))
      (kill-line 1)
      (insert-buffer "*Shell Command Output*")
      (forward-line -1)
      )

)







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                 snippets                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





;; (cl-case  system-type
;;           (cywing  "Running cywing")
;;           (darwing "Running Mac Osx")
;;           (gnu/linux "Running Linux")
;; )



;; ELISP> (shell-command-to-string "pwd")
;; "/home/tux/PycharmProjects/ocaml/prelude\n"


