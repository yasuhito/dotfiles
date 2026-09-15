#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles install test.XXXXXX")"
trap 'rm -rf "$temporary_root"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_link() {
  local relative_path="$1"
  local destination="$test_home/$relative_path"
  local expected="$repo_root/home/$relative_path"
  [ -L "$destination" ] || fail "$destination is not a symlink"
  [ "$(readlink "$destination")" = "$expected" ] || \
    fail "$destination does not point to $expected"
}

assert_no_path() {
  local path="$1"
  if [ -e "$path" ] || [ -L "$path" ]; then
    fail "$path unexpectedly exists"
  fi
}

assert_installed_payload() {
  assert_link "AGENTS.md"
  assert_link ".config/gh-dash/config.yml"
  assert_link ".config/git/config"
  assert_link ".config/mise/config.toml"
}

# A fresh installation supports spaces, preserves machine-local files, and
# does not install either retired tmux payload.
test_home="$temporary_root/home with spaces"
mkdir -p "$test_home/.config/git"
printf '%s\n' '[user]' > "$test_home/.config/git/local"

"$repo_root/install.sh" "$test_home"
assert_installed_payload
assert_no_path "$test_home/.tmux.conf"
assert_no_path "$test_home/.config/tmux/tmux.conf"
[ "$(cat "$test_home/.config/git/local")" = '[user]' ] || \
  fail "machine-local Git configuration was changed"

# Applying an already-applied checkout must be a no-op and succeed.
"$repo_root/install.sh" "$test_home"
assert_installed_payload
assert_no_path "$test_home/.tmux.conf"
assert_no_path "$test_home/.config/tmux/tmux.conf"

# Links to both retired payloads from this checkout are removed.
test_home="$temporary_root/retired links home"
mkdir -p "$test_home/.config/tmux"
ln -s "$repo_root/home/.tmux.conf" "$test_home/.tmux.conf"
ln -s "$repo_root/home/.config/tmux/tmux.conf" \
  "$test_home/.config/tmux/tmux.conf"
"$repo_root/install.sh" "$test_home"
assert_installed_payload
assert_no_path "$test_home/.tmux.conf"
assert_no_path "$test_home/.config/tmux/tmux.conf"

# A link remains managed when it came from a different verified checkout.
old_checkout="$temporary_root/former checkout with spaces"
mkdir -p "$old_checkout/home/.config/tmux" "$old_checkout/.config/git"
printf '%s\n' 'retired' > "$old_checkout/home/.tmux.conf"
printf '%s\n' 'retired' > "$old_checkout/home/.config/tmux/tmux.conf"
printf '%s\n' '[include]' > "$old_checkout/.config/git/config"
git -C "$old_checkout" init -q
origin_url="$(git -C "$repo_root" config --get remote.origin.url)"
[ -n "$origin_url" ] || fail "test checkout has no origin remote"
git -C "$old_checkout" remote add origin "$origin_url"

other_checkout_home="$temporary_root/other checkout home"
mkdir -p "$other_checkout_home/.config/git" "$other_checkout_home/.config/tmux"
ln -s "$old_checkout/.config/git/config" \
  "$other_checkout_home/.config/git/config"
ln -s "$old_checkout/home/.tmux.conf" "$other_checkout_home/.tmux.conf"
ln -s "$old_checkout/home/.config/tmux/tmux.conf" \
  "$other_checkout_home/.config/tmux/tmux.conf"
test_home="$other_checkout_home"
"$repo_root/install.sh" "$test_home"
assert_installed_payload
assert_no_path "$test_home/.tmux.conf"
assert_no_path "$test_home/.config/tmux/tmux.conf"
"$repo_root/install.sh" "$test_home"
assert_installed_payload

# Unrelated regular files, links, and directories at retired paths are not
# owned by the installer and must remain untouched.
test_home="$temporary_root/unrelated retired regular home"
mkdir -p "$test_home/.config/tmux"
printf '%s\n' 'keep me' > "$test_home/.tmux.conf"
printf '%s\n' 'foreign' > "$temporary_root/foreign tmux.conf"
ln -s "$temporary_root/foreign tmux.conf" "$test_home/.config/tmux/tmux.conf"
"$repo_root/install.sh" "$test_home"
assert_installed_payload
[ "$(cat "$test_home/.tmux.conf")" = 'keep me' ] || \
  fail "unrelated regular file at retired path was changed"
[ "$(readlink "$test_home/.config/tmux/tmux.conf")" = \
  "$temporary_root/foreign tmux.conf" ] || \
  fail "unrelated symlink at retired path was changed"

test_home="$temporary_root/unrelated retired directory home"
mkdir -p "$test_home/.tmux.conf" "$test_home/.config/tmux/tmux.conf"
"$repo_root/install.sh" "$test_home"
assert_installed_payload
[ -d "$test_home/.tmux.conf" ] || fail "directory at retired path was changed"
[ -d "$test_home/.config/tmux/tmux.conf" ] || \
  fail "nested directory at retired path was changed"

