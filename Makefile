.PHONY: help up down start stop restart logs pull clean status

# Load variables from .env (IMAGE_NAME, CONTAINER_NAME, TZ, HERMES_UID, HERMES_GID)
include .env

.DEFAULT_GOAL := help

CONTAINER=$(CONTAINER_NAME)

# Print all targets with their ## descriptions
help:
	@echo "Hermes Docker Compose commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Start all containers (first run or after down)
	docker compose up -d

down: ## Stop and remove all containers
	docker compose down

start: ## Start stopped containers
	docker compose start

stop: ## Stop running containers (without removing them)
	docker compose stop

restart: ## Restart containers
	docker compose restart

logs: ## Stream logs from all containers
	docker compose logs -f

status: ## Show container status
	docker compose ps

# Also removes named volumes (persistent data)
clean: down ## Stop containers and remove volumes
	docker compose down -v

# Open a root shell — useful for inspecting the container filesystem
sh-root:
	docker exec -it $(CONTAINER) sh

# Open an interactive bash shell as the hermes user
bash:
	docker exec -it -u hermes $(CONTAINER) bash -i

# Build for ARM64 (Raspberry Pi); image tagged with IMAGE_NAME from .env
build:
	docker buildx build -t $(IMAGE_NAME) .
