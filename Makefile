.PHONY: zensical-serve
zensical-serve: ## Run Zensical development server (uses zensical.toml).
	@./scripts/run-zensical.sh

.PHONY: zensical-cleanup
zensical-cleanup: ## Remove virtual environment and generated site.
	@./scripts/cleanup.sh
