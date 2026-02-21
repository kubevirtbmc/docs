# Running Documentation Locally

This guide explains how to run the KubeVirtBMC documentation locally for preview.

## Running the Documentation

### Using Make

You can use the provided make target to set up a virtual environment and run the documentation server:

```bash
make mkdocs-serve
```

This will:

- Create a virtual environment (if it doesn't exist)
- Install all required dependencies
- Start the MkDocs development server with live reload

The documentation will be available at `http://127.0.0.1:8000` and will automatically reload when you make changes to the markdown files.

## Cleanup

To remove the virtual environment and generated files:

```bash
make mkdocs-cleanup
```

This will remove:

- The `.venv` virtual environment directory
- The `site/` generated static site directory
