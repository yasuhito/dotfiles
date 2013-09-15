;;
;; "Effective Emacs" by Steve Yegge
;; http://sites.google.com/site/steveyegge2/effective-emacs
;;

;; M- を使わない
(global-set-key "\C-x\C-m" 'execute-extended-command)
(global-set-key "\C-c\C-m" 'execute-extended-command)

;; Prefer backward-kill-word over Backspace
(global-set-key "\C-w" 'backward-kill-word)
(global-set-key "\C-x\C-k" 'kill-region)
(global-set-key "\C-c\C-k" 'kill-region)

;; その他、M- をなくすためのキーバインド
(global-set-key "\C-z" 'scroll-down)
(global-set-key "\C-x\C-w" 'kill-ring-save)
(global-set-key "\C-c\C-w" 'kill-ring-save)
(global-set-key "\C-x<" 'beginning-of-buffer)
(global-set-key "\C-c<" 'beginning-of-buffer)

;; Lose the UI
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(if (fboundp 'menu-bar-mode) (menu-bar-mode -1))
