#!/bin/zsh

set -u

fail() {
  print -r -- "$1" >&2
  exit 1
}

command -v node >/dev/null 2>&1 || fail "Missing required command: node"
command -v npx >/dev/null 2>&1 || fail "Missing required command: npx"

chrome_roots=(
  "/Applications"
  "${HOME}/Applications"
)

chrome_bundle_names=(
  "Google Chrome Beta.app"
  "Google Chrome.app"
)

chrome_path=""
chrome_channel=""
candidate_notes=()

channel_is_running() {
  local app_name="$1"
  local running_state

  running_state="$(osascript -e "tell application \"${app_name}\" to get running" 2>/dev/null || true)"
  [[ "$running_state" == "true" ]]
}

select_usable_candidate() {
  local bundle_name="$1"
  local root candidate info_plist bundle_executable exec_path version_output major_version

  for root in "${chrome_roots[@]}"; do
    candidate="$root/$bundle_name"
    if [[ ! -d "$candidate" ]]; then
      candidate_notes+=("${candidate}: not installed")
      continue
    fi

    info_plist="$candidate/Contents/Info.plist"
    if [[ ! -r "$info_plist" ]]; then
      candidate_notes+=("${candidate}: missing Info.plist")
      continue
    fi

    bundle_executable=""
    if command -v /usr/libexec/PlistBuddy >/dev/null 2>&1; then
      bundle_executable="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$info_plist" 2>/dev/null || true)"
    fi

    if [[ -z "$bundle_executable" ]]; then
      candidate_notes+=("${candidate}: missing CFBundleExecutable")
      continue
    fi

    exec_path="$candidate/Contents/MacOS/$bundle_executable"
    if [[ ! -x "$exec_path" ]]; then
      candidate_notes+=("${candidate}: executable not found at $exec_path")
      continue
    fi

    version_output="$("$exec_path" --version 2>/dev/null || true)"
    version_string="$(print -r -- "$version_output" | grep -Eo '[0-9]+(\.[0-9]+){3}' | head -n 1)"
    if [[ -z "$version_string" ]]; then
      candidate_notes+=("${candidate}: could not determine version from $exec_path")
      continue
    fi

    major_version="${version_string%%.*}"
    if (( major_version < 144 )); then
      candidate_notes+=("${candidate}: version $version_string is too old")
      continue
    fi

    chrome_path="$exec_path"
    if [[ "$bundle_name" == "Google Chrome Beta.app" ]]; then
      chrome_channel="beta"
    else
      chrome_channel=""
    fi
    return 0
  done

  return 1
}

running_channel_detected=0
for bundle_name in "${chrome_bundle_names[@]}"; do
  if [[ "$bundle_name" == "Google Chrome Beta.app" ]]; then
    app_name="Google Chrome Beta"
  else
    app_name="Google Chrome"
  fi

  if channel_is_running "$app_name"; then
    running_channel_detected=1
    if select_usable_candidate "$bundle_name"; then
      break
    fi
  fi
done

if [[ -z "$chrome_path" ]]; then
  for bundle_name in "${chrome_bundle_names[@]}"; do
    if select_usable_candidate "$bundle_name"; then
      break
    fi
  done
fi

if [[ -z "$chrome_path" ]]; then
  if (( ${#candidate_notes[@]} > 0 )); then
    if (( running_channel_detected )); then
      checked_prefix="Running Chrome session(s) found, but none were usable. Checked:"
    else
      checked_prefix="No usable Chrome installation found. Checked:"
    fi
    checked_notes=""
    for note in "${candidate_notes[@]}"; do
      checked_notes+=$'\n- '"$note"
    done
    fail "${checked_prefix}${checked_notes}"
  fi
  fail "Could not find Google Chrome Beta or Google Chrome"
fi

print -r -- "Chrome path: $chrome_path" >&2
print -r -- "Chrome version: $version_string" >&2
print -r -- "Chrome channel: ${chrome_channel:-stable}" >&2

args=(chrome-devtools-mcp@latest --autoConnect)
if [[ -n "$chrome_channel" ]]; then
  args+=(--channel="$chrome_channel")
fi

exec npx -y "${args[@]}"
