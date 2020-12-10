package main

import (
	"fmt"
	"strings"
)

func debug(dbPath string) {
	//fmt.Printf("Entering DEBUG MODE:\nusing database %s\n", dbPath)
	var db Files = loadDb(dbPath)

	var ill string = "\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000"
	for k, v := range db {
		if k == ill {
			paths := v.Paths.ToSlice()
			fmt.Println(strings.Join(paths, "\n"))
			//fmt.Printf("\n\n %d", len(paths))
		}
	}
}
