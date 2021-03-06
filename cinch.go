package main

import (
	"encoding/json"
	"fmt"
	"github.com/weakish/gosugar"
	"golang.org/x/sys/unix"
	"io/ioutil"
	"os"
	"os/exec"
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
		fmt.Fprintf(os.Stderr, "cannot resolve absolute path for %q: %v\n", filePath, err)
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
		checkSumFilePath := filePath + ext
		if _, err := os.Stat(checkSumFilePath); os.IsNotExist(err) {
			return false
		} else {
			return true
		}
	} else {
		return false
	}
}

func getCheckSumFromCheckSumFile(filePath string, algorithm string) string {
	switch ext := "." + algorithm; algorithm {
	case "crc32", "md5", "sha256", "sha512":
		return readCheckSumFile(filePath, ext)
	case "sha1":
		trySha1 := readCheckSumFile(filePath, ext)
		if trySha1 == "" {
			trySha := readCheckSumFile(filePath, ".sha")
			return trySha
		} else {
			return trySha1
		}
	default:
		fmt.Fprintf(os.Stderr, "Unsupported hash algorithm: %s\n", algorithm)
		return ""
	}
}

func readCheckSumFile(filePath string, ext string) string {
	if checkSumFile := filePath + ext; doesCheckSumFileExist(filePath, ext) {
		var content []byte
		content, err := ioutil.ReadFile(checkSumFile)
		if err == nil {
			split := strings.Fields(string(content))
			if len(split) == 2 {
				return split[1]
			} else {
				fmt.Fprintf(os.Stderr, "Invalid checksum file content: %q\n", checkSumFile)
				return ""
			}
		} else {
			fmt.Fprintf(os.Stderr, "failed to read %q: %v", checkSumFile, err)
			return ""
		}
	} else {
		return ""
	}
}

func getSha256SumFromXattr(filePath string, sha256sumFromElsewhere string) string {
	attrName := "user.shatag.sha256"
	dest := make([]byte, 64) // sha256 is 64 bytes (256 bits)
	_, err := unix.Getxattr(filePath, attrName, dest)
	if err == nil {
		return string(dest)
	} else {
		return sha256sumFromElsewhere
	}
}

func getCheckSum(filePath string) (crc32sum, md5sum, sha1sum, sha256sum, sha512sum string) {
	crc32sum = getCheckSumFromCheckSumFile(filePath, "crc32")
	md5sum = getCheckSumFromCheckSumFile(filePath, "md5")
	sha1sum = getCheckSumFromCheckSumFile(filePath, "sha1")

	sha256sum = getCheckSumFromCheckSumFile(filePath, "sha256")
	// xattr takes priority.
	sha256sum = getSha256SumFromXattr(filePath, sha256sum)

	sha512sum = getCheckSumFromCheckSumFile(filePath, "sha512")

	return
}

func isBackupFile(name string) bool {
	switch filepath.Ext(name) {
	case ".bkp", ".backup", ".bup", ".attic", ".borg":
		return true
	default:
		return false
	}
}

func cinch() {
	_ = filepath.Walk(".", func(path string, f os.FileInfo, err error) error {
		if err != nil {
			fmt.Fprintf(os.Stderr, "failed to access %q: %v\n", path, err)
			return err
		} else if gosugar.IsUnixHiddenFile(f.Name()) {
			return gosugar.SkipDirOrFile(f)
		} else if isBackupFile(f.Name()) {
			return gosugar.SkipDirOrFile(f)
		} else if f.Mode().IsRegular() {
			switch filepath.Ext(f.Name()) {
			case ".crc32", ".md5", ".sha", ".sha1", ".sha256", ".sha512": // checksum file
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
		} else {
			return nil
		}
	})
}

func usage(exitCode int) {
	_, _ = os.Stderr.WriteString("Just run `cinch` under the directory to scan.\n")
	os.Exit(exitCode)
}

func main() {
	arguments := os.Args[1:]
	switch argumentsLength := len(arguments); argumentsLength {
	case 0:
		cinch()
	case 1:
		switch arguments[0] {
		case "-h", "--help", "help":
			usage(0)
		case "--version", "version":
			const version = "0.1.0"
			fmt.Printf("cinch %s\n", version)
		default:
			usage(64)
		}
	default:
		switch arguments[0] {
		case "cp":
			cpArgs := make([]string, argumentsLength)
			cpArgs[0] = "--preserve=xattr"
			cpArgs = append(cpArgs, arguments[1:argumentsLength]...)
			cmd := exec.Command("cp", cpArgs...)
			_ = cmd.Run()
		default:
			usage(64)
		}
	}
}
