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