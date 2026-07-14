package entity

import "time"

type User struct {
	ID           int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	Email        string    `gorm:"type:text;uniqueIndex" json:"email"`
	PasswordHash string    `gorm:"type:text" json:"-"`
	DisplayName  string    `gorm:"type:text" json:"display_name"`
	CreatedAt    time.Time `gorm:"autoCreateTime" json:"created_at"`
	RatingAvg    float64   `gorm:"type:numeric(5,2);default:0" json:"rating_avg"`
	RatingCount  int64     `gorm:"default:0" json:"rating_count"`
}
