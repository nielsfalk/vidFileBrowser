#!/usr/bin/env bash
# Shared commit-message validation for the rules in agents.md.
# Sourced by the commit-msg and pre-push hooks. Kept compatible with bash 3.2.

rules_fail() {
  printf '%s: %s\n' "${RULES_HOOK_NAME:-hook}" "$1" >&2
  printf 'See agents.md for the commit message format.\n' >&2
  exit 1
}

rules_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# validate_commit_message "<full commit message>"
validate_commit_message() {
  local message subject coauthors count malformed duplicates
  local author_name author_email coauthors_lower

  message="$1"
  subject="$(printf '%s\n' "$message" | head -n 1)"

  # Merge commits have no hand-written message.
  case "$subject" in
    "Merge "*) return 0 ;;
  esac

  if ! printf '%s\n' "$subject" | grep -Eq '^\[T[0-9]+\] [^[:space:]].*'; then
    rules_fail "subject must start with a task number and a summary, e.g. \"[T01] Add the file browser\""
  fi

  if ! printf '%s\n' "$message" | grep -Eqi '^(promts|prompts):[[:space:]]*$'; then
    rules_fail "missing a \"promts:\" section listing the prompt(s) involved"
  fi

  if ! printf '%s\n' "$message" | grep -Eq '^[[:space:]]+-[[:space:]]+[^[:space:]]'; then
    rules_fail "the \"promts:\" section must list at least one prompt as a \" - \" item"
  fi

  coauthors="$(printf '%s\n' "$message" | grep -i '^Co-authored-by:' || true)"
  count="$(printf '%s\n' "$coauthors" | grep -ci '^Co-authored-by:' || true)"
  if [ "${count:-0}" -lt 2 ]; then
    rules_fail "at least two coauthors are required: the agent and the model"
  fi

  malformed="$(printf '%s\n' "$coauthors" | grep -Eiv '^Co-authored-by: [^<>]+ <[^<>[:space:]]+@[^<>[:space:]]+>$' || true)"
  if [ -n "$malformed" ]; then
    rules_fail "coauthors must use the form \"Co-authored-by: Name <email>\""
  fi

  duplicates="$(printf '%s\n' "$coauthors" | sed -E 's/.*<([^>]+)>.*/\1/' | tr '[:upper:]' '[:lower:]' | sort | uniq -d)"
  if [ -n "$duplicates" ]; then
    rules_fail "duplicate coauthor: $(printf '%s' "$duplicates" | tr '\n' ' ')"
  fi

  author_name="$(git config user.name || true)"
  author_email="$(git config user.email || true)"
  coauthors_lower="$(rules_lower "$coauthors")"

  if [ -n "$author_email" ]; then
    if printf '%s\n' "$coauthors_lower" | grep -Fq "<$(rules_lower "$author_email")>"; then
      rules_fail "the commit author must not also be listed as a coauthor"
    fi
  fi
  if [ -n "$author_name" ]; then
    if printf '%s\n' "$coauthors_lower" | grep -Fq "co-authored-by: $(rules_lower "$author_name") <"; then
      rules_fail "the commit author must not also be listed as a coauthor"
    fi
  fi
}
