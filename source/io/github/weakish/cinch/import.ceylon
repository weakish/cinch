import ceylon.file {
    Directory,
    File,
    parsePath
}
import org.apache.commons.csv {
    CSVFormat
}
import java.io {
    FileReader,
    Reader
}
import ceylon.json {
    JsonObject,
    JsonArray
}
import java.util {
    HashMap,
    ArrayList
}
import java.lang {
    JString=String,
    Long
}
import java.lang.reflect {
    Type
}
import com.google.gson {
    Gson,
    GsonBuilder
}
import com.google.gson.reflect {
    TypeToken
}
import ceylon.interop.java {
    javaString
}

// `ArrayList<String>` in Java for serizilation with gson.
alias Paths => ArrayList<JString>;

// `HashMap` in `ceylon.collection` has performance issues:
// adding hundreds of thousands records to it will cause
// `java.lang.OutOfMemoryError` (GC overhead limit exceeded).
// Thus `HashMap` from `java.util` is used instead.
alias Branches => HashMap<String, Paths>;

// Uses `Long` instead of `Integer` for serizilation with gson.
// `Integer` would be converted to `{"value": number}`.
alias Details => HashMap<String, Long|Branches>;

alias Records => HashMap<String, Details>;

throws (`class ParseException`)
Records db_to_map(JsonObject db) {
    variable Integer size;
    variable Integer mtime;
    variable Paths paths = ArrayList<JString>();
    variable Branches branches = HashMap<String, Paths>();
    variable Details details = HashMap<String, Long|Branches>();
    Records records = HashMap<String, Details>();

    for (k->v in db) {
        switch (v)
        case (is JsonObject) {
            size = v.getInteger("size");
            mtime = v.getInteger("mtime");

            for (branch->file_paths in v.getObject("branches")){
                switch (file_paths)
                case (is JsonArray) {
                    for (path in file_paths) {
                        switch (path)
                        case (is String) {
                            paths.add(javaString(path));
                        }
                        else {
                            throw ParseException("Failed to parse ``k``->``v``");
                        }
                    }
                    branches[branch] = paths;
                }
                else {
                    throw ParseException("Failed to parse ``k``->``v``");
                }
            }

            details["size"] = Long(size);
            details["mtime"] = Long(mtime);
            details["branches"] = branches;

            records[k] = details;
        }
        else {
            throw ParseException("Failed to parse ``k``->``v else "null"``");
        }
    }
    return records;
}

throws (`class ParseException`)
void import_csv(Directory repository, String category, File csv) {
    File db_file = get_db(repository, category);
    JsonObject db = import_json(db_file);
    Records records = db_to_map(db);

    Reader input = FileReader(csv.path.string);
    value csv_records = CSVFormat.rfc4180.withFirstRecordAsHeader().parse(input);

    for (csv_record in csv_records) {
        String hash = csv_record.get("hash");
        Integer|ParseException size = Integer.parse(csv_record.get("size"));
        String branch = csv_record.get("name");
        JString path = javaString(
            relative_path(parsePath(csv_record.get("path")),
                branch)
        );

        switch (size)
        case (is Integer) {
            switch (details = records[hash])
            case (is Details) {
                switch (recorded = details["size"])
                case (is Long) {
                    if (Long(size) == recorded) {
                        switch (branches = details["branches"])
                        case (is Branches) {
                            switch (file_paths = branches[branch])
                            case (is Paths) {
                                if (!file_paths.contains(path)) {
                                    file_paths.add(path);
                                }
                            }
                            case (is Null) {
                                Paths paths = ArrayList<JString>();
                                paths.add(path);
                                Branches file_branches = HashMap<String,Paths>();
                                file_branches[branch] = paths;
                                details["branches"] = file_branches;
                            }
                        }
                        case (is Null|Long) {
                            throw ParseException("branches of ``hash``");
                        }
                    } else {
                        process.writeErrorLine(
                            "SizeMismatch: ``hash`` ``path`` has size ``size``,
                             while recorded size is ``recorded``");
                    }
                }
                case (is Null|Branches) {
                    throw ParseException("size of ``hash``");
                }
            }
            case (is Null) {
                Details file_details = HashMap<String,Long|Branches>();
                file_details["size"] =Long(size);
                file_details["mtime"] =Long(-1);
                Paths paths = ArrayList<JString>();
                paths.add(path);
                Branches file_branches = HashMap<String,Paths>();
                file_branches[branch] = paths;
                file_details["branches"] = file_branches;
                records[hash] = file_details;
            }
        }
        case (is ParseException) {
            throw ParseException("Error on processing ``csv_record``.");
        }
    }

    object typeToken extends TypeToken<Records>() {}
    Type records_type = typeToken.type;
    Gson gson = GsonBuilder().setPrettyPrinting().create();
    String json_out_put = gson.toJson(records, records_type);

    try (writer = db_file.Overwriter()) {
        writer.write(json_out_put);
    }
}
