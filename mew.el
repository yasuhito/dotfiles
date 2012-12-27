;;
;; Mew
;;

(autoload 'mew "mew" nil t)
(autoload 'mew-send "mew" nil t)

;; .mew の拡張子を付ける
(setq mew-use-suffix t)
(setq mew-summary-form '(type (5 date) " " (20 from) " " t (50 subj) " | " (0 body)))
(setq mew-use-cached-passwd t)
