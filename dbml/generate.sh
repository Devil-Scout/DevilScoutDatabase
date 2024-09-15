#!/bin/sh

ROOT_DIR="$(git rev-parse --show-toplevel)"

# Concatenate all of the DBML files
tmpdbml=$(mktemp)
echo -e "Source files:"
for file in $(find "$ROOT_DIR/dbml" -name "*.dbml"); do
  echo "- dbml/$(basename "$file")"
  cat "$file" >> "$tmpdbml"
done

# Create a temporary file to edit the generated SQL
tmpsql=$(mktemp)

# Add a header
echo -e \
"------------------------------\n"\
"-- THIS IS A GENERATED FILE --\n"\
"--  DO NOT MODIFY BY HAND   --\n"\
"------------------------------\n"\
  >> "$tmpsql"

# Generate the SQL code
echo "Generating SQL..."
dbml2sql "$tmpdbml" >> "$tmpsql"

# Apply the patch files
echo "Patches:"
for file in $(find "$ROOT_DIR/dbml" -name "*.patch"); do
  echo "- dbml/$(basename "$file")"
  patch -us "$tmpsql" "$file"
done

# Write the result
output="supabase/migrations/20_generated.sql"
cat "$tmpsql" > "$ROOT_DIR/$output"
echo "Output: $output"
