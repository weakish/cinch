package main

import (
	"encoding/json"
	"github.com/weakish/goaround"
	"github.com/weakish/gosugar"
	"io/ioutil"
	"os"
)

type File struct {
	Paths gosugar.StringSet
	Size int64
}

type Files = map[string]File


func loadDb(path string) (db Files) {
	if _, err := os.Stat(path); os.IsNotExist(err) {
		db = make(map[string]File)
		return db
	} else {
		var content []byte
		content, err := ioutil.ReadFile(path)
		goaround.FatalIf(err)

		err = json.Unmarshal(content, &db)
		goaround.FatalIf(err)

		return db
	}
}

func saveDb(db Files, path string) {
	var data []byte
	data, err := json.Marshal(db)
	goaround.FatalIf(err)
	err = ioutil.WriteFile(path, data, 0644)
}
