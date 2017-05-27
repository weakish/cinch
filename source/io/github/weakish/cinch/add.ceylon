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
    Path,
    File,
    Nil,
    Directory,
    Visitor
}
import io.github.weakish.sysexits {
    ConfigurationError,
    CommandLineUsageError
}


File get_db(Directory repository, String category) {
    switch (db = repository.childResource(category + ".json").linkedResource)
    case (is File) {
        return db;
    }
    case (is Nil) {
        return db.createFile();
    }
    case (is Directory) {
        throw ConfigurationError("``category``.json must not be a directory.");
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

String relative_path(Path path, String branch) {
    // `.absolutePath.normalizedPath` is equvilent to Java's `getAbsolutePath()`:
    // redundant names such as "." and ".." are removed from the pathname,
    // and symbolic links are resolved.
    String[] path_elements = path.absolutePath.normalizedPath.elements;
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
        String file_path = relative_path(file.path, branch);
        switch (result = get_sha256(file))
        case (is String) {
            String sha256 = result;
            switch (record = db.getObjectOrNull(sha256))
            case (is JsonObject) {
                update_record(file.size, record, branch, file_path);
            }
            case (is Null) {
                insert_record(db,
                              sha256,
                              file.size, file.lastModifiedMilliseconds,
                              branch, file_path);
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
    switch (file = path.resource.linkedResource)
    case (is File) {
        add_file(file, db, branch);
    }
    case (is Directory) {
        add_directory(file, db, branch);
    }
    case (is Nil) {
        throw CommandLineUsageError("``path`` does not exist!");
    }
}


void add(Directory repository, String branch, String category, {Path*} paths) {
    File db_file = get_db(repository, category);
    JsonObject db = import_json(db_file);

    for (path in paths) {
        add_path(path, db, branch);
    }
    write_db_file(db_file, db);
}