# A same-shaped retired link without matching repository identity is
# ambiguous and therefore remains untouched.
ambiguous_checkout="$temporary_root/ambiguous checkout"
mkdir -p "$ambiguous_checkout/home"
printf '%s\n' 'ambiguous' > "$ambiguous_checkout/home/.tmux.conf"
git -C "$ambiguous_checkout" init -q
test_home="$temporary_root/ambiguous retired link home"
mkdir -p "$test_home"
ln -s "$ambiguous_checkout/home/.tmux.conf" "$test_home/.tmux.conf"
"$repo_root/install.sh" "$test_home"
assert_installed_payload
[ "$(readlink "$test_home/.tmux.conf")" = \
  "$ambiguous_checkout/home/.tmux.conf" ] || \
  fail "ambiguous retired symlink was changed"

# A same-shaped active link without matching repository identity is unrelated.
foreign_checkout="$temporary_root/unrelated checkout"
mkdir -p "$foreign_checkout/.config/git"
printf '%s\n' 'foreign' > "$foreign_checkout/.config/git/config"
git -C "$foreign_checkout" init -q
git -C "$foreign_checkout" remote add origin \
  'https://example.invalid/someone-else/dotfiles.git'
foreign_home="$temporary_root/foreign link home"
mkdir -p "$foreign_home/.config/git"
ln -s "$foreign_checkout/.config/git/config" "$foreign_home/.config/git/config"
if "$repo_root/install.sh" "$foreign_home" > "$temporary_root/foreign.out" 2>&1; then
  fail "installation unexpectedly replaced an unrelated symlink"
fi
[ "$(readlink "$foreign_home/.config/git/config")" = \
  "$foreign_checkout/.config/git/config" ] || \
  fail "unrelated symlink was changed"
[ ! -e "$foreign_home/.config/gh-dash/config.yml" ] || \
  fail "installer made changes before reporting an unrelated symlink"
grep -q 'refusing to overwrite' "$temporary_root/foreign.out" || \
  fail "installer did not explain the unrelated symlink conflict"

# A conflict must be detected during preflight, before a managed retired link
# is removed or any new link is installed.
conflict_home="$temporary_root/conflicting home"
mkdir -p "$conflict_home/.config/git"
managed_link_before="$repo_root/home/.tmux.conf"
ln -s "$managed_link_before" "$conflict_home/.tmux.conf"
printf '%s\n' 'keep me' > "$conflict_home/.config/git/config"
if "$repo_root/install.sh" "$conflict_home" > "$temporary_root/conflict.out" 2>&1; then
  fail "installation unexpectedly overwrote a conflicting destination"
fi
[ "$(cat "$conflict_home/.config/git/config")" = 'keep me' ] || \
  fail "conflicting file was changed"
[ "$(readlink "$conflict_home/.tmux.conf")" = "$managed_link_before" ] || \
  fail "managed retired link was removed before a conflict was reported"
[ ! -e "$conflict_home/.config/gh-dash/config.yml" ] || \
  fail "installer made changes before reporting a conflict"
grep -q 'refusing to overwrite' "$temporary_root/conflict.out" || \
  fail "installer did not explain the file conflict"

# An existing global agent instruction file is preserved without partial changes.
agents_conflict_home="$temporary_root/agents conflict home"
mkdir -p "$agents_conflict_home"
printf '%s\n' 'keep my instructions' > "$agents_conflict_home/AGENTS.md"
if "$repo_root/install.sh" "$agents_conflict_home" > \
  "$temporary_root/agents-conflict.out" 2>&1; then
  fail "installation unexpectedly overwrote AGENTS.md"
fi
[ "$(cat "$agents_conflict_home/AGENTS.md")" = 'keep my instructions' ] || \
  fail "existing AGENTS.md was changed"
[ ! -e "$agents_conflict_home/.config/gh-dash/config.yml" ] || \
  fail "installer made changes before reporting the AGENTS.md conflict"
grep -q 'refusing to overwrite' "$temporary_root/agents-conflict.out" || \
  fail "installer did not explain the AGENTS.md conflict"

# Symlinked parents are unsafe even when their target is writable.
outside_home="$temporary_root/outside selected home"
unsafe_home="$temporary_root/unsafe parent home"
mkdir -p "$outside_home" "$unsafe_home"
ln -s "$outside_home" "$unsafe_home/.config"
if "$repo_root/install.sh" "$unsafe_home" > "$temporary_root/unsafe.out" 2>&1; then
  fail "installation unexpectedly followed a symlinked parent"
fi
[ ! -e "$outside_home/gh-dash/config.yml" ] || \
  fail "installer wrote outside the selected home"
[ "$(readlink "$unsafe_home/.config")" = "$outside_home" ] || \
  fail "unsafe parent symlink was changed"
grep -q 'destination parent is a symlink' "$temporary_root/unsafe.out" || \
  fail "installer did not explain the unsafe parent conflict"

echo "install tests passed"
