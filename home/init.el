(defun add-to-load-path (&rest paths)
  (mapc '(lambda (path)
           (add-to-list 'load-path path))
        (mapcar 'expand-file-name paths)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; フォントの設定
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(if (and (eq window-system 'x) (>= emacs-major-version 23))
    (progn
      (set-default-font "DejaVu Sans Mono-11")
      (set-fontset-font "fontset-default"
                        'japanese-jisx0208
                        '("M+1M+IPAG" . "unicode-bmp"))))

(if (eq window-system 'ns)
    (progn
      (create-fontset-from-ascii-font "Menlo-12:weight=normal:slant=normal" nil "menlokakugo")
      (set-fontset-font "fontset-menlokakugo"
                        'unicode
                        (font-spec :family "Hiragino Kaku Gothic ProN" :size 14)
                        nil
                        'append)
      (add-to-list 'default-frame-alist '(font . "fontset-menlokakugo"))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; テーマ
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(load-theme 'solarized-dark t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Emacs powerline
;; http://github.com/milkypostman/powerline
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-to-load-path "~/play/powerline")
(require 'powerline)
(powerline-default)
