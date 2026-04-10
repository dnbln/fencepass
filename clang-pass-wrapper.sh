#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"

detect_llvm_root() {
  local candidates=(
    "${LLVM_INSTALL_DIR:-}"
    "$HOME/llvm-project/build"
    "$SCRIPT_DIR/../llvm-project/build"
    "$SCRIPT_DIR/../llvm-project-22.1.2.src/installation"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    [[ -n "$candidate" ]] || continue
    if [[ -x "$candidate/bin/opt" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  return 1
}

LLVM_ROOT="$(detect_llvm_root)" || {
  echo "clang-pass-wrapper: could not find LLVM root with bin/opt" >&2
  exit 1
}

CLANG_BIN="${CLANG_BIN:-$(command -v clang)}"
OPT_BIN="$LLVM_ROOT/bin/opt"
LLC_BIN="$LLVM_ROOT/bin/llc"
SOURCE_SUBDIR_FILTER="${FENCEPASS_SOURCE_SUBDIR:-}"
SOURCE_SUBDIR_FILTERS="${FENCEPASS_SOURCE_SUBDIRS:-}"

if [[ ! -x "$CLANG_BIN" ]]; then
  echo "clang-pass-wrapper: clang not found" >&2
  exit 1
fi

if [[ ! -x "$LLC_BIN" ]]; then
  echo "clang-pass-wrapper: llc not found at $LLC_BIN" >&2
  exit 1
fi

MODE="${FENCEPASS_MODE:-}"

case "$MODE" in
  baseline)
    PASS_PLUGIN=""
    PASS_NAME=""
    ;;
  tso)
    PASS_PLUGIN="$BUILD_DIR/libFencePass.dylib"
    PASS_NAME="FencePassTSO"
    ;;
  pso)
    PASS_PLUGIN="$BUILD_DIR/libFencePass.dylib"
    PASS_NAME="FencePassPSO"
    ;;
  naive)
    PASS_PLUGIN="$BUILD_DIR/libFencePassBaselineNaive.dylib"
    PASS_NAME="FencePass"
    ;;
  *)
    echo "clang-pass-wrapper: set FENCEPASS_MODE to one of: baseline, tso, pso, naive" >&2
    exit 1
    ;;
esac

if [[ -n "$PASS_PLUGIN" && ! -f "$PASS_PLUGIN" ]]; then
  echo "clang-pass-wrapper: plugin not found at $PASS_PLUGIN" >&2
  exit 1
fi

source_matches_filter() {
  local source_path="$1"
  local filters="$SOURCE_SUBDIR_FILTERS"

  if [[ -n "$SOURCE_SUBDIR_FILTER" ]]; then
    filters="$SOURCE_SUBDIR_FILTER"
  fi

  if [[ -z "$filters" ]]; then
    return 0
  fi

  local filter
  IFS=':' read -r -a filter_list <<< "$filters"
  for filter in "${filter_list[@]}"; do
    [[ -n "$filter" ]] || continue
    if [[ "$source_path" == *"$filter"* ]]; then
      return 0
    fi
  done

  return 1
}

args=("$@")
is_compile=0
src=""
out=""
for ((i = 0; i < ${#args[@]}; ++i)); do
  case "${args[i]}" in
    -c)
      is_compile=1
      ;;
    -o)
      if (( i + 1 < ${#args[@]} )); then
        out="${args[i + 1]}"
      fi
      ;;
    *.c|*.cc|*.cpp|*.cxx|*.C)
      src="${args[i]}"
      ;;
  esac
done

if [[ $is_compile -eq 0 || -z "$src" || -z "$out" ]]; then
  exec "$CLANG_BIN" "$@"
fi

if ! source_matches_filter "$src"; then
  exec "$CLANG_BIN" "$@"
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
raw_ll="$tmp_dir/raw.ll"
patched_ll="$tmp_dir/patched.ll"
llc_opt_level="-O2"

emit_args=()
skip_next=0
for ((i = 0; i < ${#args[@]}; ++i)); do
  if [[ $skip_next -eq 1 ]]; then
    skip_next=0
    continue
  fi

  case "${args[i]}" in
    -O0|-O1|-O2|-O3)
      llc_opt_level="${args[i]}"
      emit_args+=("${args[i]}")
      ;;
    -Ofast)
      llc_opt_level="-O3"
      emit_args+=("${args[i]}")
      ;;
    -Os|-Oz)
      llc_opt_level="-O2"
      emit_args+=("${args[i]}")
      ;;
    -c)
      ;;
    -o)
      skip_next=1
      ;;
    *.c|*.cc|*.cpp|*.cxx|*.C)
      emit_args+=("${args[i]}")
      ;;
    -MMD|-MD)
      ;;
    -MF|-MT|-MQ)
      skip_next=1
      ;;
    *)
      emit_args+=("${args[i]}")
      ;;
  esac
done

"$CLANG_BIN" "${emit_args[@]}" -emit-llvm -S -o "$raw_ll"

if [[ "$MODE" == "baseline" ]]; then
  "$OPT_BIN" "$raw_ll" -S -o "$patched_ll"
else
  "$OPT_BIN" -load-pass-plugin "$PASS_PLUGIN" -passes="$PASS_NAME" "$raw_ll" -S -o "$patched_ll"
fi

exec "$LLC_BIN" "$llc_opt_level" -filetype=obj "$patched_ll" -o "$out"