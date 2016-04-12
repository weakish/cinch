package main

import (
	"crypto/sha256"
	"fmt"
	"log"
	"io"
	"os"
)

func main() {
	oidHash := sha256.New()
	size, err := io.Copy(oidHash, os.Stdin)

	if err != nil {
		log.Fatal(err)
		os.Exit(1)
	}

	fmt.Printf("version https://git-lfs.github.com/spec/v1\n")
	fmt.Printf("oid sha256:%x\n", oidHash.Sum(nil))
	fmt.Printf("size %d\n", size)
}
