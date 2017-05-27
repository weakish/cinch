import io.github.weakish.xdg {
    XDG
}
import ceylon.file {
    File,
    Directory,
    lines,
    Nil,
    Link
}
import io.github.weakish.sysexits {
    ConfigurationError,
    DataFormatError
}
import ceylon.json {
    JsonObject,
    parse,
    JsonArray
}

throws (`class ConfigurationError`, "if config file is unaccessable, empty, or corrupted")
String? read_config() {
    switch (config_file = XDG("cinch").config.childPath("config").resource)
    case (is File) {
        try (reader = config_file.Reader()) {
            switch (line = reader.readLine())
            case (is String) {
                switch (repo = line.split('='.equals).rest.first)
                case (is String) {
                    return repo;
                }
                case (is Null) {
                    throw ConfigurationError("`~/.config/cinch/config` is corrupted!");
                }
            }
            case (is Null) {
                throw ConfigurationError("`~/.config/cinch/config` seems empty or unaccessable!");
            }
        }
    }
    case (is Nil) {
        return null;
    }
    case (is Directory|Link) {
        throw ConfigurationError("`~/.config/cinch/config` must not be a directory or a link.");
    }

}

throws (`class DataFormatError`, "if db is invalid")
JsonObject import_json(File db) {
    String json_string = "\n".join(lines(db));
    if (json_string.empty) {
        return JsonObject({});
    } else {
        switch (json = parse(json_string))
        case (is JsonObject) {
            return json;
        }
        else {
            throw DataFormatError("``db`` is invalid.");
        }
    }
}


void insert_record(JsonObject db,
                   String sha256,
                   Integer size, Integer mtime, String branch, String file_path) {
    db.put {
        sha256;
        JsonObject {
            "size" -> size,
            "mtime" -> mtime,
            "branches" -> JsonObject {
                branch -> JsonArray({file_path})
            }
        };
    };
}

void update_record(Integer file_size, JsonObject record, String branch, String file_path) {
    if (file_size == record.getInteger("size")) {
        JsonObject branches = record.getObject("branches");
        switch (paths = branches.getArrayOrNull(branch))
        case (is JsonArray) {
            if (!paths.contains(file_path)) {
                paths.add(file_path);
            }
        }
        case (is Null) {
            branches.put(branch, JsonArray({file_path}));
        }
    } else {
        throw FileSizeMismatchException(file_path);
    }
}

void write_db_file(File db_file, JsonObject db) {
    try (writer = db_file.Overwriter()) {
        writer.write(db.pretty);
    }
}
