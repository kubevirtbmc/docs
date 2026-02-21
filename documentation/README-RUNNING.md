# Running Documentation Locally

This guide explains how to run the KubeVirtBMC documentation locally for preview.

## Running the Documentation

### Using Make

From the repository root:

```bash
make zensical-serve
```

This will:

- Create a virtual environment (if it doesn't exist)
- Install Zensical
- Start the development server with live reload

The documentation will be available at **http://127.0.0.1:8000** and will automatically reload when you change the markdown files.

## Cleanup

To remove the virtual environment and generated site:

```bash
make zensical-cleanup
```

This will remove:

- The `.venv` virtual environment directory
- The `site/` generated static site directory
