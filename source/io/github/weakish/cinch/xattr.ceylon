import java.nio.file {
    Paths,
    Files,
    FileStore
}
import ceylon.file {
    current,
    Path,
    parsePath,
    File
}
import java.nio.file.attribute {
    UserDefinedFileAttributeView
}
import ceylon.interop.java {
    javaClass
}
import java.io {
    IOException
}
import java.nio {
    ByteBuffer
}
import java.nio.charset {
    Charset
}

"Test if xattr is enabled on the filesystem."
Boolean is_xattr_enabled() {
    value filePath = Paths.get(current.string);
    FileStore fileStore = Files.getFileStore(filePath);

    if (fileStore.supportsFileAttributeView("user")) {
        return true;
    } else {
        // `supportsFileAttributeView` cannot guarantee to give the correct result
        // when the file store is not a local storage device.
        return guess(fileStore.name());
    }
}

Boolean check_according_to_file_system_type(String line) {
    {String+} enabled_by_default_file_system = {
        "ext2", "ext3", "ext4",
        "jfs", "xfs",
        "zfs", "btrfs",
        "squashfs", "f2fs",
        "yaffs2", "orangefs", "lustre", "ocfs2"
    };

    if (line.containsAny(enabled_by_default_file_system)) {
        return true;
    } else if (line.contains("reiserfs")) { // ReiserFS is an exception.
        return false;
    } else if (line.contains("ntfs-3g")) { // ntfs-3g is different.
        if (line.contains("streams_interface=xattr")) { // same as `user_xattr`
            return true;
        } else if (line.contains("streams_interface=none") ||
                   line.contains("streams_interface=windows")) {
            return false;
        } else { // The default is `xattr`.
            return true;
        }
    } else { // other file systems, assuming false
       return false;
    }
}

Boolean check_mount_options(File file, String file_store_name) {
   try (reader = file.Reader()) {
       while (exists line = reader.readLine()) {
           if (line.contains(file_store_name)) {
               // Does not handle overwritting options, e.g. `nouser_xattr,user_xattr`.
               if (line.contains("nouser_xattr")) {
                   return false;
               } else if (line.contains("user_xattr")) {
                   return true;
               } else {
                   // For recent Linux kernels,
                   // most of the filesystems which support extended user attributes
                   // enable them by default.
                   return check_according_to_file_system_type(line);
               }
           }
       }
       // File store not found in mtab, assuming false.
       return false;
   }
}

Boolean guess(String file_store_name) {
    Path mtab = parsePath("/etc/mtab");
    if (is File file = mtab.resource) {
        return check_mount_options(file, file_store_name);
    } else {
        // No `mtab`, probably not on linux. Assuming true.
        return true;
    }
}

UserDefinedFileAttributeView get_xattr_view(File file) {
    value file_path = Paths.get(file.path.string);
    UserDefinedFileAttributeView? view = Files.getFileAttributeView(
        file_path,
        javaClass<UserDefinedFileAttributeView>());
    if (exists view) {
        return view;
    } else {
        throw XattrNotEnabledException(
            "`user_xattr` is not enabled!
             Remount the filesystem with `user_xattr`
             or switch to a filesystem supporting `user_xattr`.");
    }
}

Integer? get_xattr_size(UserDefinedFileAttributeView view, String tag) {
    try {
        return view.size(tag);
    } catch (IOException e) {
        return null;
    }
}

String get_xattr(String tag, Integer size, UserDefinedFileAttributeView view) {
    ByteBuffer buffer = ByteBuffer.allocate(size);
    view.read(tag, buffer);
    buffer.flip();
    String xattr = Charset.defaultCharset().decode(buffer).string;
    return xattr;
}

String? read_xattr(String tag, File file) {
    UserDefinedFileAttributeView view = get_xattr_view(file);
    switch (size = get_xattr_size(view, tag))
    case (is Integer) {
        return get_xattr(tag, size, view);
    }
    case (is Null) {
        return null;
    }
}
