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
  relative_path="$1"
  destination="$test_home/$relative_path"
  expected="$repo_root/home/$relative_path"
  [ -L "$destination" ] || fail "$destination is not a symlink"
  [ "$(readlink "$destination")" = "$expected" ] || \
    fail "$destination does not point to $expected"
}

# A fresh installation supports spaces and preserves machine-local files.
test_home="$temporary_root/home with spaces"
mkdir -p "$test_home/.config/git"
printf '%s\n' '[user]' > "$test_home/.config/git/local"

"$repo_root/install.sh" "$test_home"
assert_link ".config/gh-dash/config.yml"
assert_link ".config/git/config"
assert_link ".config/mise/config.toml"
assert_link ".config/tmux/tmux.conf"
assert_link ".tmux.conf"
[ "$(cat "$test_home/.config/git/local")" = '[user]' ] || \
  fail "machine-local Git configuration was changed"

# Applying an already-applied checkout must be a no-op and succeed.
"$repo_root/install.sh" "$test_home"
assert_link ".config/git/config"

# Links created by the documented former layout in this checkout are upgraded.
legacy_home="$temporary_root/legacy home"
mkdir -p "$legacy_home"
ln -s "$repo_root/.tmux.conf" "$legacy_home/.tmux.conf"
"$repo_root/install.sh" "$legacy_home"
[ "$(readlink "$legacy_home/.tmux.conf")" = "$repo_root/home/.tmux.conf" ] || \
  fail "legacy managed link from this checkout was not migrated"

# A legacy link remains managed when it came from a different clone location.
old_checkout="$temporary_root/former checkout with spaces"
mkdir -p "$old_checkout/.config/git"
printf '%s\n' '[include]' > "$old_checkout/.config/git/config"
git -C "$old_checkout" init -q
origin_url="$(git -C "$repo_root" config --get remote.origin.url)"
[ -n "$origin_url" ] || fail "test checkout has no origin remote"
git -C "$old_checkout" remote add origin "$origin_url"

other_checkout_home="$temporary_root/other checkout home"
mkdir -p "$other_checkout_home/.config/git"
ln -s "$old_checkout/.config/git/config" "$other_checkout_home/.config/git/config"
"$repo_root/install.sh" "$other_checkout_home"
[ "$(readlink "$other_checkout_home/.config/git/config")" = \
  "$repo_root/home/.config/git/config" ] || \
  fail "legacy managed link from another checkout was not migrated"
"$repo_root/install.sh" "$other_checkout_home"
[ "$(readlink "$other_checkout_home/.config/git/config")" = \
  "$repo_root/home/.config/git/config" ] || \
  fail "migrated installation was not idempotent"

# A same-shaped link without matching repository identity is unrelated.
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
[ ! -e "$foreign_home/.tmux.conf" ] || \
  fail "installer made changes before reporting an unrelated symlink"
grep -q 'refusing to overwrite' "$temporary_root/foreign.out" || \
  fail "installer did not explain the unrelated symlink conflict"

# A conflict must be detected during preflight, before any managed link moves.
conflict_home="$temporary_root/conflicting home"
mkdir -p "$conflict_home/.config/git"
managed_link_before="$repo_root/.tmux.conf"
ln -s "$managed_link_before" "$conflict_home/.tmux.conf"
printf '%s\n' 'keep me' > "$conflict_home/.config/git/config"
if "$repo_root/install.sh" "$conflict_home" > "$temporary_root/conflict.out" 2>&1; then
  fail "installation unexpectedly overwrote a conflicting destination"
fi
[ "$(cat "$conflict_home/.config/git/config")" = 'keep me' ] || \
  fail "conflicting file was changed"
[ "$(readlink "$conflict_home/.tmux.conf")" = "$managed_link_before" ] || \
  fail "managed link was migrated before another conflict was reported"
[ ! -e "$conflict_home/.config/gh-dash/config.yml" ] || \
  fail "installer made changes before reporting a conflict"
grep -q 'refusing to overwrite' "$temporary_root/conflict.out" || \
  fail "installer did not explain the file conflict"

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
