#!/bin/bash

cd /home/ignacio/Personal/Projects/DevOps/githubActionsTerraformDocker

# Rename .new files to remove extension
for file in docs/*.new; do
  if [ -f "$file" ]; then
    mv "$file" "${file%.new}"
    echo "Renamed: $file → ${file%.new}"
  fi
done

# Remove old files
rm -f docs/README.md

# List docs
echo "Files in docs/:"
ls -la docs/

# Git operations
git add docs/ test-aws-endpoints.sh
git status
git commit -m "Replace AI-generated docs with accurate Python/FastAPI documentation and add AWS test script"
git push origin main

echo "✅ Done!"
