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
	@julia --project=docs -e '\
		using Documenter, OnlineResamplers; \
		makedocs(; \
			modules = [OnlineResamplers], \
			sitename = "OnlineResamplers.jl", \
			format = Documenter.HTML(; \
				prettyurls = false, \
				canonical = "https://femtotrader.github.io/OnlineResamplers.jl", \
				assets = String[], \
				sidebar_sitename = false \
			), \
			pages = [ \
				"Home" => "index.md", \
				"Tutorial" => "tutorial.md", \
				"User Guide" => "user_guide.md", \
				"API Reference" => "api_reference.md", \
				"Edge Cases & Limitations" => "edge_cases.md", \
				"⚠️ AI Transparency" => "ai_transparency.md" \
			], \
			source = "docs/src", \
			build = "build", \
			checkdocs = :none, \
			doctest = false, \
			warnonly = [:missing_docs, :cross_references] \
		)'
	@echo "✅ Documentation built successfully!"
	@echo "📂 Documentation files are in: build/"

# Build and open documentation
docs-open: docs
	@echo "📖 Opening documentation..."
	@open build/index.html

# Run tests
test:
	@echo "🧪 Running tests..."
	julia --project=. -e "using Pkg; Pkg.test()"

# Clean built documentation
clean:
	@echo "🧹 Cleaning documentation build directory..."
	rm -rf build/
	@echo "✅ Documentation build directory cleaned"