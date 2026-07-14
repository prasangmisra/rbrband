package entity

import "time"

type Rating struct {
	ID        int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	GigID     int64     `gorm:"index" json:"gig_id"`
	UserID    int64     `gorm:"index" json:"user_id"`
	Score     int       `gorm:"not null" json:"score"`
	Comment   string    `gorm:"type:text" json:"comment"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}
