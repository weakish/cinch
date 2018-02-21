package main

import (
	"os"
	"encoding/csv"
	"io"
	"log"
	"strconv"
	"github.com/weakish/goaround"
)

func importCsv(path string, db Files) {
	var file *os.File
	file, err := os.Open(path)
	goaround.FatalIf(err)
	defer file.Close()

	var records *csv.Reader
	records = csv.NewReader(file)

	discardHeader(records)
	for {
		var record []string
		record, err := records.Read()
		if err == io.EOF {
			break
		} else if err != nil {
			log.Fatal(err)
		} else {
			var sha256 string = record[0]
			var path string = record[3]
			var file File
			file, present := db[sha256]
			if present {
				if file.Paths[path] {
					log.Println(path + " already checked in.")
				} else {
					file.Paths[path] = true
				}
			} else {
				var size int64
				size, err := strconv.ParseInt(record[1], 0, 64)
				if err != nil {
					log.Println(sha256 + "," + path + ": size unrecognizable " + record[1])
					size = 0
				}
				db[sha256] = File{
					map[string]bool{path: true},
					size,
					}
			}
		}
	}
}

func discardHeader(records *csv.Reader) {
	var header []string
	header, err := records.Read()
	if err != nil {
		log.Fatal(err)
	} else {
		if header[0] != "hash" {
			log.Fatal("CSV file should begin with `hash,size,name,path`!")
		} else {
			// fine
		}
	}
}
