package main

import (
	"encoding/json"
	"github.com/weakish/goaround"
	"github.com/weakish/gosugar"
	"io/ioutil"
)

type OldFile struct {
	Paths map[string]bool // mimic set
	Size int64
}
type OldFiles = map[string]OldFile

func convertDb(path string) {
	var content []byte
	content, err := ioutil.ReadFile(path)
	goaround.FatalIf(err)

	var old OldFiles
	err = json.Unmarshal(content, &old)
	goaround.FatalIf(err)

	db := make(Files)
	for sha256, f := range old {
		paths := gosugar.NewStringSet()
		paths.MigrateFrom(f.Paths)
		db[sha256] = File{
			paths,
			f.Size,
		}
	}

	saveDb(db, path)
}
