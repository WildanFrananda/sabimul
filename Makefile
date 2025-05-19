# Makefile for Docker Laravel Project

.PHONY: help up down build dev watch test setup-existing

help: ## Show this help
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $1, $2}'

up: ## Start all containers
	docker compose up -d

down: ## Stop all containers
	docker compose down

build: ## Rebuild all containers
	docker compose build --no-cache

setup-existing: ## Setup for existing Laravel installation with Livewire
	@echo "Setting up Docker for existing Laravel installation..."
	docker compose exec node npm install
	docker compose exec node npm install -D tailwindcss postcss autoprefixer
	@echo "Setup completed successfully! Run 'make dev' to start Vite development server."

dev: ## Run npm dev
	docker compose exec node npm run dev

watch: ## Run npm watch
	docker compose exec node npm run watch

bash: ## Access app container shell
	docker compose exec app bash

node-bash: ## Access node container shell
	docker compose exec node bash

migrate: ## Run Laravel migrations
	docker compose exec app php artisan migrate

seed: ## Run Laravel seeders
	docker compose exec app php artisan db:seed

fresh: ## Refresh migrations and seed
	docker compose exec app php artisan migrate:fresh --seed
