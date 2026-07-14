package entity

import "time"

type Gig struct {
	ID          int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	BandID      *int64    `gorm:"index" json:"band_id"`
	OrganizerID *int64    `gorm:"index" json:"organizer_id"`
	Title       string    `gorm:"type:text" json:"title"`
	Description string    `gorm:"type:text" json:"description"`
	Venue       string    `gorm:"type:text" json:"venue"`
	City        string    `gorm:"type:text" json:"city"`
	Country     string    `gorm:"type:text" json:"country"`
	StartAt     time.Time `json:"start_at"`
	EndAt       time.Time `json:"end_at"`
	CreatedAt   time.Time `gorm:"autoCreateTime" json:"created_at"`
	RatingAvg   float64   `gorm:"type:numeric(5,2);default:0" json:"rating_avg"`
	RatingCount int64     `gorm:"default:0" json:"rating_count"`
	Processed   bool      `gorm:"default:false" json:"processed"`
}
