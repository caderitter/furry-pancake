Assignment 6 - Application Integration
Cade Ritter - cer8, Emily Lisa - ekl1

To run our code, change the password in the connect() method in hw6.py, then type the following in your shell
(make sure you're in the correct directory).

    BASH$ psql -f hw6.sql
    BASH$ python hw6.py

You can also load our .sql file in any other manner (through Pycharm, PostgreSQL admin, PostgreSQL command line).
A new mini-shell will appear:

    hw6>

Type your commands in here. Typing 'help' will display the help message again.

** Make sure to connect to the DB before doing anything! **


****************** Available commands (GRADER LOOK HERE) ******************


    connect - Connects to the configured database.


    import - Read data from a user-provided filenamein the client’s file system, and add the data
    into the database.


    export - Save all data to a user-provided filename.


    enter - For each table, enter a row of data.


    update - For the Participant, Event, and Org tables, update a row of data, given the primary
    key.


    display - Given a type of result to display (meet|results|names|scores|meetforschool|meetforswimmer), displays data
    from the table. Consult the following for more detail:

    display meet - For a Meet, display a Heat Sheet.

    display meetforswimmer - For a Participant and Meet, display a Heat Sheet limited to just that swimmer,
    including any relays they are in.

    display meetforschool - For a School and Meet, display a Heat Sheet limited to just that School’s swimmers.

    display names - For a School and Meet, display just the names of the competing swimmers.

    display results - For an Event and Meet, display all results sorted by time. Include the heat,
    swimmer(s) name(s), and rank.

    display scores - For a Meet, display the scores of each school, sorted by scores


