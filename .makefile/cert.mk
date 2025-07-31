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