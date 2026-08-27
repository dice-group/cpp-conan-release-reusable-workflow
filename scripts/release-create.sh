#!/usr/bin/env bash
set -euo pipefail

BUMP="${BUMP:?BUMP env var (major|minor|patch) is required}"
REPOREF="${REPOREF:?REPOREF env var is required}"

latest="$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' | sort -V | tail -n1)"
if [ -z "$latest" ]; then
  echo "::error::No existing v*.*.* tag found to bump from."
  exit 1
fi

IFS='.' read -r major minor patch <<< "${latest#v}"
case "$BUMP" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
  *) echo "::error::Unknown bump type: $BUMP"; exit 1 ;;
esac
new="v${major}.${minor}.${patch}"

if git ls-remote --exit-code --tags origin "refs/tags/${new}" >/dev/null 2>&1; then
  echo "::error::Tag ${new} already exists."
  exit 1
fi

echo "Releasing ${latest} -> ${new} (${BUMP})"

# Detach so the pin commit below never becomes part of main's history --
# it only ever exists as the tagged commit, same as the old r/v scheme.
git checkout --detach HEAD

sed -i -E "s#(${REPOREF}/\.github/actions/[A-Za-z0-9_-]+)@main#\1@${new}#g" .github/workflows/*.yml

git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

if ! git diff --quiet; then
  git commit -am "Pin internal actions to ${new}"
fi

git tag "${new}"
git push origin "${new}"
