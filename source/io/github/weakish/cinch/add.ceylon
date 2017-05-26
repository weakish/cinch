import ceylon.process {
    Process,
    createProcess
}
import ceylon.json {
    JsonObject
}
import java.lang {
    System
}
import java.io {
    IOException
}
import ceylon.file {
    current,
    Path,
    File,
    Reader,
    Link,
    parsePath,
    Nil,
    Directory,
    Visitor
}
import io.github.weakish.sysexits {
    ConfigurationError,
    NotImplementedYetException,
    CommandLineUsageError,
    InternalSoftwareError
}
Directory get_repo() {
    if (process.namedArgumentPresent("d")) {
        switch (repo = process.namedArgumentValue("d"))
        case (is String) {
            return resolve_directory(repo);
        }
        case (is Null) {
            throw CommandLineUsageError("Please supply the directory path for `-d`.");
        }
    } else {
        switch (repo = read_config())
        case (is String) {
            return resolve_directory(repo);
        }
        case (is Null) {
            throw CommandLineUsageError(
                "Cannot find repo!
                 Supply it via `-d <path>` or run `cinch init <path>` before hand."
            );
        }
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

{Path+} to_add_paths() {
    {Path+} paths;

    if (nonempty arguments = process.arguments.rest) {
        paths = { for (argument in arguments) parsePath(argument) };
    } else {
        paths = { current };
    }

    return paths;
}

Directory resolve_directory(String path) {
    switch (location = parsePath(path).resource)
    case (is Directory) {
        return location;
    }
    case (is Nil|File|Link) {
        throw ConfigurationError("``path`` directory does not exist!");
    }
}

"Try to get hostname via environment virable.
 If failed, get hostname via running `hostname`."
String get_hostname() {
    String? enviroment_variable;
    if (operatingSystem.name == "windows") {
        enviroment_variable = process.environmentVariableValue("COMPUTERNAME");
    } else if (["linux", "mac", "unix", "other"].contains(operatingSystem.name)) {
        // Bash or derivatives sets the HOSTNAME variable.
        enviroment_variable = process.environmentVariableValue("HOSTNAME");
    } else {
        throw NotImplementedYetException(
            "Support for os ``operatingSystem.name`` is not implemented.");
    }

    switch (enviroment_variable)
    case (is String) {
        return enviroment_variable;
    }
    case (is Null) {
        String host_name;
        Process process = createProcess("hostname");
        if (is Reader reader = process.output) {
            if (is String line = reader.readLine()) {
                host_name = line;
            } else {
                throw InternalSoftwareError("`hostname` has an empty output!");
            }
        } else {
            throw InternalSoftwareError("`hostname` has a wrong output stream!");
        }
        switch (exit_code = process.waitForExit())
        case (0) {
            return host_name;
        } else {
            throw InternalSoftwareError("`hostname` failed with exit code ``exit_code``");
        }
    }
}

"Supplied via `-b` or using hostname."
String get_branch() {
    if (process.namedArgumentPresent("b")) {
        switch (branch = process.environmentVariableValue("b"))
        case (is String) {
            return branch;
        }
        case (is Null) {
            throw CommandLineUsageError("Please supply the branch name for `-b`.");
        }
    } else {
        return get_hostname();
    }
}

"Ignore checksum files and `.cinch`."
Boolean is_ignored(File file) {
    if (file.path.string.endsWith(".md5") ||
    file.path.string.endsWith(".sha") ||
    file.path.string.endsWith(".sha1") ||
    file.path.string.endsWith(".sha256") ||
    file.path.string.endsWith(".sha512")) {

        return true;
    } else if (is String last = file.path.elements.last) {
        if (last == ".cinch") {
            return true;
        } else {
            return false;
        }
    } else {
        return false;
    }
}

String relative_path(File file, String branch) {
    // `.absolutePath.normalizedPath` is equvilent to Java's `getAbsolutePath()`:
    // redundant names such as "." and ".." are removed from the pathname,
    // and symbolic links are resolved.
    String[] path_elements = file.path.absolutePath.normalizedPath.elements;
    assert (nonempty path_elements);
    switch (path_length = path_elements.size)
    case (1|2) {
        return "/".join(path_elements);
    }
    case (3) {
        String? branch_name = path_elements[1];
        assert (is String branch_name);
        if (branch_name == branch) {
            String? file_name = path_elements[2];
            assert (is String file_name);
            return  file_name;
        } else {
            return "/".join(path_elements);
        }
    }
    else {
        String? user_name = path_elements[1];
        assert (is String user_name);
        if (user_name == System.getProperty("user.name")) {
            String? branch_name = path_elements[2];
            assert (is String branch_name);
            if (branch_name == branch) {
                return "/".join(path_elements[3...]);
            } else {
                return "/".join(path_elements);
            }
        } else if (user_name == branch) {
            return "/".join(path_elements[2...]);
        } else {
            return "/".join(path_elements.rest);
        }
    }
}

void add_file(File file, JsonObject db, String branch) {
    if (!is_ignored(file)) {
        String file_path = relative_path(file, branch);
        switch (result = get_sha256(file))
        case (is String) {
            String sha256 = result;
            switch (record = db.getObjectOrNull(sha256))
            case (is JsonObject) {
                update_record(file, record, branch, file_path);
            }
            case (is Null) {
                insert_record(db, sha256, file, branch, file_path);
            }
        }
        case (is IOException) {
            process.writeErrorLine("IO error on ``file.path``" + result.message);
        }
    }
}

void add_directory(Directory directory, JsonObject db, String branch) {
    object visitor extends Visitor() {
        shared actual void file(File file) => add_file(file, db, branch);
    }
    directory.path.visit(visitor);
}

void add_path(Path path, JsonObject db, String branch) {
    switch (file = path.resource)
    case (is File) {
        add_file(file, db, branch);
    }
    case (is Directory) {
        add_directory(file, db, branch);
    }
    case (is Link) {
        process.writeErrorLine("``path`` is a link. Skip it.");
    }
    case (is Nil) {
        throw CommandLineUsageError("``path`` does not exist!");
    }
}

void add() {
    File db_file = get_db();
    JsonObject db = import_json(db_file);
    String branch = get_branch();

    for (path in to_add_paths()) {
        add_path(path, db, branch);
    }
    try (writer = db_file.Overwriter()) {
        writer.write(db.string);
    }
}