#!/bin/bash

# Load keywords from file
function load_keyword_list {
    local filename=$1
    mapfile -t keywords < "$filename"
    echo "${keywords[@]}"
}

# Get list of databases
function get_database_list {
    local host=$1
    local user=$2
    local password=$3
    PGPASSWORD="$password" psql -h "$host" -U "$user" postgres -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ('postgres', 'template0', 'template1');"
}

# Get list of tables in a database
function get_table_list {
    local host=$1
    local user=$2
    local password=$3
    local database=$4
    PGPASSWORD="$password" psql -h "$host" -U "$user" -d "$database" -t -c "SELECT table_name FROM information_schema.tables WHERE table_schema='public';"
}

# Check for fields with keywords in a table
function get_field_list {
    local host=$1
    local user=$2
    local password=$3
    local database=$4
    local table=$5
    shift 5
    local keywords=("$@")

    fields=$(PGPASSWORD="$password" psql -h "$host" -U "$user" -d "$database" -t -c "SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name='$table';")
    
    for field in $fields; do
        for keyword in "${keywords[@]}"; do
            if [[ "$field" == *"$keyword"* ]]; then
                return 0
            fi
        done
    done
    return 1
}

# Get table fields and data with proper formatting
function get_table_fields_and_data {
    local host=$1
    local user=$2
    local password=$3
    local database=$4
    local table=$5

    # Get table fields
    local fields=$(PGPASSWORD="$password" psql -h "$host" -U "$user" -d "$database" -t -c "SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name='$table';")
    local formatted_fields=$(echo "$fields" | xargs)

    # Get table data
    local data=$(PGPASSWORD="$password" psql -h "$host" -U "$user" -d "$database" -t -c "SELECT * FROM \"$table\" LIMIT 5;")

    # Combine fields and data, format with `column`
    {
        echo -e "$formatted_fields"
        echo -e "$data"
    } | column -t -s $'\t'
}

# Display summary of PII detection results in table format
function display_pii_summary {
    local detected_list=("$@")
    
    echo -e "\nSummary of PII Data Detection:"
    echo "======================================================"
    printf "%-30s | %-15s\n" "Database.Table" "PII Detected?"
    echo "------------------------------------------------------"

    for entry in "${detected_list[@]}"; do
        IFS='|' read -r db_table detected <<< "$entry"
        printf "%-30s | %-15s\n" "$db_table" "$detected"
    done
    echo "======================================================"
}

# Main logic to print database and table information
function print_databases_and_tables {
    local host=$1
    local user=$2
    local password=$3
    local keyword_file=$4
    local output_file="${host}_database_pii_detection.txt"

    keywords=($(load_keyword_list "$keyword_file"))
    databases=$(get_database_list "$host" "$user" "$password")

    declare -a pii_summary_list

    {
        echo -e "\n==============================================================="
        echo "||                 PII DATA DETECTOR                  ||"
        echo "==============================================================="
        echo "List of databases on the server:"
        echo "$databases"
        echo -e "\n----------------------------------------------------------------\n"

        for database in $databases; do
            tables=$(get_table_list "$host" "$user" "$password" "$database")
            echo -e "\nTables in $database:"
            for table in $tables; do
                echo "  - $table"
                if get_field_list "$host" "$user" "$password" "$database" "$table" "${keywords[@]}"; then
                    echo "    PII data detected!"
                    echo "    Table contents with fields:"
                    table_content=$(get_table_fields_and_data "$host" "$user" "$password" "$database" "$table")
                    echo "$table_content"
                    pii_summary_list+=("$database.$table|YES")
                else
                    echo "    PII data not detected."
                    pii_summary_list+=("$database.$table|NO")
                fi
                echo
            done
            echo -e "\n-----------------------------------------------------------------------------------------\n"
        done
    } > "$output_file"

    # Display the summary table
    display_pii_summary "${pii_summary_list[@]}"
}

# Input parameters
read -p "Enter the PostgreSQL server hostname: " host
read -p "Enter the PostgreSQL username: " user
read -sp "Enter the PostgreSQL password: " password
echo
read -p "Enter the keyword list file name: " keyword_file

# Run the script
print_databases_and_tables "$host" "$user" "$password" "$keyword_file"


