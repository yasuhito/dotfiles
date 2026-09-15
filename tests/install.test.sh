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

# Links created by the documented former layout are upgraded in place.
legacy_home="$temporary_root/legacy home"
mkdir -p "$legacy_home"
ln -s "$repo_root/.tmux.conf" "$legacy_home/.tmux.conf"
"$repo_root/install.sh" "$legacy_home"
[ "$(readlink "$legacy_home/.tmux.conf")" = "$repo_root/home/.tmux.conf" ] || \
  fail "legacy managed link was not migrated"

# A conflict must be detected during preflight, before any payload is applied.
conflict_home="$temporary_root/conflicting home"
mkdir -p "$conflict_home"
printf '%s\n' 'keep me' > "$conflict_home/.tmux.conf"
if "$repo_root/install.sh" "$conflict_home" > "$temporary_root/conflict.out" 2>&1; then
  fail "installation unexpectedly overwrote a conflicting destination"
fi
[ "$(cat "$conflict_home/.tmux.conf")" = 'keep me' ] || \
  fail "conflicting file was changed"
[ ! -e "$conflict_home/.config/gh-dash/config.yml" ] || \
  fail "installer made changes before reporting a conflict"
grep -q 'refusing to overwrite' "$temporary_root/conflict.out" || \
  fail "installer did not explain the conflict"

echo "install tests passed"
