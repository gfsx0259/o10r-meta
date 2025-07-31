.DEFAULT_GOAL := all

MAKEFLAGS += --no-print-directory
PROJECT_DIRS := $(wildcard projects/*)

include .makefile/env.mk
include .makefile/cert.mk
include .makefile/hosts.mk
include .makefile/clear.mk

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

fetch:
	git submodule update --init --recursive --remote

summary:
	@echo "Built and launched successfully, check it out 🎈 \n"
	@git submodule foreach "docker compose ps 2> /dev/null || echo \"Possibly, application is not running\""