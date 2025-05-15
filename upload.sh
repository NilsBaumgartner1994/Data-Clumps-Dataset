#!/bin/bash

# Maximale Commit-Größe in MB
MAX_COMMIT_SIZE_MB=80
MAX_COMMIT_SIZE_BYTES=$((MAX_COMMIT_SIZE_MB * 1024 * 1024))

# Hole Root-Verzeichnis des Repos
cd "$(git rev-parse --show-toplevel)" || exit 1

# Hole alle unversionierten + geänderten Dateien (nicht gelöscht oder umbenannt)
FILES=$(git status --porcelain | grep '^[ ?]M\|^??' | awk '{print $2}')

if [ -z "$FILES" ]; then
  echo "Keine Dateien zum Committen gefunden."
  exit 0
fi

readarray -t FILE_ARRAY <<<"$FILES"
TOTAL=${#FILE_ARRAY[@]}
echo "📦 $TOTAL Dateien werden verarbeitet..."

i=0
commit_number=1
current_commit_size=0
declare -a TO_COMMIT

while [ $i -lt $TOTAL ]; do
  FILE="${FILE_ARRAY[i]}"

  if [ ! -f "$FILE" ]; then
    echo "⚠️  Datei nicht gefunden oder gelöscht: $FILE"
    ((i++))
    continue
  fi

  FILE_SIZE=$(stat -f%z "$FILE") # macOS-kompatibel; für Linux wäre stat -c%s

  # Prüfen, ob Hinzufügen die Max-Größe überschreiten würde
  if (( current_commit_size + FILE_SIZE > MAX_COMMIT_SIZE_BYTES )); then
    if [ ${#TO_COMMIT[@]} -eq 0 ]; then
      echo "⚠️  Datei $FILE ist alleine zu groß für einen Commit (${FILE_SIZE} Bytes). Wird übersprungen."
      ((i++))
      continue
    fi

    # Commit durchführen
    echo "📝 Commit $commit_number mit $((${#TO_COMMIT[@]})) Dateien (~$((current_commit_size / 1024 / 1024)) MB)"
    git add "${TO_COMMIT[@]}"
    git commit -m "Teil-Commit $commit_number (${#TO_COMMIT[@]} Dateien, ~$(($current_commit_size / 1024 / 1024)) MB)"
    ((commit_number++))

    # Reset für nächste Runde
    TO_COMMIT=()
    current_commit_size=0
    continue
  fi

  TO_COMMIT+=("$FILE")
  current_commit_size=$((current_commit_size + FILE_SIZE))
  ((i++))
done

# Letzten Rest committen
if [ ${#TO_COMMIT[@]} -gt 0 ]; then
  echo "📝 Finaler Commit $commit_number mit ${#TO_COMMIT[@]} Dateien (~$((current_commit_size / 1024 / 1024)) MB)"
  git add "${TO_COMMIT[@]}"
  git commit -m "Teil-Commit $commit_number (${#TO_COMMIT[@]} Dateien, ~$(($current_commit_size / 1024 / 1024)) MB)"
fi

echo "✅ Alle Dateien verarbeitet."
