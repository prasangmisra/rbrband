//go:build migration

package main

import (
	"io"
	"log"
	"os"

	"ariga.io/atlas-provider-gorm/gormschema"

	"github.com/prasangmisra/rbrband/internal/db/entity"
)

func main() {
	stmts, err := gormschema.New("postgres").Load(entity.AllEntities...)

	if err != nil {
		log.Fatalf("error loading gorm schema: %v\n", err)
	}

	_, err = io.WriteString(os.Stdout, stmts)

	if err != nil {
		log.Fatalf("error writing statements to stdout: %v", err)
	}
}
