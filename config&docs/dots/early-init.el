;; Early init: runs before package system initializes (Emacs 27+)

;; Reduce GC work during startup; restored in `emacs-startup-hook`.
(defconst my-startup-gc-cons-threshold gc-cons-threshold)
(defconst my-startup-gc-cons-percentage gc-cons-percentage)
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold my-startup-gc-cons-threshold
                  gc-cons-percentage my-startup-gc-cons-percentage)))

;; Use HTTPS MELPA by default
(setq package-archives
      '(("gnu"   . "http://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))

;; Faster startup by preloading package autoloads
(setq package-quickstart t)

;; Some Windows builds have TLS1.3 issues with GnuTLS
(when (and (eq system-type 'windows-nt)
           (boundp 'gnutls-algorithm-priority))
  (setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3"))

;; Signature checks can be flaky on some environments; user prefers disabled
(setq package-check-signature nil)
