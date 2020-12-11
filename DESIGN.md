# Keep It Simple, Stupid

- sha256 should be optional.

    * It should be implemented in the file system level.

    * Cloud drives typically use MD5 or SHA1.

    * It makes copying and modifying date complicated.

- It should not implement special wrapping commands for moving, copying, and deleting files.

    Just use normal `mv`, `cp`, `rm` etc. Using special commands increases mental burden and is error prone. I tend to forget to use them sometimes.

- It does not need to track the copies of files.

    * Just keep one copy.
    
    * If the files need to be backed up, backup the whole directory together with backup tools like `borg` or Time Machine.

    * If necessary, also backup them to remote machines (cloud).

    * The built-in disks of the laptop/desktop are considered as cache, where files are not counted as copies.

- Store data in a simple and fast format.

    [JSON Lines][jsonl] is a simple format, friendly to diff and grep.

[jsonl]: https://jsonlines.org/

## Schema

One file per driver/host.
One line per file.

```go
type fileMetaInfo struct {
	Path   string
	Size   int64
	CRC32  string `json:",omitempty"`
	MD5    string `json:",omitempty"`
	SHA1   string `json:",omitempty"`
	SHA256 string `json:",omitempty"`
	SHA512 string `json:",omitempty"`
}
```

```jsonl
{"Path":"DESIGN.md","Size":1293}
{"Path":"LICENSE","Size":191}
{"Path":"README.md","Size":641}
{"Path":"cinch","Size":2576922}
{"Path":"cinch.go","Size":4114}
```
