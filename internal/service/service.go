package service

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/spf13/viper"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type App struct {
	DB *gorm.DB
}

// Health returns 200 if the service is running
func (a *App) Health(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

// Ready returns 200 if the service and database are both healthy
func (a *App) Ready(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	sqlDB, err := a.DB.DB()
	if err != nil {
		w.WriteHeader(http.StatusServiceUnavailable)
		w.Write([]byte("DB connection failed"))
		return
	}

	if err := sqlDB.PingContext(ctx); err != nil {
		w.WriteHeader(http.StatusServiceUnavailable)
		w.Write([]byte("DB ping failed"))
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Ready"))
}

func NewAppFromEnv() (*App, error) {
	v := viper.New()
	v.AutomaticEnv()
	v.SetDefault("TIMEOUT_SEC", 5)

	dsn := v.GetString("DATABASE_URL")
	if dsn == "" {
		return nil, fmt.Errorf("DATABASE_URL is required")
	}

	dialector := postgres.Open(dsn)
	db, err := gorm.Open(dialector, &gorm.Config{})
	if err != nil {
		return nil, err
	}

	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(v.GetInt("TIMEOUT_SEC"))*time.Second)
	defer cancel()

	sqlDB, err := db.DB()
	if err != nil {
		return nil, err
	}
	if err := sqlDB.PingContext(ctx); err != nil {
		return nil, err
	}

	return &App{DB: db}, nil
}
