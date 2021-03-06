# Cinch

A manager of large files.

From WordNet 3.0 (2006)

> **cinch**
>
> - **noun** any undertaking that is easy to do

## Install

Compile from source and install to `/usr/local/bin`:

```sh
make
make install
```

Depending on your file system permission configuration, you may need to prefix the `make install` command with `sudo`.
If you want to install cinch to other directory, please edit the `config.mk` file.
The Makefile is compatible with both GNU and BSD make.


## Usage

```sh
cinch
```

Refer to DESIGN.md and source code (`cinch.go`) for more information.

## Reference

You may have interests in the following projects:

- git-annex
- [shatag](https://bitbucket.org/maugier/shatag)
- [shattr](https://github.com/weakish/shattr)

## Contributing

1. Fork it ( https://github.com/weakish/cinch/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

The coding style I use: https://mmap.page/coding-style/go/

## License

0BSD