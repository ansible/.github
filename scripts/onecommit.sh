#!/bin/bash
set -euo pipefail

# gitlab logic
if [ -n "${CI_MERGE_REQUEST_DIFF_BASE_SHA:-}" ]; then
    COMMIT_COUNT=$(git rev-list "$CI_MERGE_REQUEST_DIFF_BASE_SHA...$CI_COMMIT_SHA" --count)
# github logic
elif [ -f "${GITHUB_EVENT_PATH:-}" ]; then
    PR_NUMBER=$(jq -r .pull_request.number "$GITHUB_EVENT_PATH")
    # elif [[ -n "${PR_NUMBER:-}" ]] && [[ -n "${GITHUB_ACTION:-}" ]]; then
    # get the number of commits in the PR
    PR_NUMBER=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
    if [ "$PR_NUMBER" != "null" ]; then
        COMMIT_COUNT=$(gh pr view "$PR_NUMBER" --json commits --jq '.commits | length')
        echo "PR_NUMBER: $PR_NUMBER"
        echo "COMMIT_COUNT: $COMMIT_COUNT"
    else
        echo "No PR number found, skipping onecommit check."
        exit 0
    fi
else
    echo "No GitHub or GitHub CI environment detected, skipping onecommit check."
    exit 0
fi

if [ "$COMMIT_COUNT" -gt 1 ]; then
    echo "Error: The proposed change has more than one commit, squash all commits to allow merge."
    exit 1
fi
