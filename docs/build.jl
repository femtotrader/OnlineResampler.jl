#!/usr/bin/env julia

# Script to build documentation locally
# Usage: julia docs/build.jl

using Pkg

println("🔧 Setting up documentation environment...")

# Activate the docs environment
Pkg.activate(@__DIR__)

# Instantiate to install dependencies
println("📦 Installing documentation dependencies...")
Pkg.instantiate()

# Develop the main package so it's available
println("📚 Adding OnlineResamplers package...")
Pkg.develop(PackageSpec(path=joinpath(@__DIR__, "..")))

# Load the packages
println("📚 Loading OnlineResamplers...")
using OnlineResamplers

println("📚 Loading Documenter...")
using Documenter

println("🔨 Building documentation...")

# Build the docs
include("make.jl")

println("✅ Documentation built successfully!")
println("📖 Open docs/build/index.html in your browser to view the documentation")