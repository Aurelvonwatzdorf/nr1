#!/usr/bin/env bash
# Richtet Ghidra 12.1.x für REA auf dem Mac ein – mit einem Befehl:
#   ./game/tools/ghidra_einrichten.sh
# Lädt die neueste Ghidra-12.1.x-Version von GitHub nach ~/Tools, gibt sie für
# macOS frei, trägt GHIDRA_INSTALL_DIR in ~/.zprofile ein, installiert bei
# Bedarf Node.js (über Homebrew) und prüft am Ende mit "rea doctor".

set -u
tools_dir="$HOME/Tools"

if [ "$(uname)" != "Darwin" ]; then
	echo "Dieses Skript ist für den Mac gedacht."
	exit 1
fi

echo "== 1. Java prüfen =="
java_major="$(java -version 2>&1 | head -n 1 | sed -E 's/.*version "([0-9]+).*/\1/')"
if [ -z "$java_major" ] || [ "$java_major" -lt 21 ] 2>/dev/null; then
	echo "Java 21 oder neuer fehlt. Bitte Temurin von https://adoptium.net installieren."
	exit 1
fi
echo "Java $java_major – ok"

echo ""
echo "== 2. Neueste Ghidra-12.1-Version suchen =="
releases="$(curl -fsSL "https://api.github.com/repos/NationalSecurityAgency/ghidra/releases?per_page=40")" || {
	echo "GitHub nicht erreichbar. Internet prüfen."
	exit 1
}
asset_url="$(printf '%s' "$releases" | /usr/bin/python3 -c '
import json, sys
for release in json.load(sys.stdin):
    if not release.get("tag_name", "").startswith("Ghidra_12.1"):
        continue
    for asset in release.get("assets", []):
        name = asset.get("name", "")
        if name.startswith("ghidra_12.1") and "PUBLIC" in name and name.endswith(".zip"):
            print(asset["browser_download_url"])
            sys.exit(0)
')"
if [ -z "$asset_url" ]; then
	echo "Keine Ghidra-12.1.x-Version gefunden. Bitte Claude fragen."
	exit 1
fi
echo "Gefunden: $(basename "$asset_url")"

echo ""
echo "== 3. Herunterladen und auspacken (ca. 500 MB, kann dauern) =="
mkdir -p "$tools_dir"
zip_file="$tools_dir/$(basename "$asset_url")"
if [ ! -f "$zip_file" ]; then
	curl -fL --progress-bar -o "$zip_file" "$asset_url" || {
		echo "Download fehlgeschlagen."
		rm -f "$zip_file"
		exit 1
	}
fi
ghidra_name="$(unzip -Z1 "$zip_file" | head -n 1 | cut -d/ -f1)"
ghidra_dir="$tools_dir/$ghidra_name"
if [ ! -d "$ghidra_dir" ]; then
	unzip -q "$zip_file" -d "$tools_dir" || { echo "Auspacken fehlgeschlagen."; exit 1; }
fi
xattr -dr com.apple.quarantine "$ghidra_dir" 2>/dev/null
rm -f "$zip_file"
echo "Ghidra liegt in: $ghidra_dir"

echo ""
echo "== 3b. Decompiler für Apple Silicon bauen =="
# Ghidra liefert den Decompiler nur für Linux/Windows mit. Auf arm64-Macs
# bauen wir ihn aus dem mitgelieferten Quellcode. Das Makefile will Intel
# (x86_64), daher erzwingen wir arm64. Das neueste SDK passt manchmal nicht
# zum Linker, also probieren wir die SDKs von neu nach alt durch.
decomp_os="$ghidra_dir/Ghidra/Features/Decompiler/os/mac_arm_64"
decomp_src="$ghidra_dir/Ghidra/Features/Decompiler/src/decompile/cpp"
if [ "$(uname -m)" = "arm64" ] && [ ! -x "$decomp_os/decompile" ]; then
	if ! xcode-select -p >/dev/null 2>&1; then
		echo "Xcode-Kommandozeilenwerkzeuge fehlen. Bitte 'xcode-select --install' ausführen."
		exit 1
	fi
	built=""
	for sdk in $(ls -d /Library/Developer/CommandLineTools/SDKs/MacOSX[0-9]*.sdk 2>/dev/null | sort -V -r); do
		echo "Versuche SDK $(basename "$sdk") …"
		(
			cd "$decomp_src" || exit 1
			rm -rf ghi_opt sla_opt ghidra_opt sleigh_opt
			export SDKROOT="$sdk"
			make -j8 ghidra_opt "ARCH_TYPE=-arch arm64" ADDITIONAL_FLAGS="-mmacosx-version-min=12.0 -w" >/dev/null 2>&1 &&
				make -j8 sleigh_opt "ARCH_TYPE=-arch arm64" ADDITIONAL_FLAGS="-mmacosx-version-min=12.0 -w" >/dev/null 2>&1
		) && { built="yes"; break; }
	done
	if [ -z "$built" ]; then
		echo "Decompiler ließ sich nicht bauen. Bitte Claude fragen."
		exit 1
	fi
	mkdir -p "$decomp_os"
	cp "$decomp_src/ghidra_opt" "$decomp_os/decompile"
	cp "$decomp_src/sleigh_opt" "$decomp_os/sleigh"
	chmod +x "$decomp_os/decompile" "$decomp_os/sleigh"
fi
echo "ok"

echo ""
echo "== 4. Für REA eintragen (~/.zprofile) =="
touch "$HOME/.zprofile"
grep -v "GHIDRA_INSTALL_DIR" "$HOME/.zprofile" > "$HOME/.zprofile.tmp" && mv "$HOME/.zprofile.tmp" "$HOME/.zprofile"
echo "export GHIDRA_INSTALL_DIR=\"$ghidra_dir\"" >> "$HOME/.zprofile"
export GHIDRA_INSTALL_DIR="$ghidra_dir"
echo "ok"

echo ""
echo "== 5. Node.js prüfen =="
if ! command -v node >/dev/null 2>&1; then
	if command -v brew >/dev/null 2>&1; then
		brew install node || { echo "Node.js-Installation fehlgeschlagen."; exit 1; }
	else
		echo "Node.js fehlt und Homebrew auch. Bitte zuerst Homebrew installieren."
		exit 1
	fi
fi
echo "Node $(node -v) – ok"

echo ""
echo "== 6. REA prüft Ghidra =="
npx -y rea-agents@latest doctor --provider ghidra
echo ""
echo "FERTIG. Öffne ein neues Terminal-Fenster (oder: source ~/.zprofile)"
echo "und starte Claude im Terminal neu, damit REA Ghidra benutzt."
