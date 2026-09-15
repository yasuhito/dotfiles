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

has_conflict=0
while IFS= read -r -d '' tracked_path; do
  relative_path="${tracked_path#home/}"
  source_path="$payload_root/$relative_path"
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
    if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source_path" ]; then
      continue
    fi

    # Links made by the repository's former root-level layout are managed by
    # this project and can be migrated safely.
    legacy_source="$repo_root/$relative_path"
    if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$legacy_source" ]; then
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

while IFS= read -r -d '' tracked_path; do
  relative_path="${tracked_path#home/}"
  source_path="$payload_root/$relative_path"
  destination="$target_home/$relative_path"

  mkdir -p "$(dirname "$destination")"
  if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source_path" ]; then
    continue
  fi
  if [ -L "$destination" ]; then
    rm "$destination" # A preflight-approved legacy managed link.
  fi
  ln -s "$source_path" "$destination"
done < <(tracked_payloads)

echo "Applied dotfiles to $target_home"
