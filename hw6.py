import psycopg2
import csv
import pprint

cursor = None
conn = None


def connect():
    try:
        global conn
        conn = psycopg2.connect("dbname='' user='' host='' password=''")
    except RuntimeError:
        print("Unable to connect to the database")

    global cursor
    cursor = conn.cursor()
    print("Connected to database!")


def upsert(table, vals):
    try:
        if table == "org":
            cursor.callproc("UpsertOrg", vals)

        if table == "meet":
            cursor.callproc("UpsertMeet", vals)

        if table == "participant":
            cursor.callproc("UpsertParticipant", vals)

        if table == "stroke":
            cursor.callproc("UpsertStroke", vals)

        if table == "distance":
            cursor.callproc("UpsertDistance", vals)

        if table == "event":
            cursor.callproc("UpsertEvent", vals)

        if table == "heat":
            cursor.callproc("UpsertHeat", vals)

        if table == "swim":
            cursor.callproc("UpsertSwim", vals)

    except psycopg2.ProgrammingError:
        print("Error when inserting data into table")


def import_from_csv(filename):
    global conn
    try:
        with open(filename, 'r') as csv_file:
            reader = csv.reader(csv_file)
            table = ""
            print("Importing data...")
            for row in reader:
                # Trim list of blank entries.
                row = list(filter(None, row))

                # Detect if it's a table identifier. If so, set the current table to it and continue.
                if row[0][0] == '*':
                    table = row[0].replace("*", "").lower()
                    continue

                # If the table is still blank, we have an error.
                if table == "":
                    print("Table name not found in CSV file")
                    return

                # Call necessary upsert SQL functions.
                upsert(table, row)
                print(row)

            # Commit changes.
            conn.commit()

            # Close file.
            csv_file.close()

    except FileNotFoundError:
        print("No such file in local directory")


def save_data_to_csv(filename):
    with open(filename, "w") as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow([i[0] for i in cursor.description])
        writer.writerows(cursor)
        csv_file.close()


def enter_data_in_table(table_name):
    cursor.callproc("GetColumns", [table_name])
    cols = cursor.fetchall()
    vals = []
    for col in cols:
        val = input("Enter value '{}' of type '{}': ".format(col[0], col[1]))
        vals.append(val)
    upsert(table_name, vals)
    conn.commit()
    print("Row entered in table '{}'!".format(table_name))


def update_row(table_name):
    pass


def display_heat_sheet_for_meet(meet):
    cursor.callproc("MeetHeetSheet", [meet, ])
    cols = cursor.fetchall()
    for col in cols:
        print(col)


def display_heat_sheet_for_swimmer(participant, meet):
    pass


def display_heat_sheet_for_swimmers(school, meet):
    pass


def display_names_for_school_meet(school, meet):
    cursor.callproc("SwimmerNamesSchoolMeetHeetSheet", [school, meet, ])
    cols = cursor.fetchall()
    pprint.pprint(cols)


def display_results_for_event_meet(event, meet):
    pass


def display_scores(meet):
    pass


start = True
connect()
while 1:
    if start:
        print("================================================================================")
        print("Welcome to the HW6 PostgreSQL interface!")
        print("================================================================================")
        print("Available commands: import, save, enter, update, display, help, quit/q/exit\n")
        start = False
    cmdline = input("hw6> ").lower().split(" ")

    if cmdline[0] == "import":
        if len(cmdline) == 2:
            import_from_csv(cmdline[1])
        else:
            print("Usage: import <filename>")

    elif cmdline[0] == "save":
        if len(cmdline) == 2:
            save_data_to_csv(cmdline[1])
        else:
            print("Usage: save <filename>")

    elif cmdline[0] == "enter":
        if len(cmdline) == 2:
            enter_data_in_table(cmdline[1])
        else:
            print("Usage: enter <table name>")

    elif cmdline[0] == "display":
        if len(cmdline) == 2:
            if cmdline[1] == "names":
                meet = input("Enter meet name: ")
                school = input("Enter school ID: ")
                display_names_for_school_meet(school, meet)
            elif cmdline[1] == "meet":
                meet = input("Enter meet: ")
                display_heat_sheet_for_meet(meet)
            elif cmdline[1] == "results":
                event = input("Enter event: ")
                meet = input("Enter meet: ")
                display_results_for_event_meet(event, meet)
            elif cmdline[1] == "scores":
                meet = input("Enter meet: ")
                display_scores(meet)

        else:
            print("Usage: display <meet|results|names|scores>")

    elif cmdline[0] == "help":
        print("Available commands: import, save, enter, update, display, quit/q/exit\n")

    elif cmdline[0] == "q" or cmdline[0] == "quit" or cmdline[0] == "exit":
        print("Exiting...")
        cursor.close()
        conn.close()
        break

    else:
        print("Command not found")
