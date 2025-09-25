# OnlineResamplers.jl Documentation

Documentation build system for OnlineResamplers.jl using Documenter.jl.

## Quick Build

```bash
# Build and view documentation
make docs-open

# Or manually:
julia docs/build.jl
julia docs/open.jl
```

## Structure

```
docs/
├── Project.toml          # Documentation dependencies
├── Manifest.toml         # Dependency lockfile
├── src/                  # Documentation source (Markdown)
├── build/                # Generated HTML (auto-generated)
├── make.jl              # Documenter.jl configuration
├── build.jl             # Build script
└── open.jl              # Browser opener script
```

## Dependencies

This documentation has its own isolated environment:
- **Documenter.jl** - HTML documentation generation
- **OnlineResamplers.jl** - Main package (as development dependency)

## Other Commands

```bash
make docs        # Build only
make clean       # Clean build directory
make test        # Run package tests
make help        # Show all commands
```