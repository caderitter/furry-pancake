import psycopg2
import csv
import pprint

cursor = None
conn = None


def connect():
    try:
        global conn
        conn = psycopg2.connect("dbname='postgres' user='ricedb' host='localhost' password='whsoo2p9'")
        conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
    except psycopg2.Error:
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

    except psycopg2.Error:
        print("Error when importing from the database")


def save_data_to_csv(filename):
    tables = ['Org', 'Meet', 'Participant', 'Stroke', 'Distance', 'Event', 'Heat', 'Swim']
    try:
        with open(filename, 'w', newline='') as csv_file:
            writer = csv.writer(csv_file)

            for i in range(len(tables)):
                writer.writerow(['*' + tables[i]])
                cursor.callproc("Get{}".format(tables[i]), [])
                writer.writerows(cursor)

            csv_file.close()

        print("Data exported!")

    except FileNotFoundError:
        print("No such file in local directory")

    except psycopg2.Error:
        print("Error when saving to CSV file")


def enter_data_in_table(table_name):
    try:
        cursor.callproc("GetColumns", [table_name])
        cols = cursor.fetchall()
        vals = []
        for col in cols:
            val = input("Enter value '{}' of type '{}': ".format(col[0], col[1]))
            vals.append(val)
        upsert(table_name, vals)
        conn.commit()
        print("Row entered in table '{}'!".format(table_name))

    except psycopg2.Error:
        print("Error when entering data in table '{}'".format(table_name))


def update_row(table_name):
    try:
        if table_name in ["participant", "event", "org"]:
            row_id = input("Enter PK of row: ")
            cursor.callproc("GetColumns", [table_name])
            cols = cursor.fetchall()
            vals = []
            for col in cols:
                if col[0] == 'id':
                    vals.append(row_id)
                else:
                    val = input("Enter value '{}' of type '{}': ".format(col[0], col[1]))
                    vals.append(val)
            upsert(table_name, vals)
            conn.commit()
            print("Value '{}' updated in table '{}'!".format(row_id, table_name))
        else:
            print("Updating rows in '{}' is not supported. You can only update Participant, Event, and Org."
                  .format(table_name))

    except psycopg2.Error:
        print("Error when updating row in table '{}'".format(table_name))


def display_heat_sheet_for_meet(meet):
    cursor.callproc("MeetHeetSheet", [meet])
    cols = cursor.fetchall()
    for col in cols:
        print(col)


def display_heat_sheet_for_swimmer(participant, meet):
    cursor.callproc("ParticipantMeetHeetSheet", [participant, meet])
    cols = cursor.fetchall()
    for col in cols:
        print(col)


def display_heat_sheet_for_school(school, meet):
    cursor.callproc("SchoolMeetHeetSheet", [school, meet])
    cols = cursor.fetchall()
    for col in cols:
        print(col)


def display_names_for_school_meet(school, meet):
    cursor.callproc("SwimmerNamesSchoolMeetHeetSheet", [school, meet])
    cols = cursor.fetchall()
    pprint.pprint(cols)


def display_results_for_event_meet(event, meet):
    cursor.callproc("EventMeetHeetSheet", [event, meet])
    cols = cursor.fetchall()
    for col in cols:
        print(col)


def display_scores(meet):
    cursor.callproc("MeetScores", [meet])
    cols = cursor.fetchall()
    for col in cols:
        print(col)


start = True
connected = False
while 1:
    if start:
        print("================================================================================")
        print("Welcome to the HW6 PostgreSQL interface!")
        print("================================================================================")
        print("Available commands: connect, import, export, enter, update, display, help, quit/q/exit")
        print("Enter 'help' to display this prompt again.")
        start = False
    cmdline = input("hw6> ").lower().split(" ")

    if cmdline[0] == "help":
        if len(cmdline) == 2:
            if cmdline[1] == 'connect':
                print("Connects to the configured database.")
            elif cmdline[1] == 'import':
                print("Given a CSV file formatted in COMP430 style, imports data into the connected database.")
            elif cmdline[1] == 'export':
                print("Given a CSV file present in the local directory, exports data in the database to the CSV.")
            elif cmdline[1] == 'enter':
                print("Given a table name, enters a single row of data in the table.")
            elif cmdline[1] == 'update':
                print("Given an object's primary key in table Participant, Event, or Org, updates the row of data.")
            elif cmdline[1] == 'display':
                print("Given a type of result to display (meet|results|names|scores|meetforschool|meetforswimmer)"
                      ", displays data from the table.")
            elif cmdline[1] == 'help':
                print("Send me a text if you see this so I can say hi: 512-450-4381")
        else:
            print("Available commands: connect, import, export, enter, update, display, help, quit/q/exit")
            print("Type 'help' followed by a command to show details about that command.")
        continue

    elif cmdline[0] == "connect":
        if not connected:
            connect()
            connected = True
            continue
        else:
            print("You are already connected!")

    if connected:
        if cmdline[0] == "import":
            if len(cmdline) == 2:
                import_from_csv(cmdline[1])
            else:
                print("Usage: import <filename>")

        elif cmdline[0] == "export":
            if len(cmdline) == 2:
                save_data_to_csv(cmdline[1])
            else:
                print("Usage: export <filename>")

        elif cmdline[0] == "enter":
            if len(cmdline) == 2:
                enter_data_in_table(cmdline[1])
            else:
                print("Usage: enter <table name>")

        elif cmdline[0] == "update":
            if len(cmdline) == 2:
                update_row(cmdline[1])
            else:
                print("Usage: update <table name>")

        elif cmdline[0] == "display":
            if len(cmdline) == 2:

                if cmdline[1] == "names":
                    meet = input("Enter meet name: ")
                    school = input("Enter school ID: ")
                    display_names_for_school_meet(school, meet)

                elif cmdline[1] == "meet":
                    meet = input("Enter meet name: ")
                    display_heat_sheet_for_meet(meet)

                elif cmdline[1] == "results":
                    meet = input("Enter meet name: ")
                    event = input("Enter event ID: ")
                    display_results_for_event_meet(event, meet)

                elif cmdline[1] == "scores":
                    meet = input("Enter meet name: ")
                    display_scores(meet)

                elif cmdline[1] == "meetforschool":
                    meet = input("Enter meet name: ")
                    school = input("Enter school ID: ")
                    display_heat_sheet_for_school(school, meet)

                elif cmdline[1] == "meetforswimmer":
                    meet = input("Enter meet name: ")
                    swimmer = input("Enter swimmer ID: ")
                    display_heat_sheet_for_swimmer(swimmer, meet)

            else:
                print("Usage: display <meet|results|names|scores|meetforschool|meetforswimmer>")

        elif cmdline[0] == "q" or cmdline[0] == "quit" or cmdline[0] == "exit":
            print("Exiting...")
            break

        elif cmdline[0] == "q" or cmdline[0] == "quit" or cmdline[0] == "exit":
            print("Exiting...")
            cursor.close()
            conn.close()
            break

        else:
            print("Command not found")

    else:
        print("You must connect to the database!")
