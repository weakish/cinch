package main

import (
	"crypto/sha256"
	"encoding/hex"
	"github.com/weakish/goaround"
	"github.com/weakish/gosugar"
	"golang.org/x/sys/unix"
	"hash"
	"io"
	"io/ioutil"
	"log"
	"os"
	"path"
	"path/filepath"
	"strings"
)

func addDirectory(path string, db Files) {
	goaround.RequireNonNull(db)
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
	goaround.RequireNonNull(db)
	return func(filePath string, info os.FileInfo, err error) error {
		if err != nil {
			log.Print(err)
			return nil
		} else if info.IsDir() {
			switch ext := filepath.Ext(filePath); ext {
			case ".git", ".hg", ".svn", ".idea":
				return filepath.SkipDir
			default:
				return nil
			}
		} else {
			switch ext := filepath.Ext(filePath); ext {
			case ".md5", ".sha", ".sha1", ".sha256", ".sha512":
				return nil
			default:
				var sha256sum string
				var size int64

				if checkSumFile := filePath + ".sha256"; doesCheckSumFileExist(filePath) {
					var content []byte
					content, err := ioutil.ReadFile(checkSumFile)
					goaround.LogIf(err)
					var split []string = strings.Split(string(content), " ")
					sha256sum = goaround.GetString(split, 1)
					size = info.Size()
				} else {
					sha256sum, size = getSha256AndSize(filePath, info)
				}

				var file File
				file, present := db[sha256sum]
				if present {
					if file.Paths.Contains(filePath) {
						// already checked in
					} else {
						file.Paths.Add(filePath)
					}
				} else {
					paths := gosugar.NewStringSet()
					paths.Add(filePath)
					db[sha256sum] = File{
						paths,
						size,
					}
				}
				return nil
			}
		}
	}
}

func doesCheckSumFileExist(filePath string) bool {
	if canCheckSumFileExist(filePath) {
		var checksumFile string = filePath + ".sha256"
		if _, err := os.Stat(checksumFile); os.IsNotExist(err) {
			return false
		} else {
			return true
		}
	} else {
		return false
	}
}

func canCheckSumFileExist(filePath string) bool {
	// Most filesystems have a 255 filename length limit.
	// len(".sha256") = 7
	if baseName := path.Base(filePath); len(baseName) + 7 > 255 {
		return false
	} else if checksumFile := filePath + ".sha256"; len(checksumFile) > 4096 { // Linux path length limit
		return false
	} else {
		return true
	}
}

func getSha256AndSize(path string, info os.FileInfo) (sha256sum string, size int64) {
	goaround.RequireNonNull(info)
	var attrName string = "user.shatag.sha256"
	var dest []byte = make([]byte, 64) // sha256 is 64 bytes (256 bits)
	_, err := unix.Getxattr(path, attrName, dest)
	if err == nil {
		sha256sum = string(dest)
		size = info.Size()
		return sha256sum, size
	} else {
		var f *os.File
		f, err := os.Open(path)
		goaround.LogIf(err)
		defer f.Close()

		var h hash.Hash = sha256.New()
		size, err = io.Copy(h, f)
		goaround.LogIf(err)
		sha256sum = hex.EncodeToString(h.Sum(nil))

		err = unix.Setxattr(path, attrName, dest, 0)
		if err != nil {
			log.Print(err)
		}
		return sha256sum, size
	}
}

