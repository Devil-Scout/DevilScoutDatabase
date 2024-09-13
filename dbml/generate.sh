#!/bin/sh

ROOT_DIR="$(git rev-parse --show-toplevel)"

# Concatenate all of the DBML files
tmpdbml=$(mktemp)
sources=$(find "$ROOT_DIR/dbml" -name "*.dbml")
echo -e "Source files:\n$sources"
cat $sources > "$tmpdbml"

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
echo "Generating..."
dbml2sql "$tmpdbml" >> "$tmpsql"

# Apply the patch files
echo "Applying patches..."
for file in $(find "$ROOT_DIR/dbml" -name "*.patch"); do
  patch -us "$tmpsql" "$file"
done

# Write the result
output="$ROOT_DIR/supabase/migrations/50_generated.sql"
cat "$tmpsql" > "$output
echo "Results at $output"
