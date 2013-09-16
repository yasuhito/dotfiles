(setq gnus-select-method
      '(nnimap "Gmail"
               (nnimap-user "yasuhito@gmail.com")
               (nnimap-address "localhost")
               (nnimap-stream network)
               (nnimap-authenticator login)))

(add-to-list 'gnus-secondary-select-methods
             '(nnimap "NEC"
                      (nnimap-user "y-takamiya@az.jp.nec.com")
                      (nnimap-address "localhost")
                      (nnimap-stream network)
                      (nnimap-authenticator login)))

;; メール送信の設定

;; with Emacs 23.1, you have to set this explicitly (in MS Windows)
;; otherwise it tries to send through OS associated mail client
(setq message-send-mail-function 'message-send-mail-with-sendmail)
;; we substitute sendmail with msmtp
(setq sendmail-program "/usr/local/bin/msmtp")

;; Choose account label to feed msmtp -a option based on From header
;; in Message buffer; This function must be added to
;; message-send-mail-hook for on-the-fly change of From address before
;; sending message since message-send-mail-hook is processed right
;; before sending message.
;;
;; http://www.emacswiki.org/emacs/GnusMSMTP
;;
(defun cg-feed-msmtp ()
  (if (message-mail-p)
      (save-excursion
        (let* ((from
                (save-restriction
                  (message-narrow-to-headers)
                  (message-fetch-field "from")))
               (account
                (cond
                 ;; I use email address as account label in ~/.msmtprc
                 ((string-match "yasuhito@gmail.com" from) "yasuhito@gmail.com")
                 ((string-match "y-takamiya@az.jp.nec.com" from) "y-takamiya@az.jp.nec.com"))))
          (setq message-sendmail-extra-arguments (list '"-a" account)))))) ; the original form of this script did not have the ' before "a" which causes a very difficult to track bug --frozencemetery

(setq message-sendmail-envelope-from 'header)
(add-hook 'message-send-mail-hook 'cg-feed-msmtp)

(setq gnus-ignored-from-addresses "yasuhito")
