package main

import (
	"fmt"
	"os"
)

func main() {
	var arguments []string = os.Args[1:]
	if len(arguments) <= 1 {
		usage()
		os.Exit(0)
	} else if len(arguments) == 2 {
		var dbPath string = os.Getenv("HOME") + "/" + "cinch.json"
		var db Files
		switch command := arguments[0]; command {
		case "add":
			db = loadDb(dbPath)
			addDirectory(arguments[1], db)
			saveDb(db, dbPath)
		case "import":
			db = loadDb(dbPath)
			importCsv(arguments[1], db)
			saveDb(db, dbPath)
		default:
			usage()
			os.Exit(1)
		}
	}
}

func usage() {
	fmt.Println("cinch import <path.csv>")
}
