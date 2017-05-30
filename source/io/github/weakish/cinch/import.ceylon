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
import java.util {
    HashMap,
    ArrayList
}
import java.lang {
    JString=String
}
import java.lang.reflect {
    Type
}
import com.google.gson {
    Gson,
    GsonBuilder,
    JsonIOException,
    JsonSyntaxException
}
import com.google.gson.reflect {
    TypeToken
}
import ceylon.interop.java {
    javaString
}

// `ArrayList<String>` in Java for serizilation with gson.
alias Values => ArrayList<JString>;

alias Infos => HashMap<JString,Values>;
alias Details => HashMap<JString, Infos>;

// `HashMap` in `ceylon.collection` has performance issues:
// adding hundreds of thousands records to it will cause
// `java.lang.OutOfMemoryError` (GC overhead limit exceeded).
// Thus `HashMap` from `java.util` is used instead.
alias Records => HashMap<JString, Details>;

throws (
    `class ParseException`,
    "when failed to parse CSV file or json records"
)
throws (
    `class JsonIOException`,
    "if there was a problem reading from the Reader"
)
throws (
    `class JsonSyntaxException`,
    "if json is not a valid representation for an object of type"
)
void import_csv(Directory repository, String category, File csv) {
    object typeToken extends TypeToken<Records>() {}
    Type records_type = typeToken.type;

    File db_file = get_db(repository, category);
    Reader json_file_reader = FileReader(db_file.path.string);
    Gson gson_reader = Gson();
    Records records = gson_reader.fromJson<Records>(
        json_file_reader, records_type
    ) else HashMap<JString, Details>();

    Reader input = FileReader(csv.path.string);
    value csv_records = CSVFormat.rfc4180.withFirstRecordAsHeader().parse(input);

    for (csv_record in csv_records) {
        JString hash = javaString(csv_record.get("hash"));
        JString size = javaString(csv_record.get("size"));
        JString branch = javaString(csv_record.get("name"));
        JString path = javaString(
            relative_path(parsePath(csv_record.get("path")),
                branch.string)
        );

        if (exists details = records[hash]) {
            if (exists branches = details[javaString("branches")]) {
                if (exists paths = branches[branch]) {
                    if (!paths.contains(path)) {
                        paths.add(path);
                    }
                } else {
                    Values paths = ArrayList<JString>();
                    paths.add(path);
                    branches[branch] = paths;
                    details[javaString("branches")] = branches;
                }
            } else {
                throw ParseException("branches of ``hash``");
            }
        }
        else {
            Details details = HashMap<JString,Infos>();

            Values size_values = ArrayList<JString>();
            size_values.add(size);
            Infos size_record = HashMap<JString, Values>();
            size_record[javaString("Integer")] = size_values;
            details[javaString("size")] = size_record;

            Values mtime_values = ArrayList<JString>();
            mtime_values.add(javaString("-1"));
            Infos mtime_record = HashMap<JString, Values>();
            mtime_record[javaString("Integer")] = mtime_values;
            details[javaString("mtime")] = mtime_record;

            Values paths = ArrayList<JString>();
            paths.add(path);
            Infos file_branches = HashMap<JString,Values>();
            file_branches[branch] = paths;
            details[javaString("branches")] = file_branches;
            records[hash] = details;
        }
    }

    Gson gson_writer = GsonBuilder().setPrettyPrinting().create();
    String json_out_put = gson_writer.toJson(records, records_type);

    try (writer = db_file.Overwriter()) {
        writer.write(json_out_put);
    }
}
