package main

import (
	"encoding/csv"
	"github.com/weakish/goaround"
	"github.com/weakish/gosugar"
	"io"
	"log"
	"os"
	"strconv"
)

func importCsv(path string, db Files) {
	goaround.RequireNonNull(db)
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
				if file.Paths.Contains(path) {
					log.Println(path + " already checked in.")
				} else {
					file.Paths.Add(path)
				}
			} else {
				var size int64
				size, err := strconv.ParseInt(record[1], 0, 64)
				if err != nil {
					log.Println(sha256 + "," + path + ": size unrecognizable " + record[1])
					size = 0
				}
				paths := gosugar.NewStringSet()
				paths.Add(path)
				db[sha256] = File{
					paths,
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

