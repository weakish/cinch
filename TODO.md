## Choices of backend

To manage file operation history, we can use `git` as a backend,
instead of SQL databases used by `shatag`.

### Choice 1

Use filename as key:

```ceylon
String repo = "~/.local/var/shattr/repo";
String host = "hostname";
String fileName = "``repo``/hostname/path/to/original/file";
```

Content is compatible with git-lfs:

```
version https://git-lfs.github.com/spec/v1
oid sha256:f4ddae8469a15fb96fea5bfb3340526fe415a6cfc5bc6deebf5ae418b407364d
size 21
```

Pros:

Just use ordinal file operations like `mv` and `rm`, etc.

Cons:

1. We need to build separated index of sha256.

2. A huge number of files will exhaust inodes of file system and slow down git.

    > Scaling to hundreds of thousands of files is not a problem,
    > scaling beyond that and git will start to get slow.

    -- [git-annex wiki](https://git-annex.branchable.com/scalability/)

    I have 1904875 files (and growing).

### Choice 2

Use `sha256` as key:

```Ceylon
String repo = "~/.local/var/shattr/repo";
String fileName = "``repo``/sha256"
```

Content

```
version https://git-lfs.github.com/spec/v1
oid sha256:f4ddae8469a15fb96fea5bfb3340526fe415a6cfc5bc6deebf5ae418b407364d
size 21
paths hostname:/path/to/file;another:/path/to/file
```

We still have `oid` field to conform git-lfs specification.

Pros:

1. If we want to delete files safely, e.g. not allowing delete the last copy, use sha256 as index will be fast to query.

Cons:

1. Ordinal file operations like `mv` and `rm` does not work
    (unless we implement a FUSE file system).

2. Still a huge number of files.
    I have 1338211 (and growing).

### Option 3

Option 1 + separated repositories for videos, audios, books etc.

Pros:

1. Same as Option 1.

Cons:

1. Same as Option 1, except file numbers.
2. Inter-repository operation is difficult to handle.

### Option 4

Option 2 + separated repositories.

Cons:

Refer to Option 2 and Option 3.

### Option 5

Use one big text file (e.g. csv) to record all meta data, sorted by `sha256`.

Pros:

- If we read the file in RAM, it may be faster than to query the file system.

Cons:

`mv` etc won't work.

### Option 6

Option 5 + separated text files.

Cons:

Refer to Option 2 and Option 3.

### Option 7

Without git, use Java  object persistence, like [Prevayler][].

Pros:

- Faster to load in RAM.

Cons:

- Need to implement history myself.

[Prevayler]: http://prevayler.org/

## Backend

First, I do not want to implement history myself.

Second, I choose to use sha256 as key, because:

- It is fast to find copies (no need to grep sha256).
- It is fast to find the record (just read the xattr of file, no need to grep path).
- Other file manger systems like git-annex and ipfs also use checksum as key.

Third, I choose separated files/repos, because:

- Fast to search.

- Duplication between different types of collection is useful.

    For example, an album cover image in both the `image` set and the `music` set.
    If they are counted as duplication, and, say, the copy in `music` set is removed,
    then the cover is missing in the music directory
    (e.g. a music playre cannot diplay it),
    even though the file still exists in `image` set.
    Also, linking the cover image in `music` set to the file in `image` set may not be useful,
    because `music` and `image` set may be on different external disks
    and not available at the same time.

Fourth, I choose one big file instead of one sha256 per file, because:

- Fast to load in RAM.
- Fast to operate under Git.
- Avoid too many inodes issue.

Last, I choose json as the file format:

- CSV is bad at nested structure, e.g. `paths` need to be an array, how to map it to CSV?
- Ceylon has `ceylon.json` in its standard libraries.
Commands:

### Conclusion

#### Directory structure

```
cinch-repo
    audio.json
    video.json
    ...
```

#### JSON schema

```json
{
    { "SHA256-hash_of_file": {
            size: Integer,
            lastModificationTime: Integer,
            [
                "external-drive-name_or_remote-host-name": "relative/path/to/mountpoint",
                ...
            ]
        }
    },
    ...
}
```


## CliO UI

```
cinch init
cinch add [files ...] (first, after edit)
cinch mv
cinch drop path/to/filename (mark removed only)
cinch rm path/to/filename (true rm)
cinch ls
cinch find
cinch status (not added/removed files)
cinch whereis path/to/filename | sha256
cinch addurl
cinch trust
cinch untrust
cinch semitrust
cinch dead
cinch uncinch
cinch uninit
```
