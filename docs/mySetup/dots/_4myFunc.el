;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;               useful cnlang functions                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun transelate-to-chinese (start end )
    " bug:
        - pos of cursor at 1
    "
    (interactive "r")

    (goto-char end)

    (while (and    (>= (point) start)
                   (not (equal  (point) 1) ))
      (shell-command  (concat
                        "~/.emacs.d/__transelate-to-chinese.sh \""
                        (buffer-substring-no-properties       (line-beginning-position)       (line-end-position)     )
                        "\""      ))
      (kill-line 1)
      (insert-buffer "*Shell Command Output*")
      (forward-line -1)
      (message "while %s > %s" (point) start)
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



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::;;;;;;;;;;;;;;;;;;;;;;
;;                 borrowed code                                 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun xah-get-bounds-of-thing-or-region (@unit)
  "Same as `xah-get-bounds-of-thing', except when (use-region-p) is t, return the region boundary instead.
Version 2016-10-18"
  (if (use-region-p)
      (cons (region-beginning) (region-end))
    (xah-get-bounds-of-thing @unit)))

(defun xah-get-thing-at-point (@unit)
  "Same as `xah-get-bounds-of-thing', but return the string.
Version 2016-10-18T02:31:36-07:00"
  (let ( ($bds (xah-get-bounds-of-thing @unit)) )
    (buffer-substring-no-properties (car $bds) (cdr $bds))))

(defun xah-get-thing-at-cursor (@unit)
  "Same as `xah-get-bounds-of-thing', except this returns a vector [text a b], where text is the string and a b are its boundary.
Version 2016-10-18T00:23:52-07:00"
  (let* (
         ($bds (xah-get-bounds-of-thing @unit))
         ($p1 (car $bds)) ($p2 (cdr $bds)))
    (vector (buffer-substring-no-properties $p1 $p2) $p1 $p2 )))

(defun xah-get-bounds-of-thing (@unit )
  "Return the boundary of @UNIT under cursor.
Return a cons cell (START . END).
@UNIT can be:
• 'word — sequence of 0 to 9, A to Z, a to z, and hyphen.
• 'glyphs — sequence of visible glyphs. Useful for file name, URL, …, anything doesn't have white spaces in it.
• 'line — delimited by “\\n”. (captured text does not include “\\n”.)
• 'block — delimited by empty lines or beginning/end of buffer. Lines with just spaces or tabs are also considered empty line. (captured text does not include a ending “\\n”.)
• 'buffer — whole buffer. (respects `narrow-to-region')
• 'filepath — delimited by chars that's USUALLY not part of filepath.
• 'url — delimited by chars that's USUALLY not part of URL.
• a vector [beginRegex endRegex] — The elements are regex strings used to determine the beginning/end of boundary chars. They are passed to `skip-chars-backward' and `skip-chars-forward'. For example, if you want paren as delimiter, use [\"^(\" \"^)\"]
This function is similar to `bounds-of-thing-at-point'.
The main difference are:
• This function's behavior does not depend on syntax table. e.g. for @units 「'word」, 「'block」, etc.
• 'line always returns the line without end of line character, avoiding inconsistency when the line is at end of buffer.
• Support certain “thing” such as 'glyphs that's a sequence of chars. Useful as file path or url in html links, but do not know which before hand.
• Some “thing” such 'url and 'filepath considers strings that at USUALLY used for such. The algorithm that determines this is different from thing-at-point.
Version 2017-05-27"
  (let (p1 p2)
    (save-excursion
      (cond
       ( (eq @unit 'word)
         (let ((wordcharset "-A-Za-z0-9ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ"))
           (skip-chars-backward wordcharset)
           (setq p1 (point))
           (skip-chars-forward wordcharset)
           (setq p2 (point))))

       ( (eq @unit 'glyphs)
         (progn
           (skip-chars-backward "[:graph:]")
           (setq p1 (point))
           (skip-chars-forward "[:graph:]")
           (setq p2 (point))))

       ((eq @unit 'buffer)
        (progn
          (setq p1 (point-min))
          (setq p2 (point-max))))

       ((eq @unit 'line)
        (progn
          (setq p1 (line-beginning-position))
          (setq p2 (line-end-position))))
       ((eq @unit 'block)
        (progn
          (if (re-search-backward "\n[ \t]*\n" nil "move")
              (progn (re-search-forward "\n[ \t]*\n")
                     (setq p1 (point)))
            (setq p1 (point)))
          (if (re-search-forward "\n[ \t]*\n" nil "move")
              (progn (re-search-backward "\n[ \t]*\n")
                     (setq p2 (point)))
            (setq p2 (point)))))

       ((eq @unit 'filepath)
        (let (p0)
          (setq p0 (point))
          ;; chars that are likely to be delimiters of full path, e.g. space, tabs, brakets.
          (skip-chars-backward "^  \"\t\n'|()[]{}<>〔〕“”〈〉《》【】〖〗«»‹›·。\\`")
          (setq p1 (point))
          (goto-char p0)
          (skip-chars-forward "^  \"\t\n'|()[]{}<>〔〕“”〈〉《》【】〖〗«»‹›·。\\'")
          (setq p2 (point))))

       ((eq @unit 'url)
        (let (p0
              ;; ($delimitors "^ \t\n,()[]{}<>〔〕“”\"`'!$^*|\;")
              ($delimitors "!\"#$%&'*+,-./0123456789:;=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~"))
          (setq p0 (point))
          (skip-chars-backward $delimitors) ;"^ \t\n,([{<>〔“\""
          (setq p1 (point))
          (goto-char p0)
          (skip-chars-forward $delimitors) ;"^ \t\n,)]}<>〕\"”"
          (setq p2 (point))))

       ;; • 'filepath-or-url — either file path or URL, with heuristics to detect which sequences of chars to grab. They cannot be distinguished correctly by just lexical form. For example, URL usually contains the colon, but file path not. Sometimes you need this, for example, the value of “href” attribute, which can be just a file path (e.g. relative path) or URL (e.g. http://example.com/)

       ;; ((eq @unit 'filepath-or-url)
       ;;  (let (p0
       ;;        $input
       ;;        (case-fold-search nil)
       ;;        ($delimitors "!\"#$%&'*+,-./0123456789:;=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~"))
       ;;    (setq p0 (point))
       ;;    (skip-chars-backward $delimitors) ;"^ \t\n,([{<>〔“\""
       ;;    (setq p1 (point))
       ;;    (goto-char p0)
       ;;    (skip-chars-forward $delimitors) ;"^ \t\n,)]}<>〕\"”"
       ;;    (setq p2 (point))
       ;;    (setq $input (buffer-substring-no-properties p1 p2))
       ;;    (if (string-match "`http\\|`file" $input &optional START)
       ;;        (progn )
       ;;      (progn ))))

       ((vectorp @unit)
        (let (p0)
          (setq p0 (point))
          (skip-chars-backward (elt @unit 0))
          (setq p1 (point))
          (goto-char p0)
          (skip-chars-forward (elt @unit 1))
          (setq p2 (point))))))

    (cons p1 p2 )))
