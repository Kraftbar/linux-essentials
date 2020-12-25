
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
