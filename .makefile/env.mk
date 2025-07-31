.env:
	@echo "[*] Creating .env from .env.example"
	@cp .env.example .env

include .env
export $(shell [ -f .env ] && grep '=' .env | sed 's/=.*//')