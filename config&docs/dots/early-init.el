;; Early init: runs before package system initializes (Emacs 27+)

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

