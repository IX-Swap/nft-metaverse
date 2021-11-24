#!/usr/bin/env bash

SCRIPT_DIR=$(cd `dirname "$0"` && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."
SOURCE_REPOSITORY="git@gitlab.titanium.codes:tools/nest-boilerplate.git"
TMP_SOURCE_DIR=$(mktemp -d)
ROOT_FILES=( Dockerfile docker-compose.yml tsconfig.json .prettierrc .prettierignore .dockerignore .gitignore README.md styled.d.ts router.d.ts )
FOLDERS=( bin src public )

source "$SCRIPT_DIR/_helpers.sh"

function _sync_file() {
  sf="$TMP_SOURCE_DIR/$1"
  tf="$PROJECT_ROOT/$1"
  dtf=$(dirname "$tf")

  _info "$1"

  if [ -f "$tf" ]; then
    fdiff=$(diff "$tf" "$sf")
    
    if [ -z "$fdiff" ]; then
      echo "Nothing to update."
      return 0
    fi
    
    git diff --no-index --color-moved=zebra --ignore-all-space --ignore-blank-lines --no-prefix --color=always "$tf" "$sf"

    if _yes_no_prompt "Update $1"; then
      echo "Skip."
      return 0
    fi
  elif _yes_no_prompt "Create $1"; then
    echo "Skip."
    return 0
  fi
 
  if [ ! -d "$dtf" ]; then
    mkdir -p "$dtf" || _fail "Unable to create '$dtf' folder"
  fi

  mv "$sf" "$tf" || _fail "Unable to move file"
  return 1
}

_info "Clonning original sources into '$TMP_SOURCE_DIR'"
git clone --depth 1 "$SOURCE_REPOSITORY" "$TMP_SOURCE_DIR" || _fail "Unable to clone original sources"
cd "$TMP_SOURCE_DIR/" || _fail

_info "Checking root files"
for rfile in "${ROOT_FILES[@]}"
do
  _sync_file "$rfile"
done

_info "Checking folders"
for rfolder in "${FOLDERS[@]}"
do
  rfolder_files=( $(find "$TMP_SOURCE_DIR/$rfolder" -type f -printf "%P\n") )

  for rfolder_file in "${rfolder_files[@]}"
  do
    _sync_file "$rfolder/$rfolder_file"
  done
done

_info "Cleaning up"
rm -rf "$TMP_SOURCE_DIR"
