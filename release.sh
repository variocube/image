#!/usr/bin/env bash

die() {
	echo -e >&2 "$@"
	exit 1
}

# Read version from arg
version=$1

# Ensure version in changelog is correct
if [[ -z "$version" ]]
then
  die "Error: No version specified as command line argument.\n\nUsage: $0 <version>"
fi

# Allow to make release only from master
[[ $(git rev-parse --abbrev-ref HEAD) == "main" ]] || die "Error: Release can only be made from main branch."

# Make sure we are up to date
echo -n "git pull... "
git pull

# Make sure there no local changes
[[ $(git status --porcelain) ]] && die "Error: Local changes detected."

# Create and push version tag
git tag "$version"
git push --tags
