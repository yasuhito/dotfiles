#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 HOME_DIRECTORY" >&2
  echo "Apply this repository's home/ payload to an explicitly selected home directory." >&2
}

if [ "$#" -ne 1 ]; then
  usage
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
payload_root="$repo_root/home"

if [ ! -d "$1" ]; then
  echo "error: selected home directory does not exist: $1" >&2
  exit 2
fi
target_home="$(cd "$1" && pwd -P)"

if [ "$target_home" = "/" ]; then
  echo "error: refusing to use / as a home directory" >&2
  exit 2
fi

# Print tracked payload paths only. This prevents an unrelated untracked file in
# home/ from unexpectedly becoming part of an installation.
tracked_payloads() {
  git -C "$repo_root" ls-files -z -- home/
}

# Paths formerly installed by this repository. They are considered only for
# removal and never become installation sources again.
retired_payloads() {
  printf '%s\0' '.tmux.conf' '.config/tmux/tmux.conf'
}

# Compare repository remotes without making checkout location or the common
# GitHub SSH/HTTPS spelling part of the identity.
normalize_remote() {
  local remote_url="$1"
  remote_url="${remote_url%/}"
  remote_url="${remote_url%.git}"

  case "$remote_url" in
    http://*|https://*|ssh://*)
      remote_url="${remote_url#*://}"
      remote_url="${remote_url#*@}"
      ;;
    *@*:*)
      remote_url="${remote_url#*@}"
      remote_url="${remote_url/:/\/}"
      ;;
  esac

  printf '%s\n' "$remote_url"
}

same_repository() {
  local candidate_root="$1"
  local candidate_git_root candidate_config candidate_url candidate_identity
  local current_config current_url

  candidate_git_root="$(git -C "$candidate_root" rev-parse --show-toplevel 2>/dev/null)" || return 1
  candidate_git_root="$(cd "$candidate_git_root" && pwd -P)" || return 1
  [ "$candidate_git_root" = "$candidate_root" ] || return 1

  while IFS= read -r candidate_config; do
    candidate_url="${candidate_config#* }"
    candidate_identity="$(normalize_remote "$candidate_url")"
    while IFS= read -r current_config; do
      current_url="${current_config#* }"
      if [ "$candidate_identity" = "$(normalize_remote "$current_url")" ]; then
        return 0
      fi
    done < <(git -C "$repo_root" config --get-regexp '^remote\..*\.url$' || true)
  done < <(git -C "$candidate_root" config --get-regexp '^remote\..*\.url$' || true)

  return 1
}

# A managed link points at this checkout, or at the corresponding current or
# former-layout path in another checkout of the same repository. The latter is
# verified by Git remote identity rather than by a machine-specific path.
is_managed_link() {
  local destination="$1"
  local relative_path="$2"
  local link_target absolute_target repository_path candidate_root
  [ -L "$destination" ] || return 1

  link_target="$(readlink "$destination")"
  if [ "$link_target" = "$payload_root/$relative_path" ]; then
    return 0
  fi

  case "$link_target" in
    /*) absolute_target="$link_target" ;;
    *) absolute_target="$(dirname "$destination")/$link_target" ;;
  esac

  for repository_path in "home/$relative_path" "$relative_path"; do
    case "$absolute_target" in
      *"/$repository_path") candidate_root="${absolute_target%"/$repository_path"}" ;;
      *) continue ;;
    esac

    [ -n "$candidate_root" ] || continue
    candidate_root="$(cd "$candidate_root" 2>/dev/null && pwd -P)" || continue
    if [ "$candidate_root" = "$repo_root" ] || same_repository "$candidate_root"; then
      return 0
    fi
  done

  return 1
}

has_conflict=0
while IFS= read -r -d '' tracked_path; do
  relative_path="${tracked_path#home/}"
  destination="$target_home/$relative_path"
  parent="$(dirname "$destination")"

  # Refuse symlinked or non-directory parents: following one could place files
  # outside the explicitly selected home directory.
  while [ "$parent" != "$target_home" ]; do
    if [ -L "$parent" ]; then
      echo "conflict: destination parent is a symlink: $parent" >&2
      has_conflict=1
      break
    fi
    if [ -e "$parent" ] && [ ! -d "$parent" ]; then
      echo "conflict: destination parent is not a directory: $parent" >&2
      has_conflict=1
      break
    fi
    parent="$(dirname "$parent")"
  done

  if [ -e "$destination" ] || [ -L "$destination" ]; then
    if is_managed_link "$destination" "$relative_path"; then
      continue
    fi
    if [ -f "$destination" ] && [ ! -L "$destination" ] && \
      cmp -s "$payload_root/$relative_path" "$destination"; then
      continue
    fi

    echo "conflict: refusing to overwrite $destination" >&2
    has_conflict=1
  fi
done < <(tracked_payloads)

if [ "$has_conflict" -ne 0 ]; then
  echo "No changes were made." >&2
  exit 1
fi

# Retire only links that pass the same repository-identity check used for
# migrations. Unsafe parents are ignored so cleanup can never escape the
# explicitly selected home directory.
while IFS= read -r -d '' relative_path; do
  destination="$target_home/$relative_path"
  parent="$(dirname "$destination")"
  unsafe_parent=0

  while [ "$parent" != "$target_home" ]; do
    if [ -L "$parent" ] || { [ -e "$parent" ] && [ ! -d "$parent" ]; }; then
      unsafe_parent=1
      break
    fi
    parent="$(dirname "$parent")"
  done

  if [ "$unsafe_parent" -eq 0 ] && is_managed_link "$destination" "$relative_path"; then
    rm "$destination"
  fi
done < <(retired_payloads)

while IFS= read -r -d '' tracked_path; do
  relative_path="${tracked_path#home/}"
  source_path="$payload_root/$relative_path"
  destination="$target_home/$relative_path"

  mkdir -p "$(dirname "$destination")"
  if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source_path" ]; then
    continue
  fi
  if [ -L "$destination" ] || [ -f "$destination" ]; then
    # Preflight approved either a managed link or a byte-identical regular file.
    rm "$destination"
  fi
  ln -s "$source_path" "$destination"
done < <(tracked_payloads)

echo "Applied dotfiles to $target_home"
