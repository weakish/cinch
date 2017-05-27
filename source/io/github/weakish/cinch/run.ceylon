import io.github.weakish.sysexits {
    NotImplementedYetException,
    CommandLineUsageError,
    CanNotCreateFileError,
    SysexitsException
}
import org.apache.commons.cli {
    CommandLineParser,
    DefaultParser,
    Options,
    Option,
    HelpFormatter,
    CommandLine
}
import ceylon.interop.java {
    createJavaStringArray,
    toStringArray
}
import ceylon.file {
    Resource,
    Directory,
    parsePath,
    Nil,
    File,
    Link,
    current,
    Path
}

Directory resolve_directory(String path) {
    Resource location = parsePath(path).resource;
    File|Directory|Nil resolved;
    try {
        resolved = location.linkedResource;
    } catch (Exception e) {
        throw CanNotCreateFileError(
            "``path`` is a link which cannot be fully resolved due to a cycle."
        );
    }
    switch (resolved)
    case (is Directory) {
        return resolved;
    }
    case (is Nil) {
        return resolved.createDirectory();
    }
    case (is File) {
        throw CanNotCreateFileError("``path`` points to a file!");
    }
}

throws (`class CommandLineUsageError`, "given invalid options")
void init_command(String[] arguments) {
    Options options = Options();
    options.addOption("h", "help", false, "show this help message and exit" );


    CommandLineParser parser = DefaultParser();
    CommandLine commandLine;
    try {
        commandLine = parser.parse(
            options,
            createJavaStringArray(process.arguments.rest)
        );
    } catch (ParseException e) {
        throw CommandLineUsageError(e.message);
    }

    Directory verified(String? path) {
        switch (path)
        case (is String) {
            return resolve_directory(path);
        }
        case (is Null) {
            switch (current_directory = current.resource)
            case (is Directory) {
                return current_directory;
            }
            case (is File|Link|Nil) { // current directory removed/replaced
            throw CanNotCreateFileError(
                "Current directory is invalid!
                 Rerun `cinch init <DIRECTORY>` with a valid directory specified.");
            }
        }
    }

    if (commandLine.hasOption("help")) {
        String syntax = "cinch init [<DIRECTORY>]\n\n";
        String header = "Creates the cinch repository at <DIRECTORY>.\n\nOptions:\n";
        String footer = "\nIf <DIRECTORY> is not specified,
                         the repository will be created at the current directory.";
        HelpFormatter helpFormatter = HelpFormatter();
        helpFormatter.printHelp(
            syntax,
            header,
            options,
            footer,
            false
        );

    } else {
        String? repo_path = toStringArray(commandLine.args).first;
        init(verified(repo_path));
    }
}

throws (`class CommandLineUsageError`, "given invalid options")
void add_command(String[] argumests) {
    Option repo = Option.builder("d")
                        .longOpt("repo")
                        .hasArg().argName("directory")
                        .desc("Uses another repository.")
                        .build();
    Option branch = Option.builder("b")
                          .longOpt("branch")
                          .hasArg().argName("label")
                          .desc("Specifies branch name (default: hostname).")
                          .build();
    Option category = Option.builder("n")
                            .longOpt("name")
                            .hasArg().argName("category")
                            .desc("Specifies category (default: uncategorized).")
                            .build();
    Options options = Options();
    for (opt in {repo, branch, category}) {
        options.addOption(opt);
    }
    options.addOption("h", "help", false, "show this help message and exit" );

    CommandLineParser parser = DefaultParser();
    CommandLine commandLine;
    try {
        commandLine = parser.parse(
            options,
            createJavaStringArray(process.arguments.rest)
        );
    } catch (ParseException e) {
        throw CommandLineUsageError(e.message);
    }

    if (commandLine.hasOption("help")) {
        String syntax = "cinch add [-d REPO] [-b BRANCH] [-n CATEGORY] <PATH> ...\n\n";
        String header =
                "Add files and directories (reclusively) to cinch repository.\n\nOptions:\n";
        HelpFormatter helpFormatter = HelpFormatter();
        helpFormatter.printHelp(
            syntax,
            header,
            options,
            "",
            false);

    } else {
        Directory repo_directory;
        if (commandLine.hasOption("repo")) {
            repo_directory = resolve_directory(commandLine.getOptionValue("repo"));
        } else {
            switch (path = read_config())
            case (is String) {
                repo_directory = resolve_directory(path);
            }
            case (is Null) {
                throw CommandLineUsageError(
                    "Cannot find repo!
                     Supply it via `-d <path>` or run `cinch init <path>` before hand."
                );
            }
        }

        String branch_name;
        if (commandLine.hasOption("branch")) {
            branch_name = commandLine.getOptionValue("branch");
        } else {
            branch_name = get_hostname();
        }

        String category_name;
        if (commandLine.hasOption("name")) {
            category_name = commandLine.getOptionValue("name");
        } else {
            category_name = "uncategorized";
        }

        Array<String?> arguments_left = toStringArray(commandLine.args);
        {Path*} paths;
        if (arguments_left.empty) {
            throw CommandLineUsageError("Nothing specified, nothing added.");
        } else {
            paths = { for (path in arguments_left) if (exists path) parsePath(path) };
        }

        add(repo_directory, branch_name, category_name, paths);
    }

}

throws (`class CommandLineUsageError`, "given invalid options")
void import_command(String[] arguments) {
    Option repo = Option.builder("d")
        .longOpt("repo")
        .hasArg().argName("directory")
        .desc("Uses another repository.")
        .build();
    Option category = Option.builder("n")
        .longOpt("name")
        .hasArg().argName("category")
        .desc("Specifies category (default: csv file basename).")
        .build();
    Options options = Options();
    options.addOption(repo);
    options.addOption(category);
    options.addOption("h", "help", false, "show this help message and exit" );

    CommandLineParser parser = DefaultParser();
    CommandLine commandLine;
    try {
        commandLine = parser.parse(
            options,
            createJavaStringArray(process.arguments.rest)
        );
    } catch (ParseException e) {
        throw CommandLineUsageError(e.message);
    }

    if (commandLine.hasOption("help")) {
        String syntax = "cinch import [-d REPO] [-n CATEGORY] <FILE.CSV>\n\n";
        String header =
                "Import file lists from csv to cinch repository.\n\nOptions:\n";
        String footer = "\nFirst row of csv file: `hash,size,name,path`\n
                         Last modification time for imported records will be `-1`";
        HelpFormatter helpFormatter = HelpFormatter();
        helpFormatter.printHelp(
            syntax,
            header,
            options,
            footer,
            false);

    } else {
        Directory repo_directory;
        if (commandLine.hasOption("repo")) {
            repo_directory = resolve_directory(commandLine.getOptionValue("repo"));
        } else {
            switch (path = read_config())
            case (is String) {
                repo_directory = resolve_directory(path);
            }
            case (is Null) {
                throw CommandLineUsageError(
                    "Cannot find repo!
                     Supply it via `-d <path>` or run `cinch init <path>` before hand."
                );
            }
        }
        String category_name;
        if (commandLine.hasOption("name")) {
            category_name = commandLine.getOptionValue("name");
        } else {
            switch (csv_filename = toStringArray(commandLine.args).first)
            case (is String) {
                switch (csv_basename = parsePath(csv_filename).elements.last)
                case (is String) {
                    category_name = csv_basename.replaceLast(".csv", "");
                }
                case (is Null) {
                    throw CommandLineUsageError("``csv_filename`` is invalid!");
                }
            }
            case (is Null) {
                throw CommandLineUsageError("Please specify csv filename to import.");
            }
        }

        switch (csv_filename = toStringArray(commandLine.args).first)
        case (is String) {
            switch (csv_file = parsePath(csv_filename).resource.linkedResource)
            case (is File) {
                import_csv(repo_directory, category_name, csv_file);
            }
            case (is Nil) {
                throw CommandLineUsageError("``csv_filename`` does not exist!");
            }
            case (is Directory) {
                throw CommandLineUsageError("``csv_filename`` points to a directory!");
            }
        }
        case (is Null) {
            throw CommandLineUsageError("Please specify csv filename to import.");
        }
    }
}
"Entry point."
void main() {
    String help_info = "usage: cinch <command> ...

                        Options:

                          -h, --help       show this help message and exit
                          -V, --version    show version number and exit

                        Commands:

                          init             initialize repository
                          add              add files to repository
                          import           import csv file lists
                          help             same as `--help`
                          version          same as `--version`

                        Type `cinch <command> --help` to get help for a specific command.";
    switch (subcommand = process.arguments.first)
    case ("init") {
        init_command(process.arguments.rest);
    }
    case ("add") {
        add_command(process.arguments.rest);
    }
    case ("import") {
        import_command(process.arguments.rest);
    }
    case ("help"|"--help"|"-h") {
        print(help_info);
    }
    case ("version"|"--version"|"-V") {
        print("cinch " + `module io.github.weakish.cinch`.version);
    }
    case (is Null) {
        print(help_info);
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
    } catch (SysexitsException e) {
        process.writeErrorLine(e.message);
        process.exit(e.exit_code);
    }
}
