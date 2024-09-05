import mysql.connector
import sys

def load_keyword_list(filename):
    """Loads a list of keywords from a text file.

    Args:
        filename: The name of the text file.

    Returns:
        A list of keywords.
    """

    with open(filename, "r") as f:
        keywords = [line.strip() for line in f]
    return keywords

def get_database_list(host, user, password):
    """Connects to a remote MySQL server and returns a list of databases.

    Args:
        host: The hostname of the MySQL server.
        user: The username to connect to the MySQL server.
        password: The password to connect to the MySQL server.

    Returns:
        A list of database names.
    """

    try:
        mydb = mysql.connector.connect(
            host=host,
            user=user,
            password=password
        )

        mycursor = mydb.cursor()

        mycursor.execute("SHOW DATABASES")

        databases = [database[0] for database in mycursor.fetchall() if database[0] not in ("information_schema", "performance_schema", "mysql")]

        return databases

    except mysql.connector.Error as e:
        print(f"Error connecting to MySQL server: {e}")
        return []

def get_table_list(host, user, password, database):
    """Connects to a remote MySQL server and returns a list of tables in a given database.

    Args:
        host: The hostname of the MySQL server.
        user: The username to connect to the MySQL server.
        password: The password to connect to the MySQL server.
        database: The name of the database.

    Returns:
        A list of table names.
    """

    try:
        mydb = mysql.connector.connect(
            host=host,
            user=user,
            password=password,
            database=database
        )

        mycursor = mydb.cursor()

        mycursor.execute("SHOW TABLES")

        tables = [table[0] for table in mycursor.fetchall()]

        return tables

    except mysql.connector.Error as e:
        print(f"Error connecting to MySQL server: {e}")
        return []

def get_field_list(host, user, password, database, table, keywords):
    """Connects to a remote MySQL server and returns a list of fields in a given table.

    Args:
        host: The hostname of the MySQL server.
        user: The username to connect to the MySQL server.
        password: The password to connect to the MySQL server.
        database: The name of the database.
        table: The name of the table.
        keywords: A list of keywords to check for PII data.

    Returns:
        A boolean indicating whether PII data is detected.
    """

    try:
        mydb = mysql.connector.connect(
            host=host,
            user=user,
            password=password,
            database=database
        )

        mycursor = mydb.cursor()

        mycursor.execute(f"DESCRIBE {table}")

        fields = [field[0] for field in mycursor.fetchall()]

        for field in fields:
            if any(keyword.lower() in field.lower() for keyword in keywords):
                return True
        return False

    except mysql.connector.Error as e:
        print(f"Error connecting to MySQL server: {e}")
        return False

def get_table_data(host, user, password, database, table):
    """Fetches the first 5 rows of a table.

    Args:
        host: The hostname of the MySQL server.
        user: The username to connect to the MySQL server.
        password: The password to connect to the MySQL server.
        database: The name of the database.
        table: The name of the table.

    Returns:
        A list of tuples representing the rows.
    """

    try:
        mydb = mysql.connector.connect(
            host=host,
            user=user,
            password=password,
            database=database
        )

        mycursor = mydb.cursor()

        mycursor.execute(f"SELECT * FROM {table} LIMIT 5")

        data = mycursor.fetchall()

        return data

    except mysql.connector.Error as e:
        print(f"Error connecting to MySQL server: {e}")
        return []

def format_table_data(data):
    """Formats table data into a tabular format.

    Args:
        data: A list of tuples representing the rows.

    Returns:
        A formatted string representing the table.
    """

    if not data:
        return "No data found."

    header = "\t".join(str(field) for field in data[0])  # Convert field names to strings
    divider = "\t".join(["-" * len(str(field)) for field in data[0]])

    table_str = f"{header}\n{divider}\n"
    for row in data:
        table_str += "\t".join(str(value) for value in row) + "\n"

    return table_str

def print_databases_and_tables(host, user, password, keywords, output_filename):
    """Prints a list of databases and their corresponding tables, indicating whether PII data is detected.

    Args:
        host: The hostname of the MySQL server.
        user: The username to connect to the MySQL server.
        password: The password to connect to the MySQL server.
        keywords: A list of keywords to check for PII data.
        output_filename: The name of the output file.
    """

    databases = get_database_list(host, user, password)

    if databases:
        # Redirect output to a file
        sys.stdout = open(output_filename, "w")

        print("""
        ================================================================
        ||                 PII DATA DETECTOR                 ||
        ================================================================
        """)
        print("List of databases on the server:")
        for database in databases:
            print(f"  - {database}")

        print("\n----------------------------------------------------------------\n")

        for database in databases:
            tables = get_table_list(host, user, password, database)

            if tables:
                print(f"\nTables in {database}:")
                for table in tables:
                    is_pii_data = get_field_list(host, user, password, database, table, keywords)
                    print(f"  - {table}")
                    if is_pii_data:
                        print("    PII data detected!")
                        data = get_table_data(host, user, password, database, table)
                        if data:
                            print("    Table contents:")
                            print(format_table_data(data))
                        else:
                            print("    No data found in the table.")
                        print("\n")
                    else:
                        print("    PII data not detected.")
                        print("\n")
            else:
                print(f"\nNo tables found in {database}")
            print("\n-----------------------------------------------------------------------------------------\n")
                
    else:
        print("Failed to retrieve database list.")

    # Summary
    sys.stdout = sys.stdout  # Restore standard output
    print("\n\n")
    print("******Scan Has Been Completed!!!*********")
    print("\n\n================================================================\n")
    print("||                 SUMMARY                 ||\n")
    print("================================================================\n")
    print(f"Total number of databases: {len(databases)}")
    for database in databases:
        tables_in_database = get_table_list(host, user, password, database)
        tables_with_pii_data = 0
        pii_tables = []
        for table in tables_in_database:
            if get_field_list(host, user, password, database, table, keywords):
                tables_with_pii_data += 1
                pii_tables.append(table)
        print(f"  - {database}:")
        print(f"    Total tables: {len(tables_in_database)}")
        print(f"    Tables with PII data: {tables_with_pii_data}")
        if pii_tables:
            print(f"    PII data detected in tables: {pii_tables}")
        else:
            print(f"    No tables contain PII data")

if __name__ == "__main__":
    host = input("Enter the MySQL server hostname: ")
    user = input("Enter the MySQL username: ")
    password = input("Enter the MySQL password: ")
    keyword_list_file = input("Enter the keyword list file name: ")

    keywords = load_keyword_list(keyword_list_file)

    output_filename = f"{host}_database_pii_detection.txt"
    print_databases_and_tables(host, user, password, keywords, output_filename)
