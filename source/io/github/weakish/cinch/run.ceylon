import io.github.weakish.sysexits {
    NotImplementedYetException
}

suppressWarnings("expressionTypeNothing")
void command_help(String message) {
    print(message);
    process.exit(0);
}

"Entry point."
void main() {
    String help_info = """The most frequently used cinch commands are:

                          init    initialize cinch
                          add     add files to cinch

                          Global options:

                          -d      cinch directory

                          Run `cinch` for a complete command list.
                          Run `cinch command --help` for help on a specific subcommand.
                          """;

    String command_list = """Repository setup commands:

                             init DIRECTORY    initialize cinch repository
                             add  PATH [...]   add files to cinch""";

    switch (subcommand = process.arguments.first)
    case ("init") {
        if (process.namedArgumentPresent("help")) {
            String init = "Usage: cinch init DIRECTORY

                                This command creates the cinch repository at DIRECTORY.
                                If DIRECTORY is not given, create the cinch repository at the current directory.
                                ";
            command_help(init);
        } else {
            init();
        }
    }
    case ("add") {
        if (process.namedArgumentPresent("add")) {
            String add = "Usage: cinch add PATH [...]";
            command_help(add);
        } else {
            add();
        }
    }
    case ("help") {
        print(help_info);
    }
    case ("--help") {
        print(help_info);
    }
    case ("-h") {
        print(help_info);
    }
    case (is Null) {
        print(command_list);
    }
    else {
        throw NotImplementedYetException(subcommand);
    }
}

"Utilimate exception handler."
suppressWarnings("expressionTypeNothing")
shared void run(){
    try {
        main();
    }
    catch (NotImplementedYetException e) {
        process.writeErrorLine(e.message);
        process.exit(e.exit_code);
    }
}
