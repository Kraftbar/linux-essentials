
(setq org-support-shift-select t)

;; 
(defadvice org-call-for-shift-select (before org-call-for-shift-select-cua activate)
  (if (and cua-mode
           org-support-shift-select
           (not (use-region-p)))
      (cua-set-mark)))

;; set things to nil
(eval-after-load 'org
  (progn
    (define-key org-mode-map (kbd "<C-tab>") nil)))


    ;; no shift or alt with arrows
    ;(define-key org-mode-map (kbd "<S-left>") nil)
    ;(define-key org-mode-map (kbd "<S-right>") nil)
    ;(define-key org-mode-map (kbd "<M-left>") nil)
    ;(define-key org-mode-map (kbd "<M-right>") nil)
    ;; no shift-alt with arrows
    ;(define-key org-mode-map (kbd "<M-S-left>") nil)
    ;(define-key org-mode-map (kbd "<M-S-right>") nil)
    ;(define-key org-mode-map (kbd "C-s-<left>") 'org-metaleft)
    ;(define-key org-mode-map (kbd "C-s-<right>") 'org-metaright)