(defun xah-html-lines-to-table ()
  "Transform the current text block or selection into a HTML table.
If there's a text selection, use the selection as input.
Otherwise, used current text block delimited by empty lines.
@SEPARATOR is a string used as a delimitor for columns.
For example:
a.b.c
1.2.3
with “.” as separator, becomes
<table class=\"nrm\">
<tr><td>a</td><td>b</td><td>c</td></tr>
<tr><td>1</td><td>2</td><td>3</td></tr>
</table>
URL `http://ergoemacs.org/emacs/elisp_make-html-table.html'
Version 2019-06-07"
  (interactive)
  (let ($bds
        $p1 $p2
        $sep        
        ($i 0)
        ($j 0))
    (setq $bds (xah-get-bounds-of-thing-or-region 'block))
    (setq $p1 (car $bds))
    (setq $p2 (cdr $bds))
     (if (string= (read-string "Do you want tab separation " "yes") "yes")
            (setq $sep "\t")
            (setq $sep (read-string "String for column separation:" ","))
       )

     
    (when (equal (length $sep) 0) (user-error "separator cannot be empty."))

    (save-excursion
      (save-restriction
        (narrow-to-region $p1 $p2)
        (let ((case-fold-search nil))

          (goto-char (point-max))
          (insert "\n")

          (goto-char (point-min))
          (while (and
                  (search-forward $sep nil "NOERROR")
                  (< $i 2000))
            (replace-match "</td><td>")
            (1+ $i))

          (goto-char (point-min))
          (while (and
                  (search-forward "\n" nil "NOERROR")
                  (< $j 2000))
            (replace-match "</td></tr>
<tr><td>")
            (1+ $j))

          (goto-char (point-max))
          (beginning-of-line)
          (delete-char 8)

          (goto-char (point-min))
          (insert "<table >
<tr><td>")

          (goto-char (point-max))
          (insert "</table>")
          ;;
          )))))
