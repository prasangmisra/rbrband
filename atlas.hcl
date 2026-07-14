# Atlas configuration for rbrband
# Uses Atlas provider for GORM to load schema from Go models

data "external_schema" "gorm" {
  program = [
    "go",
    "run",
    "-tags", "migration",
    "./cmd/migrate",
  ]
}

env "local" {
  # Apply the GORM schema to calculate the diff
  src = data.external_schema.gorm.url

  # The actual running database for applying migrations
  url = "postgres://admin:rbrband123@localhost/rbrband?sslmode=disable"

  migration {
    dir = "file://migrations"
  }

  format {
    migrate {
      diff = "{{ sql . }}"
    }
  }
}

env "dev" {
  # Development environment using external schema only (no DB needed for diff)
  src = data.external_schema.gorm.url
  url = "postgres://admin:rbrband123@localhost/rbrband?sslmode=disable"
  
  migration {
    dir = "file://migrations"
  }
}
