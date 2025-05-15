#!/usr/bin/env bash

# Maximale Commit-Größe in MB
MAX_COMMIT_SIZE_MB=80
MAX_COMMIT_SIZE_BYTES=$((MAX_COMMIT_SIZE_MB * 1024 * 1024))

# Wechsle ins Root-Verzeichnis des Repos
cd "$(git rev-parse --show-toplevel)" || exit 1

# Hole alle neuen oder geänderten Dateien
FILES=$(git status --porcelain | grep '^[ ?]M\|^??' | awk '{print $2}')
if [ -z "$FILES" ]; then
  echo "Keine Dateien zum Committen gefunden."
  exit 0
fi

# Lese Dateien in Array
IFS=$'\n' read -rd '' -a FILE_ARRAY <<<"$FILES"
TOTAL=${#FILE_ARRAY[@]}
echo "📦 $TOTAL Dateien werden verarbeitet..."

# Initialisierung
i=0
commit_number=1
current_commit_size=0
declare -a TO_COMMIT
start_time=$(date +%s)
commits_done=0

while [ $i -lt $TOTAL ]; do
  FILE="${FILE_ARRAY[i]}"

  if [ ! -f "$FILE" ]; then
    echo "⚠️  Datei nicht gefunden oder gelöscht: $FILE"
    ((i++))
    continue
  fi

  FILE_SIZE=$(stat -f%z "$FILE") # macOS-kompatibel

  if (( current_commit_size + FILE_SIZE > MAX_COMMIT_SIZE_BYTES )); then
    if [ ${#TO_COMMIT[@]} -eq 0 ]; then
      echo "⚠️  Datei $FILE ist alleine zu groß für einen Commit (${FILE_SIZE} Bytes). Wird übersprungen."
      ((i++))
      continue
    fi

    echo "📝 Commit $commit_number mit ${#TO_COMMIT[@]} Dateien (~$((current_commit_size / 1024 / 1024)) MB)"
    git add "${TO_COMMIT[@]}"
    git commit -m "Teil-Commit $commit_number (${#TO_COMMIT[@]} Dateien, ~$((current_commit_size / 1024 / 1024)) MB)"
    git push origin master

    ((commits_done++))
    elapsed_time=$(($(date +%s) - start_time))
    avg_time_per_commit=$((elapsed_time / commits_done))
    remaining_files=$((TOTAL - i))
    eta_seconds=$((avg_time_per_commit * remaining_files / (${#TO_COMMIT[@]} + 1) ))
    eta_minutes=$((eta_seconds / 60))

    echo "⏳ Verbleibende Dateien: $remaining_files | ⏱️ ETA: ca. $eta_minutes Minuten"

    ((commit_number++))
    TO_COMMIT=()
    current_commit_size=0
    continue
  fi

  TO_COMMIT+=("$FILE")
  current_commit_size=$((current_commit_size + FILE_SIZE))
  ((i++))
done

# Letzten Rest committen und pushen
if [ ${#TO_COMMIT[@]} -gt 0 ]; then
  echo "📝 Finaler Commit $commit_number mit ${#TO_COMMIT[@]} Dateien (~$((current_commit_size / 1024 / 1024)) MB)"
  git add "${TO_COMMIT[@]}"
  git commit -m "Teil-Commit $commit_number (${#TO_COMMIT[@]} Dateien, ~$((current_commit_size / 1024 / 1024)) MB)"
  git push origin master
fi

echo "✅ Alle Dateien verarbeitet und direkt gepusht."
