import psycopg2
import sys

def load_keyword_list(filename):
    with open(filename, "r") as f:
        keywords = [line.strip() for line in f]
    return keywords

def get_database_list(host, user, password):
    try:
        conn = psycopg2.connect(
            host=host,
            user=user,
            password=password
        )
        cur = conn.cursor()
        cur.execute("SELECT datname FROM pg_database")
        databases = [database[0] for database in cur.fetchall() if database[0] not in ("postgres", "information_schema")]
        return databases
    except psycopg2.Error as e:
        print(f"Error connecting to PostgreSQL server: {e}")
        return []

def get_table_list(host, user, password, database):
    try:
        conn = psycopg2.connect(
            host=host,
            user=user,
            password=password,
            database=database
        )
        cur = conn.cursor()
        cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
        tables = [table[0] for table in cur.fetchall()]
        return tables
    except psycopg2.Error as e:
        print(f"Error connecting to PostgreSQL server: {e}")
        return []

def get_field_list(host, user, password, database, table, keywords):
    try:
        conn = psycopg2.connect(
            host=host,
            user=user,
            password=password,
            database=database
        )
        cur = conn.cursor()
        cur.execute(f"SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = '{table}'")
        fields = [field[0] for field in cur.fetchall()]
        for field in fields:
            if any(keyword.lower() in field.lower() for keyword in keywords):
                return True
        return False
    except psycopg2.Error as e:
        print(f"Error connecting to PostgreSQL server: {e}")
        return False

def get_table_data(host, user, password, database, table):
    try:
        conn = psycopg2.connect(
            host=host,
            user=user,
            password=password,
            database=database
        )
        cur = conn.cursor()
        cur.execute(f"SELECT * FROM {table} LIMIT 5")
        data = cur.fetchall()
        return data
    except psycopg2.Error as e:
        print(f"Error connecting to PostgreSQL server: {e}")
        return []

def format_table_data(data):
    if not data:
        return "No data found."
    header = "\t".join(str(field) for field in data[0])  # Convert field names to strings
    divider = "\t".join(["-" * len(str(field)) for field in data[0]])
    table_str = f"{header}\n{divider}\n"
    for row in data:
        table_str += "\t".join(str(value) for value in row) + "\n"
    return table_str

def print_databases_and_tables(host, user, password, keywords, output_filename):
    databases = get_database_list(host, user, password)

    if databases:
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
    host = input("Enter the PostgreSQL server hostname: ")
    user = input("Enter the PostgreSQL username: ")
    password = input("Enter the PostgreSQL password: ")
    keyword_list_file = input("Enter the keyword list file name: ")

    keywords = load_keyword_list(keyword_list_file)

    output_filename = f"{host}_database_pii_detection.txt"
    print_databases_and_tables(host, user, password, keywords, output_filename)
