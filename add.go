package main

import (
	"path/filepath"
	"os"
	"github.com/weakish/goaround"
	"log"
	"io/ioutil"
	"strings"
	"crypto/sha256"
	"hash"
	"io"
	"encoding/hex"
	"golang.org/x/sys/unix"
)

func addDirectory(path string, db Files) {
	var absolutePath string
	absolutePath, err := filepath.Abs(path)
	goaround.FatalIf(err)
	var fileInfo os.FileInfo
	fileInfo, err = os.Stat(absolutePath)
	goaround.FatalIf(err)
	if fileInfo.IsDir() {
		err = filepath.Walk(absolutePath, addFile(db))
		goaround.LogIf(err)
	} else {
		log.Fatal(absolutePath + " is not a directory!")
	}
}

func addFile(db Files) filepath.WalkFunc {
	return func(path string, info os.FileInfo, err error) error {
		if err != nil {
			log.Print(err)
			return nil
		} else if info.IsDir() {
			switch ext := filepath.Ext(path); ext {
			case ".git", ".hg", ".svn", ".idea":
				return filepath.SkipDir
			default:
				return nil
			}
		} else {
			switch ext := filepath.Ext(path); ext {
			case ".md5", ".sha", ".sha1", ".sha256", ".sha512":
				return nil
			default:
				var sha256sum string
				var size int64

				var checksumFile string = path + ".sha256"
				if _, err := os.Stat(checksumFile); os.IsNotExist(err) {
					var attrName string = "user.shatag.sha256"
					var dest []byte = make([]byte, 64) // sha256 is 64 bytes (256 bits)
					_, err := unix.Getxattr(path, attrName, dest)
					if err == nil {
						sha256sum = string(dest)
						size = info.Size()
					} else {
						var f *os.File
						f, err := os.Open(path)
						goaround.LogIf(err)
						defer f.Close()

						var h hash.Hash = sha256.New()
						size, err = io.Copy(h, f)
						goaround.LogIf(err)
						sha256sum = hex.EncodeToString(h.Sum(nil))

						err = unix.Setxattr(path, attrName, []byte(sha256sum), 0)
						if err != nil {
							log.Print(err)
						}
					}
				} else {
					var content []byte
					content, err := ioutil.ReadFile(checksumFile)
					goaround.LogIf(err)
					var split []string = strings.Split(string(content), " ")
					sha256sum = goaround.StringAt(split, 1)
					size = info.Size()
				}

				var file File
				file, present := db[sha256sum]
				if present {
					if file.Paths[path] {
						// already checked in
					} else {
						file.Paths[path] = true
					}
				} else {
					db[sha256sum] = File{
						map[string]bool{path: true},
						size,
					}
				}
				return nil
			}
		}
	}
}

