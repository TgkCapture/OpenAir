package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	godotenv.Load()

	dsn := fmt.Sprintf(
		"postgresql://%s:%s@%s:%s/%s?sslmode=disable",
		getEnv("DB_USER", "openair"),
		getEnv("DB_PASSWORD", "changeme"),
		getEnv("DB_HOST", "localhost"),
		getEnv("DB_PORT", "5432"),
		getEnv("DB_NAME", "openair_db"),
	)

	db, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		log.Fatalf("connect: %v", err)
	}
	defer db.Close()

	// Admin user
	adminEmail := getEnv("ADMIN_EMAIL", "admin@openair.dev")
	adminPassword := getEnv("ADMIN_PASSWORD", "Admin@OpenAir2026")

	hash, err := bcrypt.GenerateFromPassword([]byte(adminPassword), 12)
	if err != nil {
		log.Fatalf("hash: %v", err)
	}

	_, err = db.Exec(context.Background(), `
		INSERT INTO users (email, password_hash, full_name, role, is_active)
		VALUES ($1, $2, 'OpenAir Admin', 'admin', true)
		ON CONFLICT (email) DO UPDATE
		SET password_hash = $2, role = 'admin', is_active = true, updated_at = NOW()`,
		adminEmail, string(hash),
	)
	if err != nil {
		log.Fatalf("insert admin: %v", err)
	}

	fmt.Printf("✅ Admin user ready\n")
	fmt.Printf("   Email:    %s\n", adminEmail)
	fmt.Printf("   Password: %s\n", adminPassword)
	fmt.Println()

	// Seed channels if empty
	var count int
	db.QueryRow(context.Background(), `SELECT COUNT(*) FROM channels`).Scan(&count)
	if count == 0 {
		_, err = db.Exec(context.Background(), `
			INSERT INTO channels (name, type, stream_url, is_premium, is_active, sort_order) VALUES
			('Test TV 1', 'tv', 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8', false, true, 1),
			('Test TV 2', 'tv', 'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8', false, true, 2),
			('Test Radio 1', 'radio', 'https://stream.radioparadise.com/aac-128', false, true, 1),
			('Test Radio 2', 'radio', 'https://ice1.somafm.com/groovesalad-128-aac', false, true, 2)`)
		if err != nil {
			log.Printf("seed channels: %v", err)
		} else {
			fmt.Println("✅ Seeded 4 test channels")
		}
	}

	// Seed VOD if empty
	db.QueryRow(context.Background(), `SELECT COUNT(*) FROM content`).Scan(&count)
	if count == 0 {
		_, err = db.Exec(context.Background(), `
			INSERT INTO content (title, description, type, file_url, thumbnail_url, category, duration_secs, is_premium, is_published) VALUES
			('Big Buck Bunny', 'Classic open source animation', 'vod',
			 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
			 'https://peach.blender.org/wp-content/uploads/title_anouncement.jpg?x11217',
			 'Entertainment', 596, false, true),
			('Elephant Dream', 'First Blender open movie', 'vod',
			 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
			 null, 'Documentary', 654, false, true),
			('For Bigger Blazes', 'Action promo clip', 'vod',
			 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
			 null, 'Entertainment', 15, false, true)`)
		if err != nil {
			log.Printf("seed vod: %v", err)
		} else {
			fmt.Println("✅ Seeded 3 test VOD items")
		}
	}

	// Seed podcast if empty
	db.QueryRow(context.Background(), `SELECT COUNT(*) FROM podcasts`).Scan(&count)
	if count == 0 {
		var podcastID string
		err = db.QueryRow(context.Background(), `
			INSERT INTO podcasts (title, description, author, category, is_premium, is_active)
			VALUES ('Tech Talk', 'Weekly technology discussions', 'OpenAir Team', 'Technology', false, true)
			RETURNING id`).Scan(&podcastID)
		if err != nil {
			log.Printf("seed podcast: %v", err)
		} else {
			db.Exec(context.Background(), `
				INSERT INTO episodes (podcast_id, title, audio_url, duration_secs, episode_number, is_premium) VALUES
				($1, 'Episode 1 - Getting Started', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', 240, 1, false),
				($1, 'Episode 2 - Deep Dive', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', 360, 2, false)`,
				podcastID)
			fmt.Println("✅ Seeded 1 podcast with 2 episodes")
		}
	}

	fmt.Println("\n🎉 Seed complete!")
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}