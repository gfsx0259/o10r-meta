MAKEFLAGS += --no-print-directory
PROJECT_DIRS := $(wildcard projects/*)

UNAME_S := $(shell uname -s)
ARCH := $(shell uname -m)

ifeq ($(UNAME_S),Darwin)
  ifeq ($(ARCH),arm64)
    MKCERT_BINARY := https://dl.filippo.io/mkcert/latest?for=darwin/arm64
  else
    MKCERT_BINARY := https://dl.filippo.io/mkcert/latest?for=darwin/amd64
  endif
else
  MKCERT_BINARY := https://dl.filippo.io/mkcert/latest?for=linux/amd64
endif

HOSTS_LINE := "127.0.0.1 welcome.o10r.io ory.o10r.io project.o10r.io hydra.o10r.io hydra-admin.o10r.io hydra-consent.o10r.io"

.env:
	@echo "[*] Creating .env from .env.example"
	@cp .env.example .env

include .env
export $(shell [ -f .env ] && grep '=' .env | sed 's/=.*//')

all: .env network bootstrap-cert fetch
	@docker compose up -d
	@for dir in $(PROJECT_DIRS); do \
    	if [ -f $$dir/Makefile ]; then \
			echo ">>> Building $$dir"; \
			$(MAKE) -C $$dir; \
		fi \
     	done
	@$(MAKE) summary

network:
	@if ! docker network inspect $(DOCKER_NETWORK_NAME) >/dev/null 2>&1; then \
		docker network create $(DOCKER_NETWORK_NAME); \
	fi

bootstrap-cert: bootstrap-deps
	@echo "Install certificate generation utility"
	@cd cert; curl -q -o mkcert -JLO $(MKCERT_BINARY); chmod +x mkcert; sudo cp mkcert /usr/local/bin/mkcert
	@echo "Create root certificate authority"
	@mkcert -install
	@echo "Generate application wildcard certificate"
	@cd cert; mkcert "$(APP_WILDCARD_DOMAIN)"
	@touch bootstrap-cert

bootstrap-deps:
	@if [ "$(UNAME_S)" = "Darwin" ]; then \
		brew install nss; \
	else \
    	sudo apt install libnss3-tools; \
	fi
	@touch bootstrap-deps

fetch:
	git submodule update --init --recursive --remote

hosts:
	@echo "[*] Adding domains to /etc/hosts if missing"
	@if ! grep -q "ory.o10r.io" /etc/hosts; then \
		echo $(HOSTS_LINE) | sudo tee -a /etc/hosts > /dev/null; \
		echo "✔ Hosts added"; \
	else \
		echo "ℹ Hosts already present"; \
	fi

summary:
	@echo "Built and launched successfully, check it out 🎈 \n"
	@git submodule foreach "docker compose ps 2> /dev/null || echo \"Possibly, application is not running\""

clear: clear-containers clear-images clear-projects

clear-containers:
	@git submodule foreach docker compose down -v && echo "Successfully\n" || echo "It is not possible to call down for some projects, just skip"

clear-images:
	@for dir in $(PROJECT_DIRS); do \
		project=$$(basename $$dir); \
		echo ">>> Removing images for project: $$project"; \
		ids=$$(docker images -q --filter "label=com.docker.compose.project=$$project"); \
		if [ -n "$$ids" ]; then \
			docker rmi -f $$ids; \
		else \
			echo "No images found for $$project"; \
		fi \
    done

clear-projects:
	@git submodule deinit -f . && echo "Successfully\n" || echo "Nothing to clear, just skip"