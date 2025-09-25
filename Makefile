# OnlineResampler.jl Makefile

.PHONY: help docs docs-open test clean

# Default target
help:
	@echo "OnlineResampler.jl - Available Commands:"
	@echo ""
	@echo "  docs        - Build documentation locally"
	@echo "  docs-open   - Build and open documentation in browser"
	@echo "  test        - Run tests"
	@echo "  clean       - Clean built documentation"
	@echo "  help        - Show this help message"
	@echo ""

# Build documentation
docs:
	@echo "🔨 Building documentation..."
	julia docs/build.jl

# Build and open documentation
docs-open: docs
	@echo "📖 Opening documentation..."
	julia docs/open.jl

# Run tests
test:
	@echo "🧪 Running tests..."
	julia --project=. -e "using Pkg; Pkg.test()"

# Clean built documentation
clean:
	@echo "🧹 Cleaning documentation build directory..."
	rm -rf docs/build/
	@echo "✅ Documentation build directory cleaned"