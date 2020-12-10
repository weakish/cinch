package main

import (
	"fmt"
	"os"
)

func main() {
	var arguments []string = os.Args[1:]
	if len(arguments) == 1 {
		if command := arguments[0]; command == "migrate" {
			var dbPath string = os.Getenv("HOME") + "/" + "cinch.json"
			convertDb(dbPath)
		} else {
			usage()
			os.Exit(0)
		}
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
		case "debug":
			if arguments[1] == "mode" {
				debug(dbPath)
			} else {
				fmt.Println("DEBUG ONLY (may cause data corruption!): cinch debug mode")
			}
		default:
			usage()
			os.Exit(1)
		}
	} else {
		usage()
		os.Exit(0)
	}
}
func usage() {
	fmt.Println("cinch import file.csv")
	fmt.Println("cinch add directory")
	fmt.Println("WARNING: the added directory MUST NOT contain the cinch executable file itself!")
}
