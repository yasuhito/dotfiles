(defun add-to-load-path (&rest paths)
  (mapc '(lambda (path)
           (add-to-list 'load-path path))
        (mapcar 'expand-file-name paths)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PATH の設定
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; http://sakito.jp/emacs/emacsshell.html#path
;; より下に記述した物が PATH の先頭に追加されます
(dolist (dir (list
              "/usr/local/bin"
              (expand-file-name "~/bin")
              ))
  ;; PATH と exec-path に同じ物を追加します
  (when ;; (and 
         (file-exists-p dir) ;; (not (member dir exec-path)))
    (setenv "PATH" (concat dir ":" (getenv "PATH")))
    (setq exec-path (append (list dir) exec-path))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Solarized
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-to-load-path "~/.emacs.d/yasuhito/color-theme-6.6.0")
(require 'color-theme)

(add-to-load-path "~/play/solarized/emacs-colors-solarized")
(require 'color-theme-solarized)
(color-theme-solarized-dark)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Emacs powerline
;; http://github.com/milkypostman/powerline
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-to-load-path "~/play/powerline")
(require 'powerline)
(powerline-default)


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
      (create-fontset-from-ascii-font "Menlo-14:weight=normal:slant=normal" nil "menlokakugo")
      (set-fontset-font "fontset-menlokakugo"
                        'unicode
                        (font-spec :family "Hiragino Kaku Gothic ProN" :size 16)
                        nil
                        'append)
      (add-to-list 'default-frame-alist '(font . "fontset-menlokakugo"))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; "Effective Emacs" by Steve Yegge
;; http://sites.google.com/site/steveyegge2/effective-emacs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(global-set-key "\C-x\C-m" 'execute-extended-command)
(global-set-key "\C-c\C-m" 'execute-extended-command)

;; Prefer backward-kill-word over Backspace
(global-set-key "\C-w" 'backward-kill-word)
(global-set-key "\C-x\C-k" 'kill-region)
(global-set-key "\C-c\C-k" 'kill-region)

(global-set-key "\C-z" 'scroll-down)
(global-set-key "\C-x\C-w" 'kill-ring-save)
(global-set-key "\C-c\C-w" 'kill-ring-save)
(global-set-key "\C-x<" 'beginning-of-buffer)
(global-set-key "\C-c<" 'beginning-of-buffer)

;; Lose the UI
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(if (fboundp 'menu-bar-mode) (menu-bar-mode -1))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mew
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(autoload 'mew "mew" nil t)
(autoload 'mew-send "mew" nil t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DDSKK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'skk-autoloads)
(global-set-key "\C-x\C-j" 'skk-mode)
(global-set-key "\C-xj" 'skk-auto-fill-mode)
(global-set-key "\C-xt" 'skk-tutorial)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; OrgMode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-cc" 'org-capture)
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cb" 'org-iswitchb)


(setq org-directory "~/Dropbox/org/")
(setq org-agenda-files
      (quote
       ("~/Dropbox/org/ical.org"
        "~/Dropbox/org/twitter.org"
        "~/Dropbox/org/gtd.org"
        "~/Dropbox/org/capture.org")))


;; iCal の生成
;; http://qiita.com/items/0b717ad1d0488b74429d

(require 'org-icalendar)
(defun my-org-export-icalendar ()
  (interactive)
  (org-export-icalendar nil (concat org-directory "ical.org")))
(define-key org-mode-map (kbd "C-c 1") 'my-org-export-icalendar)

;; エクスポート後に yasuhito.info に飛ばす
(add-hook 'org-after-save-iCalendar-file-hook
          (lambda ()
            (shell-command-to-string
             "scp ~/Dropbox/org/ical.ics yasuhito.info:~/")
            (message "Uploading ... [DONE]")))


;; iCal の説明文
(setq org-icalendar-combined-description "OrgModeのスケジュール")
;; カレンダーに適切なタイムゾーンを設定する（google 用には nil が必要）
(setq org-icalendar-timezone nil)
;; DONE になった TODO は出力対象から除外する
(setq org-icalendar-include-todo t)
;; （通常は，<>--<> で区間付き予定をつくる．非改行入力で日付がNoteに入らない）
(setq org-icalendar-use-scheduled '(event-if-todo))
;; DL 付きで終日予定にする：締め切り日（スタンプで時間を指定しないこと）
(setq org-icalendar-use-deadline '(event-if-todo))

(defvar org-capture-ical-file (concat org-directory "ical.org"))


;; カレンダー
(add-to-load-path "~/play/emacs-calfw/")
(require 'calfw)
(require 'calfw-org)


;; 日本の祝日
(add-hook 'calendar-load-hook
          (lambda ()
            (require 'japanese-holidays)
            (setq calendar-holidays
                  (append japanese-holidays local-holidays other-holidays))))


;; キャプチャ関連
(setq org-default-notes-file (concat org-directory "/notes.org"))
(setq org-capture-templates
      (quote
       (("t"
         "独りTwitter"
         entry
         (file "~/Dropbox/org/twitter.org")
         "* %U\n  %?"
         :prepend t
         :unnarrowed t
         :empty-lines 1)
        ("n"
         "新しいタスク"
         entry
         (file "~/Dropbox/org/gtd.org")
         "* TODO %?\n  %i"
         :prepend t
         :empty-lines 1)
        ("c"
         "カレンダー"
         entry
         (file+headline org-capture-ical-file "Schedule")
         "** TODO %?\n\t")         
       ("b"
         "ブックマーク"
         entry
         (file "~/Dropbox/org/capture.org")
         "* %c %u\n  %i%^{Memo}\n"
         :prepend t
         :empty-lines 1)
        )))


;; Chrome とかとの連携
(server-start)
(require 'org-protocol)


;; mobileorg の設定
(setq org-mobile-directory "~/Dropbox/MobileOrg")
(setq org-mobile-inbox-for-pull "~/Dropbox/org/flagged.org")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; スペルチェッカー
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq ispell-program-name "aspell")

