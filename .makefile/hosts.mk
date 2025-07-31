hosts:
	@echo "[*] Adding domains to /etc/hosts if missing"
	@if ! grep -q ".o10r.io" /etc/hosts; then \
		echo $(HOSTS_LINE) | sudo tee -a /etc/hosts > /dev/null; \
		echo "✔ Hosts added"; \
	else \
		echo "Hosts already present"; \
	fi