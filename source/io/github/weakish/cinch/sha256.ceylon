import ceylon.file {
    File,
    Path,
    parsePath
}
import java.io {
    IOException
}
import com.google.common.hash {
    HashCode,
    Hashing
}
import java.nio.file {
    Paths
}
import com.google.common.io {
    Files
}
"Search for `FILE.sha256` or `FILE.SHA256`."
File? get_sha256_file(File file) {
    Path sha256_file_path = parsePath(file.path.string + ".sha256");
    Path sha256_file_path_capitalized = parsePath(file.path.string + ".SHA256");

    if (is File sha256_file = sha256_file_path.resource) {
        return sha256_file;
    } else if (is File sha256_file = sha256_file_path_capitalized.resource) {
        return sha256_file;
    } else {
        return null;
    }
}

"Format: `sha256 file_name` or `sha256`."
String? parse_sha256_file(File file){
    try (reader = file.Reader()) {
        switch (line = reader.readLine())
        case (is String) {
            switch (sha256 = line.split().first)
            case (is String) {
                return sha256.lowercased;
            }
            else {
                return null;
            }
        }
        case (is Null) {
            return null;
        }
    }
}

String? read_sha256_from_file(File file) {
    switch (sha256_file = get_sha256_file(file))
    case (is File) {
        switch (sha256 = parse_sha256_file(sha256_file))
        case (is String) {
            return sha256;
        }
        case (is Null) {
            return null;
        }
    }
    case (is Null) {
        return null;
    }
}

"Read `user.shatag.sha256` xattr."
String? read_from_xattr(File file) {
    return read_xattr("shatag.sha256", file);
}

String|IOException compute_sha256(File file) {
    HashCode hashCode;
    value jfile = Paths.get(file.path.string).toFile();
    try {
        hashCode = Files.asByteSource(jfile).hash_method(Hashing.sha256());
    } catch (IOException e) {
        return e;
    }
    return hashCode.string;
}

String|IOException get_sha256(File file) {
    if (is String sha256 = read_sha256_from_file(file)) {
        return sha256;
    } else if (is String sha256 = read_from_xattr(file)) {
        return sha256;
    } else {
        return compute_sha256(file);
    }
}

