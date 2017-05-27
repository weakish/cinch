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
    JsonObject
}
void import_csv(Directory repository, String category, File csv) {
    File db_file = get_db(repository, category);
    JsonObject db = import_json(db_file);

    Reader input = FileReader(csv.path.string);
    value records = CSVFormat.rfc4180.withFirstRecordAsHeader().parse(input);
    for (csv_record in records) {
        String hash = csv_record.get("hash");
        Integer|ParseException size = Integer.parse(csv_record.get("size"));
        String branch = csv_record.get("name");
        String path = relative_path(parsePath(csv_record.get("path")),
                                    branch);

        switch (size)
        case (is Integer) {
            switch (record = db.getObjectOrNull(hash))
            case (is JsonObject) {
                update_record(size, record, branch, path);
            }
            case (is Null) {
                insert_record(db,
                              hash,
                              size, -1, branch, path);
            }

        }
        case (is ParseException) {
            process.writeErrorLine("Error on processing ``csv_record``.");
        }
    }
    
    write_db_file(db_file, db);
}