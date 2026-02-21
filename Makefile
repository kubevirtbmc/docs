.PHONY: mkdocs-serve
mkdocs-serve: ## Run MkDocs development server.
	@./scripts/run-mkdocs.sh

.PHONY: mkdocs-cleanup
mkdocs-cleanup: ## Clean up MkDocs virtual environment and generated files.
	@./scripts/cleanup-mkdocs.sh
