#!/bin/bash

set -e

print_theme_list() {
    echo "Available themes in ./themes:"
    for theme in ./themes/*; do
        [ -f "$theme" ] && echo "- $(basename "$theme")"
    done
}

select_theme() {
    print_theme_list
    echo "Which theme do you want to use?"
    read -r -p ">> " selected

    while [ ! -f "./themes/$selected" ]; do
        echo "Error: The theme '$selected' does not exist in ./themes. Try again."
        print_theme_list
        read -r -p ">> " selected
    done

    theme="$selected"
}

app_path="/usr/lib/signal-desktop/resources/app.asar"
if flatpak list | grep -q org.signal.Signal; then
    app_path="$HOME/.local/share/flatpak/app/org.signal.Signal/current/active/files/Signal/resources/app.asar"
fi

if [ ! -f "$app_path" ]; then
    echo "app.asar not found at: $app_path"
    exit 1
fi

temp=$(mktemp -d)

echo "Extracting app.asar..."
asar extract "$app_path" "$temp"

manifest_path="$temp/stylesheets/manifest.css"
themes_path="$temp/stylesheets/themes"

if [ ! -f "$manifest_path" ]; then
    echo "Error: manifest.css not found at $manifest_path"
    rm -r "$temp"
    exit 1
fi
if [ -d "$themes_path" ]; then
    rm -r "$themes_path"
fi
mkdir -p "$themes_path"

select_theme

cp "./themes/$theme" "$themes_path/theme.css"
sed -i "/@import url('.\/themes\//d" "$manifest_path"
sed -i "1i @import url('./themes/theme.css');" "$manifest_path"

echo "Repacking..."
asar pack "$temp" "$app_path"

rm -r "$temp"

echo "theme '${theme}' applied successfully!"
