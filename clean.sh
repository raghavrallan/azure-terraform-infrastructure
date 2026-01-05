#!/usr/bin/env bash

# Removes all local saved state and lock files.

find . -name ".terraform" -exec rm -rf {} \;
find . -name "*.lock.hcl" -delete
find . -name "*.tfstate" -delete

find . -type d ! -path '*/.*' | while read dir; do
  echo "Formatting Terraform files in: $dir"
  (cd "$dir" && terraform fmt)
done