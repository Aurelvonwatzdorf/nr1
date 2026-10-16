#!/usr/bin/env bash
# Speichert den aktuellen Stand auf GitHub – mit einem Befehl (Mac, Linux, Cloud):
#   ./game/tools/speichern.sh "Was ich gemacht habe"
# Ablauf: Tests → commit → neuesten Stand holen (pull) → falls etwas Neues kam,
# Tests nochmal → push. Ist ein Test rot, wird NICHT gepusht.

set -u
cd "$(dirname "$0")/../.." || exit 1   # in den Ordner nr1/
message="${1:-Zwischenstand $(date '+%d.%m.%Y %H:%M')}"
branch="$(git rev-parse --abbrev-ref HEAD)"
game_branch="claude/youthful-ptolemy-6ekfbs"

if [ "$branch" != "$game_branch" ]; then
	echo "Achtung: Du bist auf dem Branch \"$branch\", nicht auf \"$game_branch\"."
	echo "Wechseln mit: git checkout $game_branch"
	exit 1
fi

echo "== 1. Tests =="
if ! ./game/tools/run_tests.sh; then
	echo ""
	echo "Nicht gespeichert: Erst die Fehler beheben (oder Claude fragen)."
	exit 1
fi

echo ""
echo "== 2. Commit =="
git add -A
if git diff --cached --quiet; then
	echo "Keine neuen Änderungen."
else
	git commit -q -m "$message" && echo "Gespeichert: $message"
fi

echo ""
echo "== 3. Neuesten Stand holen =="
before="$(git rev-parse HEAD)"
if ! git pull --no-rebase --no-edit -q origin "$game_branch"; then
	echo ""
	echo "Konflikt beim Zusammenführen! Nichts wurde hochgeladen."
	echo "Sag Claude: \"Hilf mir, den Git-Konflikt zu lösen.\""
	exit 1
fi
if [ "$(git rev-parse HEAD)" != "$before" ]; then
	echo "Neue Änderungen von der anderen Sitzung geholt. Tests nochmal …"
	if ! ./game/tools/run_tests.sh; then
		echo ""
		echo "Nach dem Zusammenführen ist ein Test rot. Nichts hochgeladen."
		exit 1
	fi
fi

echo ""
echo "== 4. Hochladen =="
if git push -q -u origin "$game_branch"; then
	echo "FERTIG – alles ist auf GitHub."
else
	echo "Hochladen hat nicht geklappt (Internet oder GitHub-Anmeldung prüfen)."
	exit 1
fi
