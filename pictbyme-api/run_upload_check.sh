#!/usr/bin/env bash
set -eu
TOKEN="${1:-YOUR_TOKEN}"
FILE_ARG="${2:-}"

echo "=== Starting upload diagnostic ==="
# pick file
if [ -n "$FILE_ARG" ]; then
  FILE="$FILE_ARG"
else
  FILE="$(find . -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -print | head -n1 || true)"
  if [ -z "$FILE" ]; then
    echo "No image found — creating ./test-upload.jpg (100 KB)"
    dd if=/dev/urandom of=./test-upload.jpg bs=1024 count=100 status=none
    FILE=./test-upload.jpg
  fi
fi

echo "Using file: $FILE"
if [ ! -f "$FILE" ]; then
  echo "ERROR: file not found: $FILE"
  exit 2
fi

echo
echo "File info:"
ls -l "$FILE"
stat --printf="Permissions: %A\nSize: %s\n" "$FILE" 2>/dev/null || true

echo
echo "Attempting curl upload (will show verbose):"
curl -v -H "Authorization: Bearer $TOKEN" -F "file=@${FILE}" http://localhost:8001/api/pins/upload || true

echo
echo "---- Laravel log (last 80 lines) ----"
tail -n 80 storage/logs/laravel.log || true

echo
echo "---- PHP upload limits ----"
php -r "echo 'upload_max_filesize=' . ini_get('upload_max_filesize') . PHP_EOL; echo 'post_max_size=' . ini_get('post_max_size') . PHP_EOL;" || true

echo
echo "---- storage/app/public/pins listing ----"
ls -la storage/app/public/pins || echo "(no pins dir or empty)"

echo
echo "=== Diagnostic script finished ==="
