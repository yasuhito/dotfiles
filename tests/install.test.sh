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
  assert_link ".config/ghostty/config"
  assert_link ".config/hypr/autostart.lua"
  assert_link ".config/hypr/bindings.conf"
  assert_link ".config/hypr/bindings.lua"
  assert_link ".config/hypr/hyprland.lua"
  assert_link ".config/hypr/input.lua"
  assert_link ".config/hypr/looknfeel.lua"
  assert_link ".config/hypr/monitors.lua"
  assert_link ".config/hypr/windows.lua"
  assert_link ".config/mise/config.toml"
  assert_link ".config/wezterm/wezterm.lua"
  assert_link ".config/xdg-terminals.list"
  assert_link ".local/bin/wezterm-xdg-terminal-exec"
  assert_link ".local/share/applications/org.wezfurlong.wezterm.desktop"
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

# A byte-identical regular file is safely adopted as a managed link.
test_home="$temporary_root/identical bindings home"
mkdir -p "$test_home/.config/hypr"
cp "$repo_root/home/.config/hypr/bindings.conf" \
  "$test_home/.config/hypr/bindings.conf"
"$repo_root/install.sh" "$test_home"
assert_installed_payload

# In an isolated XDG environment, the installed preference selects Ghostty by
# its actual desktop entry identifier. The desktop entry below is a deliberately
# simplified behavioral fixture, not a literal copy of the packaged entry: it
# keeps the same desktop ID and X-TerminalArg metadata (including the trailing
# "=" that makes xdg-terminal-exec join option and value into one argument), but
# uses a single-word Exec so the test stays independent of the host's packages.
fake_bin="$temporary_root/fake bin"
ghostty_data="$temporary_root/ghostty data"
mkdir -p "$fake_bin" "$ghostty_data/applications" "$temporary_root/cache"
cat > "$fake_bin/ghostty" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@"
EOF
cat > "$fake_bin/wezterm" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@"
EOF
chmod +x "$fake_bin/ghostty" "$fake_bin/wezterm"
cat > "$ghostty_data/applications/com.mitchellh.ghostty.desktop" <<'EOF'
[Desktop Entry]
Name=Ghostty
Type=Application
TryExec=ghostty
Exec=ghostty
X-TerminalArgExec=-e
X-TerminalArgTitle=--title=
X-TerminalArgAppId=--class=
X-TerminalArgDir=--working-directory=
EOF
xdg_env=(
  env
  "HOME=$test_home"
  "XDG_CONFIG_HOME=$test_home/.config"
  "XDG_DATA_HOME=$test_home/.local/share"
  "XDG_DATA_DIRS=$ghostty_data"
  "XDG_CACHE_HOME=$temporary_root/cache"
  "PATH=$repo_root/tests/fixtures:$fake_bin:$test_home/.local/bin:/usr/bin:/bin"
)
selected_terminal="$("${xdg_env[@]}" xdg-terminal-exec --print-id)"
[ "$selected_terminal" = 'com.mitchellh.ghostty.desktop' ] || \
  fail "xdg-terminal-exec selected $selected_terminal instead of Ghostty"

printed_command="$("${xdg_env[@]}" xdg-terminal-exec --print-cmd \
  --dir='/tmp/project with spaces' --app-id=TUI.float --title='Test title' \
  -e printf '%s' 'command argument')"
expected_command="$(printf '%s\n' \
  ghostty \
  --class=TUI.float \
  --title='Test title' \
  --working-directory='/tmp/project with spaces' \
  -e printf '%s' 'command argument')"
[ "$printed_command" = "$expected_command" ] || \
  fail "xdg-terminal-exec did not preserve Ghostty launch arguments"

wrapped_command="$(PATH="$fake_bin:/usr/bin:/bin" \
  "$test_home/.local/bin/wezterm-xdg-terminal-exec" \
  --class TUI.float --title 'Test title' --cwd '/tmp/project with spaces' \
  -- printf '%s' 'command argument')"
