package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/spf13/viper"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// Config holds runtime configuration loaded from environment via viper
type Config struct {
	DatabaseURL string
	TimeoutSec  int
}

func loadConfig() (*Config, error) {
	v := viper.New()
	v.AutomaticEnv()
	v.SetDefault("TIMEOUT_SEC", 5)

	cfg := &Config{
		DatabaseURL: v.GetString("DATABASE_URL"),
		TimeoutSec:  v.GetInt("TIMEOUT_SEC"),
	}
	if cfg.DatabaseURL == "" {
		return nil, fmt.Errorf("DATABASE_URL is required")
	}
	return cfg, nil
}

func main() {
	cfg, err := loadConfig()
	if err != nil {
		log.Fatalf("config: %v", err)
	}

	dialector := postgres.Open(cfg.DatabaseURL)
	db, err := gorm.Open(dialector, &gorm.Config{})
	if err != nil {
		log.Fatalf("failed to open db: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(cfg.TimeoutSec)*time.Second)
	defer cancel()

	sqlDB, err := db.DB()
	if err != nil {
		log.Fatalf("get sql db: %v", err)
	}
	if err := sqlDB.PingContext(ctx); err != nil {
		log.Fatalf("ping db: %v", err)
	}

	fmt.Println("hello from gig worker service")
}
