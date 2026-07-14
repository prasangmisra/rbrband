package entity

import "time"

type Band struct {
	ID          int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	Name        string    `gorm:"type:text;index" json:"name"`
	Slug        string    `gorm:"type:text;uniqueIndex" json:"slug"`
	Bio         string    `gorm:"type:text" json:"bio"`
	City        string    `gorm:"type:text" json:"city"`
	Country     string    `gorm:"type:text" json:"country"`
	OwnerID     int64     `gorm:"not null" json:"owner_id"`
	CreatedAt   time.Time `gorm:"autoCreateTime" json:"created_at"`
	RatingAvg   float64   `gorm:"type:numeric(5,2);default:0" json:"rating_avg"`
	RatingCount int64     `gorm:"default:0" json:"rating_count"`
}
