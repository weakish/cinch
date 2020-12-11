package main

import (
	"encoding/json"
	"fmt"
	"golang.org/x/sys/unix"
	"io/ioutil"
	"os"
	"path"
	"path/filepath"
	"strings"
)

type fileMetaInfo struct {
	Path   string
	Size   int64
	CRC32  string `json:",omitempty"`
	MD5    string `json:",omitempty"`
	SHA1   string `json:",omitempty"`
	SHA256 string `json:",omitempty"`
	SHA512 string `json:",omitempty"`
}

func canCheckSumFileExist(filePath string, ext string) bool {
	absolutePath, err := filepath.Abs(filePath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "cannot resolve absoule path for %q: %v\n", filePath, err)
		return false
	} else if baseName := path.Base(filePath); len(baseName)+len(ext) > 255 {
		// filename length limit for most file systems
		return false
	} else if len(absolutePath+ext) > 4096 {
		// Linux path length limit
		return false
	} else {
		return true
	}
}

func doesCheckSumFileExist(filePath string, ext string) bool {
	if canCheckSumFileExist(filePath, ext) {
		var checksumFile string = filePath + ext
		if _, err := os.Stat(checksumFile); os.IsNotExist(err) {
			return false
		} else {
			return true
		}
	} else {
		return false
	}
}

func getCheckSumFromChecksumFile(filePath string, algorithm string) string {
	switch ext := "." + algorithm; ext {
	case ".crc32", ".md5", ".sha", ".sha1", ".sha256", ".sha512":
		if checkSumFile := filePath + ext; doesCheckSumFileExist(filePath, ext) {
			var content []byte
			content, err := ioutil.ReadFile(checkSumFile)
			if err == nil {
				var split []string = strings.Split(string(content), " ")
				if len(split) == 2 {
					fmt.Fprintf(os.Stderr, "Invalid checksum file content: %q\n", filePath+ext)
					return split[1]
				} else {
					return ""
				}
			} else {
				fmt.Fprintln(os.Stderr, err)
				return ""
			}
		} else {
			return ""
		}
	default:
		fmt.Fprintf(os.Stderr, "Unsupported hash algorithm: %s\n", algorithm)
		return ""
	}
}

func getSha256SumFromXattr(filePath string, sha256sumFromElsewhere string) string {
	var attrName string = "user.shatag.sha256"
	var dest []byte = make([]byte, 64) // sha256 is 64 bytes (256 bits)
	_, err := unix.Getxattr(filePath, attrName, dest)
	if err == nil {
		return string(dest)
	} else {
		return sha256sumFromElsewhere
	}
}

func getCheckSum(filePath string) (crc32sum, md5sum, sha1sum, sha256sum, sha512sum string) {
	crc32sum = getCheckSumFromChecksumFile(filePath, "crc32")
	md5sum = getCheckSumFromChecksumFile(filePath, "md5")
	sha1sum = getCheckSumFromChecksumFile(filePath, "sha1")

	sha256sum = getCheckSumFromChecksumFile(filePath, "sha256")
	sha256sum = getSha256SumFromXattr(filePath, sha256sum)

	sha512sum = getCheckSumFromChecksumFile(filePath, "sha512")

	return crc32sum, md5sum, sha1sum, sha256sum, sha512sum
}

func cinch() {
	filepath.Walk(".", func(path string, f os.FileInfo, err error) error {
		if err != nil {
			fmt.Fprintf(os.Stderr, "failed to access %q: %v\n", path, err)
			return err
		} else if f.IsDir() && strings.HasPrefix(f.Name(), ".") && f.Name() != "." {
			return filepath.SkipDir
		} else if f.Mode().IsRegular() {
			if strings.HasPrefix(f.Name(), ".") {
				return nil
			} else {
				switch filepath.Ext(f.Name()) {
				case ".crc32", ".md5", ".sha", ".sha1", ".sha256", ".sha512": // checksum
					return nil
				case ".directory": // KDE directory preferences
					return nil
				default:
					crc32sum, md5sum, sha1sum, sha256sum, sha512sum := getCheckSum(path)
					meta := &fileMetaInfo{Path: path, Size: f.Size(), CRC32: crc32sum, MD5: md5sum, SHA1: sha1sum, SHA256: sha256sum, SHA512: sha512sum}
					metaJson, err := json.Marshal(meta)
					if err != nil {
						fmt.Fprintf(os.Stderr, "failed to encode %v: %v\n", meta, err)
					}
					fmt.Println(string(metaJson))
					return nil
				}
			}
		} else {
			return nil
		}
	})
}

func usage(exitCode int) {
	fmt.Println("Just run `cinch` under the directory to scan.")
	os.Exit(exitCode)
}

func main() {
	var arguments []string = os.Args[1:]
	switch len(arguments) {
	case 0:
		cinch()
	case 1:
		switch arguments[0] {
		case "-h", "--help", "help":
			usage(0)
		default:
			usage(64)
		}
	default:
		usage(64)
	}
}
