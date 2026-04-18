DB_URL=postgres://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable

migrate-up:
	migrate -path ./migrations -database "$(DB_URL)" up

migrate-down:
	migrate -path ./migrations -database "$(DB_URL)" down

migrate-create:
	migrate create -ext sql -dir ./migrations -seq $(name)

seed:
	psql "$(DB_URL)" -f ./migrations/seed.sql

.PHONY: migrate-up migrate-down migrate-create seed