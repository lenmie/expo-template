#!/bin/bash

# A script to copy a template directory to a new project directory,
# excluding Git-related files (.git folder, .gitignore files),
# and dynamically replacing project name and slug placeholders in specific files.

# --- Colors for Output ---
NC='\033[0m' # No Color
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'

# --- Script Start ---

# 1. Check for required arguments
if [ "$#" -ne 1 ]; then # Changed to 1 argument: TARGET_DIR
    echo -e "${RED}Usage: $0 <path_to_new_project_destination>${NC}"
    echo -e "Example: $0 ../new-awesome-app"
    exit 1
fi

TARGET_DIR=$1

# 2. Check if the target directory exists or create it
if [ -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}Warning: Target directory '$TARGET_DIR' already exists.${NC}"
    read -p "Do you want to continue and potentially overwrite files? (y/N): " -n 1 -r
    echo # (optional) move to a new line
    if [[ ! $REPLY =~ ^[yY]$ ]]; then
        echo -e "${RED}Operation cancelled.${NC}"
        exit 1
    fi
else
    mkdir -p "$TARGET_DIR" || { echo -e "${RED}Error: Could not create target directory '$TARGET_DIR'${NC}"; exit 1; }
fi

echo -e "${CYAN}Target Directory: ${NC}${TARGET_DIR}"
echo "---"

echo "Copying template contents (excluding git files, android/ and ios/ directories)..."

# 3. Use rsync to copy files from the current directory (source)
# -a: Archive mode (preserves permissions, ownership, etc., and recurses)
# -v: Verbose (shows which files are being copied)
# --exclude: Specifies patterns to exclude from the copy
# The trailing slash on "./" means copy the *contents* of the current directory,
# not the directory itself.
rsync -av \
  --exclude=".git" \
  --exclude=".gitignore" \
  --exclude="android/" \
  --exclude="ios/" \
  --exclude="node_modules/" \
  --exclude="./copy-template.sh" \
  --exclude="./README.md" \
  "./" "$TARGET_DIR/"

# Check if rsync was successful
if [ $? -ne 0 ]; then
    echo -e "\n${RED}❌ An error occurred during the file copy process.${NC}"
    exit 1
fi

echo -e "\n${GREEN}✅ Files copied successfully to '$TARGET_DIR'.${NC}"
echo "---"

# 4. Derive App Name and Slug from the target directory name
BASENAME=$(basename "$TARGET_DIR")

# Generate SLUG: lowercase, replace non-alphanumeric with hyphens, trim leading/trailing hyphens
APP_SLUG=$(echo "$BASENAME" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-+|-+$//g')

# Generate APP_NAME: capitalize first letter of each word (separated by hyphens), then replace hyphens with spaces
# Example: "new-awesome-app" -> "New Awesome App"
APP_NAME=$(echo "$APP_SLUG" | sed -E 's/(^|-)([a-z])/\U\2/g' | tr '-' ' ')

echo -e "${CYAN}Derived App Name:${NC} \"$APP_NAME\""
echo -e "${CYAN}Derived App Slug:${NC} \"$APP_SLUG\""
echo "---"

echo "Replacing placeholders in specific files..."

# Define placeholder strings (YOU MUST USE THESE IN YOUR TEMPLATE FILES!)
# As confirmed, these are for 'app.json' and 'package.json' at the base level.
# 'lenmie-expo-template' will be replaced by the new slug.
# 'com.javiso.lenmieexpotemplate' will be replaced by 'com.javiso.<new-slug>'.
PLACEHOLDER_SLUG_APP_JSON="lenmie-expo-template"
PLACEHOLDER_BUNDLE_ID_PREFIX="com.javiso." # Prefix for bundleIdentifier/package

# List of specific files to search for and replace within
TARGET_FILES=(
    "app.json"
    "package.json"
)

# Use find to locate relevant files and sed to perform replacements
# 'sed -i ''': For macOS compatibility, needs an empty string for the backup suffix.
#             On Linux, 'sed -i' alone would work.
# Using '#' as a delimiter for 's///' to avoid issues with '/' in paths/names.
for file_name in "${TARGET_FILES[@]}"; do
    FILE_PATH="$TARGET_DIR/$file_name"
    if [ -f "$FILE_PATH" ]; then
        echo -e "Processing: ${CYAN}$file_name${NC}"
        # Replace the main slug in app.json and package.json
        # This replaces "lenmie-expo-template" with the new app slug
        sed -i '' -e "s#${PLACEHOLDER_SLUG_APP_JSON}#${APP_SLUG}#g" "$FILE_PATH"

        # Special handling for bundleIdentifier and package in app.json
        # This changes "com.javiso.lenmieexpotemplate" to "com.javiso.newappslug"
        if [ "$file_name" == "app.json" ]; then
            sed -i '' -e "s#${PLACEHOLDER_BUNDLE_ID_PREFIX}${PLACEHOLDER_SLUG_APP_JSON}#${PLACEHOLDER_BUNDLE_ID_PREFIX}${APP_SLUG}#g" "$FILE_PATH"
        fi

        if [ $? -ne 0 ]; then
            echo -e "${YELLOW}Warning: Failed to process file '$file_name'.${NC}"
        fi
    else
        echo -e "${YELLOW}Warning: Expected file '$file_name' not found in target directory. Skipping.${NC}"
    fi
done

# 5. Report the overall result
echo "---"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Placeholders replaced successfully in specified files.${NC}"
    echo -e "\n${GREEN}✨ Template setup complete! ✨${NC}"
    echo -e "Next steps:"
    echo -e "1. Change directory: ${CYAN}cd '$TARGET_DIR'${NC}"
    echo -e "2. Install dependencies: ${CYAN}npm install${NC} or ${CYAN}yarn install${NC}"
    echo -e "3. Initialize a new Git repository: ${CYAN}git init${NC}"
else
    echo -e "\n${RED}❌ An error occurred during the placeholder replacement process. Please check warnings above.${NC}"
    exit 1
fi
