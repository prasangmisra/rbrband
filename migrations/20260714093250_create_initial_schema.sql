-- Migration: create_initial_schema
-- Generated: 2026-07-14 13:32:50 UTC
-- This migration was auto-generated from GORM models

CREATE TABLE "band_memberships" ("id" bigserial,"band_id" bigint,"user_id" bigint,"role" text DEFAULT 'member',"joined_at" timestamptz,"left_at" timestamptz,PRIMARY KEY ("id"));
CREATE INDEX IF NOT EXISTS "idx_band_memberships_user_id" ON "band_memberships" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_band_memberships_band_id" ON "band_memberships" ("band_id");
CREATE TABLE "bands" ("id" bigserial,"name" text,"slug" text,"bio" text,"city" text,"country" text,"owner_id" bigint NOT NULL,"created_at" timestamptz,"rating_avg" numeric(5,2) DEFAULT 0,"rating_count" bigint DEFAULT 0,PRIMARY KEY ("id"));
CREATE UNIQUE INDEX IF NOT EXISTS "idx_bands_slug" ON "bands" ("slug");
CREATE INDEX IF NOT EXISTS "idx_bands_name" ON "bands" ("name");
CREATE TABLE "gigs" ("id" bigserial,"band_id" bigint,"organizer_id" bigint,"title" text,"description" text,"venue" text,"city" text,"country" text,"start_at" timestamptz,"end_at" timestamptz,"created_at" timestamptz,"rating_avg" numeric(5,2) DEFAULT 0,"rating_count" bigint DEFAULT 0,"processed" boolean DEFAULT false,PRIMARY KEY ("id"));
CREATE INDEX IF NOT EXISTS "idx_gigs_organizer_id" ON "gigs" ("organizer_id");
CREATE INDEX IF NOT EXISTS "idx_gigs_band_id" ON "gigs" ("band_id");
CREATE TABLE "ratings" ("id" bigserial,"gig_id" bigint,"user_id" bigint,"score" bigint NOT NULL,"comment" text,"created_at" timestamptz,PRIMARY KEY ("id"));
CREATE INDEX IF NOT EXISTS "idx_ratings_user_id" ON "ratings" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_ratings_gig_id" ON "ratings" ("gig_id");
CREATE TABLE "users" ("id" bigserial,"email" text,"password_hash" text,"display_name" text,"created_at" timestamptz,"rating_avg" numeric(5,2) DEFAULT 0,"rating_count" bigint DEFAULT 0,PRIMARY KEY ("id"));
CREATE UNIQUE INDEX IF NOT EXISTS "idx_users_email" ON "users" ("email");
