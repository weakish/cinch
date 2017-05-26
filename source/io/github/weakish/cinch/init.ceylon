import ceylon.file {
    Path,
    parsePath,
    current,
    Directory,
    Nil,
    File,
    Resource,
    ExistingResource,
    createFileIfNil,
    Link
}
import io.github.weakish.sysexits {
    ConfigurationError,
    CanNotCreateFileError
}
import io.github.weakish.xdg {
    XDG
}
Path repo_path(String? directory = process.arguments[1]) {
    switch (directory)
    case (is String) {
        return parsePath(directory);
    }
    case (is Null) {
        return current;
    }
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
    case (is ExistingResource) {
        process.writeErrorLine("README already exists. Skip creating.");
    }
}

"content: `repo=path_to_repo`"
throws (`class ConfigurationError`, "config file path points to a link or directory")
void write_config_file(Directory config_dir, String repo) {
    Resource config_file = config_dir.childResource("config");
    switch (config_file)
    case (is Nil|File) {
        File file = createFileIfNil(config_file);
        try (writer = file.Overwriter()) {
            writer.writeLine("repo=``repo``");
        }
    }
    case (is Link|Directory) {
        throw ConfigurationError("``config_file`` must not be a link or directory.");
    }
}

"update `~/.config/cinch/config`."
throws (`class CanNotCreateFileError`, "if config directory path points to a link or file")
void update_config(Directory repo) {
    switch (config_directory = XDG("cinch").config.resource)
    case (is Directory) {
        write_config_file(config_directory, repo.path.string);
    }
    case (is Nil) {
        Directory new_directory = config_directory.createDirectory();
        write_config_file(new_directory, repo.path.string);
    }
    case (is Link|File) {
        throw CanNotCreateFileError("``config_directory`` must be a directory.");
    }
}

throws (`class CanNotCreateFileError`, "if repo path points to a link or file")
void init() {
    switch (repo = repo_path().resource)
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

