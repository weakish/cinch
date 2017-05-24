import io.github.weakish.sysexits {
    NotImplementedYetException,
    CanNotCreateFileError,
    ConfigurationError
}
import ceylon.file {
    parsePath,
    current,
    Directory,
    Nil,
    Resource,
    File,
    Link
}
import io.github.weakish.xdg {
    XDG
}



String help_info = """The most frequently used cinch commands are:

                          init    initialize cinch

                      Run `cinch` for a complete command list.
                      Run `cinch command --help` for help on a specific subcommand.
                      """;

String command_list = """Repository setup commands:

                           init    DIRECTORY    initialize cinch repository""";

void init() {
    Resource get_directory() {
        Resource repo;

        switch (directory = process.arguments[1])
        case (is String) {
            repo = parsePath(directory).resource;
        }
        case (is Null) {
            repo = current.resource;
        }

        return repo;
    }

    void create_readme(Directory repo) {
        Resource readme = repo.childResource("README");
        switch (readme)
        case (is Nil) {
            File file = readme.createFile();
            try (writer = file.Overwriter()) {
                writer.writeLine("This is a cinch repository.

                                          https://weakish.github.io/cinch/");
            }
        }
        case (is File|Directory|Link) {
            process.writeErrorLine("README already exist. Skip creating.");
        }
    }

    void update_config(Directory repo) {
        void write_config(Directory config_dir) {
            void write_config_file(File config) {
                try (writer = config.Overwriter()) {
                    writer.writeLine("repo=``repo``");
                }
            }

            Resource config_file = config_dir.childResource("config");
            switch (config_file)
            case (is Nil) {
                File file = config_file.createFile();
                write_config_file(file);
            }
            case (is File) {
                write_config_file(config_file);
            }
            case (is Link|Directory) {
                throw ConfigurationError("``config_file`` must not be a link or directory.");
            }
        }

        switch (config_dir = XDG("cinch").config.resource)
        case (is Directory) {
            write_config(config_dir);
        }
        case (is Nil) {
            Directory new_directory = config_dir.createDirectory();
            write_config(new_directory);
        }
        case (is Link|File) {
            throw CanNotCreateFileError("``config_dir`` must be a directory.");
        }
    }


    switch (repo = get_directory())
    case (is Directory) {
        create_readme(repo);
        update_config(repo);
    }
    case (is Nil) {
        Directory new_directory = repo.createDirectory();
        create_readme(new_directory);
        update_config(new_directory);
    }
    case (is File) {
        throw CanNotCreateFileError("``repo`` already exists but it is not a directory.");
    }
    case (is Link) {
        throw CanNotCreateFileError("``repo`` is a link. Please rerun `cinch init` with its target.");
    }
}

"Entry point."
suppressWarnings("expressionTypeNothing")
void main() {
    switch (subcommand = process.arguments.first)
    case ("init") {
        if (process.namedArgumentPresent("help")) {
            String init_help = """Usage: cinch init DIRECTORY

                                  This command creates the cinch repository at DIRECTORY.
                                  If DIRECTORY is not given, create the cinch repository at the current directory.
                                  """;
            print(init_help);
            process.exit(0);
        } else {
            init();
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
