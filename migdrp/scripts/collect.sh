#!/bin/bash

# --- Configuration ---
SINGLE_OUTPUT_FILE="file.codebase.md"
TARGET_DIRS=(
  "runpod-video-wan"
  "runpod-comfyui"
  "runpod-fluxgym"
  "runpod-basic"
  "docs"
) # Puedes añadir "server" aquí si existe y lo necesitas

# --- Directories to Exclude ---
EXCLUDE_DIRS=(
    "node_modules" "dist" "build" "bin" ".git" ".vscode" ".idea" "__pycache__"
)

# --- File Extensions to Include ---
INCLUDE_EXTENSIONS=(
    "*.py" "*.html" "*.ts" "*.scss" "*.css" "*.js" "*.md" "*.txt" "*.json" "*.xml" "*"
)

# --- Script Logic ---
echo "Mode: Single file output to '$SINGLE_OUTPUT_FILE'"
> "$SINGLE_OUTPUT_FILE"

for target_dir in "${TARGET_DIRS[@]}"; do
    echo "Processing directory: '$target_dir'..."

    if [ ! -d "$target_dir" ]; then
        echo "Warning: Directory '$target_dir' not found. Skipping."
        continue
    fi

    # Build the 'find' command in an array, WITHOUT escaping parentheses
    find_cmd=("find" "$target_dir")

    # Add exclusions: ( -path '*/dir1' -o -path '*/dir2' ) -prune -o
    if [ ${#EXCLUDE_DIRS[@]} -gt 0 ]; then
        find_cmd+=("(") # NO backslash
        first=true
        for dir in "${EXCLUDE_DIRS[@]}"; do
            [ "$first" = false ] && find_cmd+=("-o")
            find_cmd+=("-path" "*/$dir")
            first=false
        done
        find_cmd+=(")" "-prune" "-o") # NO backslash
    fi

    # Add inclusions: ( -type f -a ( -name '*.ext1' -o -name '*.ext2' ) )
    find_cmd+=("(") # NO backslash
    find_cmd+=("-type" "f")
    if [ ${#INCLUDE_EXTENSIONS[@]} -gt 0 ]; then
        find_cmd+=("-a" "(") # NO backslash
        first=true
        for ext in "${INCLUDE_EXTENSIONS[@]}"; do
            [ "$first" = false ] && find_cmd+=("-o")
            find_cmd+=("-name" "$ext")
            first=false
        done
        find_cmd+=(")") # NO backslash
    fi
    find_cmd+=(")" "-print") # NO backslash

    # DEBUG: Print the exact command that will be executed
    echo "DEBUG: Running command ->" >&2
    printf "%q " "${find_cmd[@]}" >&2 # Use printf %q for unambiguous output
    echo "" >&2 # Newline after debug output

    # Execute the find command
    "${find_cmd[@]}" | while IFS= read -r file; do
        extension="${file##*.}"
        echo -e "\n## 📄 $file\n" >> "$SINGLE_OUTPUT_FILE"
        case $extension in
            md)
                echo '<!-- START OF MARKDOWN CONTENT -->' >> "$SINGLE_OUTPUT_FILE"
                sed 's/#/\\#/g' "$file" >> "$SINGLE_OUTPUT_FILE"
                echo -e '\n<!-- END OF MARKDOWN CONTENT -->\n' >> "$SINGLE_OUTPUT_FILE"
                ;;
            py|html|ts|scss|css|js|json|xml)
                lang=$extension
                [[ "$lang" == "ts" ]] && lang="typescript"
                [[ "$lang" == "js" ]] && lang="javascript"
                echo '```'"$lang" >> "$SINGLE_OUTPUT_FILE"
                cat "$file" >> "$SINGLE_OUTPUT_FILE"
                echo -e '\n```\n' >> "$SINGLE_OUTPUT_FILE"
                ;;
            *)
                echo '```' >> "$SINGLE_OUTPUT_FILE"
                cat "$file" >> "$SINGLE_OUTPUT_FILE"
                echo -e '\n```\n' >> "$SINGLE_OUTPUT_FILE"
                ;;
        esac
    done
done

if [ -s "$SINGLE_OUTPUT_FILE" ]; then
    echo "✅ Success! Output file '$SINGLE_OUTPUT_FILE' created and contains data."
else
    echo "❌ Failure! Output file '$SINGLE_OUTPUT_FILE' is empty. Please check the DEBUG output."
fi
