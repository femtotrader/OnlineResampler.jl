#!/bin/bash

# Script to build documentation locally for OnlineResamplers.jl
# Usage: ./build_docs.sh

echo "📚 Building OnlineResamplers.jl Documentation"
echo "=============================================="
echo ""

# Build the documentation
julia --project=docs -e '
using Documenter
using OnlineResamplers

println("🔨 Building documentation...")

makedocs(;
    modules = [OnlineResamplers],
    sitename = "OnlineResamplers.jl",
    format = Documenter.HTML(;
        prettyurls = false,  # Local build uses simple URLs
        canonical = "https://femtotrader.github.io/OnlineResamplers.jl",
        assets = String[],
        sidebar_sitename = false
    ),
    pages = [
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "User Guide" => "user_guide.md",
        "API Reference" => "api_reference.md",
        "Edge Cases & Limitations" => "edge_cases.md"
    ],
    source = "docs/src",
    build = "build",
    checkdocs = :none,
    doctest = false,
    warnonly = [:missing_docs, :cross_references]
)

println("\n✅ Documentation built successfully!")
println("📖 Location: build/index.html")
'

if [ $? -eq 0 ]; then
    echo ""
    echo "🌐 Opening documentation in browser..."
    open build/index.html
    echo ""
    echo "📂 Documentation files are in: build/"
    echo "📝 To rebuild, run: ./build_docs.sh"
else
    echo ""
    echo "❌ Build failed! Check the error messages above."
    exit 1
fi
