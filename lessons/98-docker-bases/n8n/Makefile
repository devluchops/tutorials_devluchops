.PHONY: up down stop clean logs shell help

help:
	@echo "Available commands:"
	@echo "  up       - Start n8n with docker compose"
	@echo "  down     - Stop and remove containers"
	@echo "  stop     - Stop containers without removing"
	@echo "  clean    - Remove containers, images and data"
	@echo "  logs     - Show container logs"
	@echo "  shell    - Open shell in running container"

up:
	mkdir -p data files
	docker compose up -d

down:
	docker compose down

stop:
	docker compose stop

clean: down
	docker compose down --rmi all --volumes
	rm -rf data files

logs:
	docker compose logs -f

shell:
	docker compose exec n8n /bin/sh