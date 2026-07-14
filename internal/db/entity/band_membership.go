package entity

import "time"

type BandMembership struct {
	ID       int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	BandID   int64      `gorm:"index" json:"band_id"`
	UserID   int64      `gorm:"index" json:"user_id"`
	Role     string     `gorm:"type:text;default:'member'" json:"role"`
	JoinedAt time.Time  `gorm:"autoCreateTime" json:"joined_at"`
	LeftAt   *time.Time `json:"left_at"`
}
