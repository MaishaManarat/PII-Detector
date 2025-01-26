#!/bin/bash

# Load keywords from file
load_keyword_list() {
    local filename=$1
    mapfile -t keywords < "$filename"
    echo "${keywords[@]}"
}

# Get list of databases
get_database_list() {
    local host=$1
    local user=$2
    local password=$3
    mysql -h "$host" -u "$user" -p"$password" -e "SET PASSWORD = PASSWORD('$password'); SHOW DATABASES;" | grep -Ev "(Database|information_schema|mysql|performance_schema|sys)"
}

# Get list of tables in a database
get_table_list() {
    local host=$1
    local user=$2
    local password=$3
    local database=$4
    mysql -h "$host" -u "$user" -p"$password" -D "$database" -e "SET PASSWORD = PASSWORD('$password'); SHOW TABLES;" | grep -v "Tables_in_"
}

# Check for fields with keywords in a table
get_field_list() {
    local host=$1
    local user=$2
    local password=$3
    local database=$4
    local table=$5
    shift 5
    local keywords=("$@")

    fields=$(mysql -h "$host" -u "$user" -p"$password" -D "$database" -e "SET PASSWORD = PASSWORD('$password'); SHOW COLUMNS FROM $table;" | awk '{if(NR>1) print $1}')
    
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
get_table_fields_and_data() {
    local host=$1
    local user=$2
    local password=$3
    local database=$4
    local table=$5

    # Get table fields
    local fields=$(mysql -h "$host" -u "$user" -p"$password" -D "$database" -e "SET PASSWORD = PASSWORD('$password'); SHOW COLUMNS FROM $table;" | awk '{if(NR>1) print $1}')
    local formatted_fields=$(echo "$fields" | xargs)

    # Get table data
    local data=$(mysql -h "$host" -u "$user" -p"$password" -D "$database" -e "SET PASSWORD = PASSWORD('$password'); SELECT * FROM $table LIMIT 5;" -t)

    # Combine fields and data, format with `column`
    {
        echo "$formatted_fields"
        echo "$data"
    } | column -t -s $'\t'
}

# Display summary of PII detection results in table format
display_pii_summary() {
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
print_databases_and_tables() {
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

        # Append the summary table to the output file
        echo -e "\nSummary of PII Data Detection:"
        echo "======================================================"
        printf "%-30s | %-15s\n" "Database.Table" "PII Detected?"
        echo "------------------------------------------------------"
        for entry in "${pii_summary_list[@]}"; do
            IFS='|' read -r db_table detected <<< "$entry"
            printf "%-30s | %-15s\n" "$db_table" "$detected"
        done
        echo "======================================================"
    } > "$output_file"

    # Display the summary table in the terminal
    display_pii_summary "${pii_summary_list[@]}"
}

# Input parameters
read -p "Enter the MySQL server hostname: " host
read -p "Enter the MySQL username: " user
read -sp "Enter the MySQL password: " password
echo
read -p "Enter the keyword list file name: " keyword_file

# Run the script
print_databases_and_tables "$host" "$user" "$password" "$keyword_file"
