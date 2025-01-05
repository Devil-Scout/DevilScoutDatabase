#!/bin/sh

ROOT_DIR="$(git rev-parse --show-toplevel)"

# Concatenate all of the DBML files
tmpdbml=$(mktemp '/tmp/combined_dbml.XXXXXX.tmp')
echo -e "Source files:"
for file in $(find "$ROOT_DIR/dbml" -name "*.dbml" | sort); do
  echo "- dbml/$(basename "$file")"
  cat "$file" >> "$tmpdbml"
done

# Create a temporary file to edit the generated SQL
tmpsql=$(mktemp '/tmp/generated_sql.XXXXXX.tmp')

# Add a header
echo -e \
"------------------------------\n"\
"-- THIS IS A GENERATED FILE --\n"\
"--  DO NOT MODIFY BY HAND   --\n"\
"------------------------------\n"\
  >> "$tmpsql"

# Generate the SQL code
echo "Generating SQL..."
SQL="$(dbml2sql "$tmpdbml")"
if echo "$SQL" | grep "dbml-error" >/dev/null; then
  echo "$SQL"
  exit
fi
echo "$SQL" >> "$tmpsql"

# Write the result
output="supabase/migrations/10_generated.sql"
cat "$tmpsql" > "$ROOT_DIR/$output"
echo "Output: $output"
