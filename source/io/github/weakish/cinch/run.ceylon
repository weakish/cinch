import io.github.weakish.sysexits {
    NotImplementedYetException,
    CanNotCreateFileError,
    ConfigurationError,
    CommandLineUsageError,
    DataFormatError
}
import ceylon.file {
    parsePath,
    current,
    Directory,
    Nil,
    Resource,
    File,
    Link,
    Path
}
import ceylon.json {
    JsonObject = Object,
    parse,
    JsonObject
}
import io.github.weakish.xdg {
    XDG
}
import ceylon.collection {
    ArrayList
}



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

void add() {
    {Path+} get_paths() {
        {Path+} paths;

        if (nonempty arguments = process.arguments.rest) {
            paths = { for (argument in arguments) parsePath(argument) };
        } else {
            paths = { current };
        }

        return paths;
    }

    Directory get_repo() {
        if (process.namedArgumentPresent("d")) {
            switch (path = process.namedArgumentValue("d"))
            case (is String) {
                switch (repo = parsePath(path).resource)
                case (is Directory) {
                    return repo;
                }
                case (is Nil|File|Link) {
                    throw ConfigurationError("``repo`` directory does not exist!");
                }
            }
            case (is Null) {
                throw CommandLineUsageError("Please supply the directory path for `-d`.");
            }
        } else {
            Resource current_directory = current.resource;
            assert (is Directory current_directory);
            return current_directory;
        }
    }

    File get_db() {
        String name;
        if (process.namedArgumentPresent("n")) {
            switch (n = process.namedArgumentValue("n"))
            case (is String) {
                name = n;
            }
            case (is Null) {
                throw CommandLineUsageError("Please supply a value for `-n`.");
            }
        } else {
            name = "Uncategorized";
        }

        switch (db = get_repo().childResource(name + ".json"))
        case (is File) {
            return db;
        }
        case (is Nil) {
            return db.createFile();
        }
        case (is Directory|Link) {
            throw ConfigurationError("``name``.json must not be a directory or link.");
        }
    }

    String read_db(File db) {
        value lines = ArrayList<String>();
        try (reader = db.Reader()) {
            while (exists line = reader.readLine()) {
                lines.add(line);
            }
        }
        return "\n".join(lines);
    }

    JsonObject import_json(File db) {
        String json_string = read_db(db);
        if (json_string.empty) {
            return JsonObject {};
        } else {
            switch (json = parse(json_string))
            case (is JsonObject) {
                return json;
            }
            else {
                throw DataFormatError("Syntax of ``db`` is invalid.");
            }
        }
    }

    String get_sha256(File file) {

    }

    void add_file(File file, JsonObject db) {
        String sha256 = get_sha256(file);
        update_db(sha256, file.path.string);
    }

    void add_directory(Directory directory, JsonObject db) {

    }

    void add_path(Path path, JsonObject db) {
        switch (file = path.resource)
        case (is File) {
            add_file(file, db);
        }
        case (is Directory) {
            add_directory(file, db);
        }
        case (is Link) {
            process.writeErrorLine("``path`` is a link. Skip it.");
        }
        case (is Nil) {
            throw CommandLineUsageError("``path`` does not exist!");
        }
    }

    if (isXattrEnabled()) {

    }

    JsonObject db = import_json(get_db());

    for (path in get_paths()) {
        add_path(path, db);
    }
    record();
}

suppressWarnings("expressionTypeNothing")
void command_help(String message) {
    print(message);
    process.exit(0);
}

"Entry point."
void main() {
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
            String add = "Usage: cinch add PATH [...]
                               ";
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