# shellcheck disable=SC2016 # Expansion belongs to the wrapper's child shell.
title_script='printf "\033]0;%s\033\\" "$1"; shift; if (($#)); then exec "$@"; else exec "${SHELL:-/bin/sh}" -l; fi'
expected_wrapped="$(printf '%s\n' \
  start --class TUI.float --cwd '/tmp/project with spaces' \
  -- sh -c "$title_script" wezterm-xdg-terminal-exec 'Test title' \
  printf '%s' 'command argument')"
[ "$wrapped_command" = "$expected_wrapped" ] || \
  fail "WezTerm wrapper did not preserve class, title, directory, and command"

normal_launch="$(PATH="$fake_bin:/usr/bin:/bin" \
  "$test_home/.local/bin/wezterm-xdg-terminal-exec")"
[ "$normal_launch" = 'start' ] || fail "normal WezTerm launch has unexpected arguments"

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

# An unmanaged Ghostty configuration blocks the entire installation and is
# preserved unchanged.
ghostty_conflict_home="$temporary_root/ghostty conflict home"
mkdir -p "$ghostty_conflict_home/.config/ghostty"
printf '%s\n' 'keep my Ghostty config' > \
  "$ghostty_conflict_home/.config/ghostty/config"
if "$repo_root/install.sh" "$ghostty_conflict_home" > \
  "$temporary_root/ghostty-conflict.out" 2>&1; then
  fail "installation unexpectedly overwrote the Ghostty configuration"
fi
[ "$(cat "$ghostty_conflict_home/.config/ghostty/config")" = \
  'keep my Ghostty config' ] || fail "existing Ghostty configuration was changed"
[ ! -e "$ghostty_conflict_home/.config/gh-dash/config.yml" ] || \
  fail "installer made changes before reporting the Ghostty conflict"
grep -q 'refusing to overwrite' "$temporary_root/ghostty-conflict.out" || \
  fail "installer did not explain the Ghostty conflict"

# A different bindings.conf blocks the entire installation and is preserved.
bindings_conflict_home="$temporary_root/bindings conflict home"
mkdir -p "$bindings_conflict_home/.config/hypr"
printf '%s\n' 'keep my bindings' > \
  "$bindings_conflict_home/.config/hypr/bindings.conf"
if "$repo_root/install.sh" "$bindings_conflict_home" > \
  "$temporary_root/bindings-conflict.out" 2>&1; then
  fail "installation unexpectedly overwrote bindings.conf"
fi
[ "$(cat "$bindings_conflict_home/.config/hypr/bindings.conf")" = \
  'keep my bindings' ] || fail "existing bindings.conf was changed"
assert_no_path "$bindings_conflict_home/.config/gh-dash/config.yml"
grep -q 'refusing to overwrite' "$temporary_root/bindings-conflict.out" || \
  fail "installer did not explain the bindings.conf conflict"

# A conflict in a new payload is detected before any other new payload is installed.
new_payload_conflict_home="$temporary_root/new payload conflict home"
mkdir -p "$new_payload_conflict_home/.config/wezterm"
printf '%s\n' 'keep my terminal config' > \
  "$new_payload_conflict_home/.config/wezterm/wezterm.lua"
if "$repo_root/install.sh" "$new_payload_conflict_home" > \
  "$temporary_root/new-payload-conflict.out" 2>&1; then
  fail "installation unexpectedly overwrote the WezTerm configuration"
fi
[ "$(cat "$new_payload_conflict_home/.config/wezterm/wezterm.lua")" = \
  'keep my terminal config' ] || fail "existing WezTerm configuration was changed"
assert_no_path "$new_payload_conflict_home/.config/hypr/hyprland.lua"
grep -q 'refusing to overwrite' "$temporary_root/new-payload-conflict.out" || \
  fail "installer did not explain the WezTerm conflict"

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
