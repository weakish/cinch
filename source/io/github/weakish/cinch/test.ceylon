import ceylon.test {
    test,
    assertTrue,
    assertEquals
}
import java.io {
    JFile=File
}
import ceylon.file {
    File,
    parsePath,
    Resource,
    Path,
    Nil,
    home,
    Directory
}
import java.nio.file {
    Files,
    Paths,
    JPath=Path
}

test void xattr_is_enabled() {
    assertTrue(is_xattr_enabled());
}


test void successfully_read_sha256_from_file() {
    JFile temporary_file;
    temporary_file = JFile.createTempFile("cinch-", ".txt");

    Resource file = parsePath(temporary_file.string).resource;
    assert (is File file);
    try (writer = file.Overwriter()) {
        writer.writeLine("test sha256");
    }

    Path signature_path = parsePath(temporary_file.string + ".sha256");
    File signature;
    Resource location = signature_path.resource;
    assert (is Nil location);
    signature = location.createFile();
    String sha256 = "4b133f1ea590154b6354fd5df5467f5a2114ec0933f47a0aba1dcbdc00f7360d";
    try (writer = signature.Overwriter()) {
        writer.writeLine(
            "``sha256``  ``signature_path``"
        );
    }

    assertEquals(parse_sha256_file(signature), sha256);
    assertEquals(read_sha256_from_file(file), compute_sha256(file));
    assertEquals(get_sha256(file), sha256);

    Files.delete(Paths.get(signature.path.string));
    assertEquals(get_sha256(file), sha256);

    // clean up
    Files.delete(Paths.get(file.path.string));
}

test void repo_path_echoes_back() {
    assertEquals(repo_path(home.string), home);
}

test void successfully_create_readme() {
    JPath temporary_directory_path = Files.createTempDirectory("cinch-");
    Resource temporary_directory = parsePath(temporary_directory_path.string).resource;
    assert (is Directory temporary_directory);
    create_readme(temporary_directory);

    Resource readme = temporary_directory.childResource("README");
    assert (is File readme);

    void clean_up() {
        Files.delete(Paths.get(readme.path.string));
        Files.delete(temporary_directory_path);
    }
    clean_up();
}

test void successfully_write_config() {
    JPath temporary_directory_path = Files.createTempDirectory("cinch-");
    Resource temporary_directory = parsePath(temporary_directory_path.string).resource;
    assert (is Directory temporary_directory);

    write_config_file(temporary_directory, "/path/to/repo");

    Resource config = temporary_directory.childResource("config");
    assert (is File config);
    try (reader = config.Reader()) {
        assertEquals(reader.readLine(), "repo=/path/to/repo");
    }
    void clean_up() {
        Files.delete(Paths.get(config.string));
        Files.delete(temporary_directory_path);
    }
    clean_up();
}
