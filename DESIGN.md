# Keep It Simple, Stupid

- sha256 should be optional.

    * It should be implemented in the file system level.

    * Cloud drives typically use MD5 or SHA1.

    * It makes copying and modifying date complicated.

- It should not implement special wrapping commands for moving, copying, and deleting files.

    Just use normal `mv`, `cp`, `rm` etc. Using special commands increases mental burden and is error prone. I tends to forget to use them sometimes.

- It does not need to track the copies of files.

    * Just keep one copy.
    
    * If the files need to be backed up, backup the whole directory together with backup tools like `borg` or Time Machine.

    * If necessary, also backup them to remote machines (cloud).

    * The built-in disks of the laptop/desktop are considered as cache, where files are not counted as copies.

- Store data in a simple and fast format.

    [JSON Lines][jsonl] is a simple format, friendly to diff and grep.

[jsonl]: https://jsonlines.org/

## Format

One file per driver/host.

```jsonl
[path, size, {"hash_algorithm": "checksum_value"}]
```
