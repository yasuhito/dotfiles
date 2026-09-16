# 公開リポジトリの安全ルール

このリポジトリでは、追跡されるすべての byte、commit、branch、PR、Git history object が公開情報であるものとして扱う。
`$HOME` からファイルをコピーまたは更新する前に、候補ファイルの全 byte と最終的な staged diff を必ず検査する。
検査では、credential、token、private key、cookie、authentication profile、account identifier、private URL または endpoint、個人またはマシンの identity、hostname、IP address、command history、cache、generated state、hardware blob、絶対 machine path、その他の non-portable value が含まれていないことを確認する。
必要な private value は untracked な local include に置き、その interface だけを secret の例を含めずに文書化する。
公開して安全か確信できない場合は commit 前に停止し、review を依頼する。
secret が公開された場合は直ちに revoke または rotate し、後続 commit での削除では非公開に戻らないことを踏まえて history cleanup を調整する。
公開済み history は安易に rewrite せず、影響と関係者を確認してから処理する。

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
