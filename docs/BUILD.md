# Building Documentation Locally

This guide explains how to build the OnlineResamplers.jl documentation locally.

## Quick Start

### Option 1: Using Make (Recommended)

```bash
# Build documentation
make docs

# Build and open in browser
make docs-open

# Clean build directory
make clean
```

### Option 2: Using the Build Script

```bash
# Build and open documentation
./build_docs.sh
```

### Option 3: Using Julia Directly

```bash
julia --project=docs -e '
using Documenter, OnlineResamplers
makedocs(;
    modules = [OnlineResamplers],
    sitename = "OnlineResamplers.jl",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "User Guide" => "user_guide.md",
        "API Reference" => "api_reference.md",
        "Edge Cases & Limitations" => "edge_cases.md"
    ],
    source = "docs/src",
    build = "build"
)'
```

## Prerequisites

The documentation environment should already be set up. If you need to reinstall:

```bash
cd docs
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

If you need to add the local package to the docs environment:

```bash
cd docs
julia --project=. -e 'using Pkg; Pkg.develop(PackageSpec(path=".."))'
```

## Viewing the Documentation

After building, the documentation will be available at:

```
build/index.html
```

Open it in your browser:
- **macOS**: `open build/index.html`
- **Linux**: `xdg-open build/index.html`
- **Windows**: `start build/index.html`

Or use `make docs-open` to build and open automatically.

## Directory Structure

```
docs/
├── build.jl              # Legacy build script
├── make.jl               # Documenter.jl configuration
├── open.jl               # Script to open docs
├── Project.toml          # Docs environment
├── src/                  # Documentation source files
│   ├── index.md          # Home page
│   ├── tutorial.md       # Tutorial
│   ├── user_guide.md     # User guide
│   ├── api_reference.md  # API reference
│   └── edge_cases.md     # Edge cases & limitations
└── BUILD.md              # This file

build/                    # Generated documentation (gitignored)
├── index.html
├── tutorial.html
├── user_guide.html
├── api_reference.html
├── edge_cases.html
└── assets/
```

## Troubleshooting

### Package Not Found

If you see "Package OnlineResamplers not found":

```bash
cd docs
julia --project=. -e 'using Pkg; Pkg.develop(PackageSpec(path=".."))'
```

### Documenter Not Found

If you see "Package Documenter not found":

```bash
cd docs
julia --project=. -e 'using Pkg; Pkg.add("Documenter")'
```

### Build Warnings

The build may show warnings about invalid local links. These are expected when linking to files outside the docs directory (like examples). They don't affect the documentation quality.

### Clean Build

If you encounter issues, try a clean build:

```bash
make clean
make docs
```

## Continuous Integration

The documentation is automatically built and deployed to GitHub Pages on every push to `main` via GitHub Actions. See `.github/workflows/Documentation.yml` for details.

## Documentation Configuration

Key settings in `docs/make.jl`:

- **prettyurls**: Set to `false` for local builds (simple URLs like `index.html`)
- **checkdocs**: Set to `:none` to skip docstring checking
- **doctest**: Set to `false` to skip doctests
- **warnonly**: Warnings that won't fail the build

## Adding New Pages

1. Create a new `.md` file in `docs/src/`
2. Add it to the `pages` array in `docs/make.jl`:

```julia
pages = [
    "Home" => "index.md",
    "Tutorial" => "tutorial.md",
    "Your New Page" => "new_page.md",
    # ...
]
```

3. Rebuild the documentation

## Editing Documentation

1. Edit the relevant `.md` file in `docs/src/`
2. Rebuild: `make docs`
3. Refresh browser to see changes
4. Repeat until satisfied

For live development, you can use a file watcher or just rebuild manually after each change.

## Deployment

Documentation is deployed automatically via GitHub Actions. To deploy manually:

```julia
# Only do this if you have push access to the repository
using Documenter
deploydocs(
    repo = "github.com/femtotrader/OnlineResamplers.jl",
    devbranch = "main"
)
```

## Resources

- [Documenter.jl Documentation](https://documenter.juliadocs.org/)
- [Markdown Guide](https://www.markdownguide.org/)
- [Julia Documentation Guide](https://docs.julialang.org/en/v1/manual/documentation/)
