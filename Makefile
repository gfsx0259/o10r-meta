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

bootstrap-cert:
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

summary:
	@echo "Built and launched successfully, check it out 🎈 \n"
	@git submodule foreach "docker compose ps 2> /dev/null || echo \"Possibly, application is not running\""

clean:
	@echo "Stop docker containers..."
	@echo "Clear docker volumes..."
	@(git submodule foreach docker compose down -v > /dev/null 2>&1) && echo "Successfully\n" || echo "It is not possible to call down for some projects, just skip"
	@echo "Clear projects..."
	@(git submodule deinit -f . > /dev/null 2>&1) && echo "Successfully\n" || echo "Nothing to clear, just skip"
	@echo "Clear images..."
	@(docker rmi $$(docker images --format "{{.Repository}}:{{.Tag}}" | grep 'o10r') > /dev/null 2>&1) && echo "Successfully\n"  || echo "some error"

