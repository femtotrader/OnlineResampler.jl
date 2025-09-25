#!/usr/bin/env julia

# Script to open the generated documentation in the default browser
# Usage: julia docs/open.jl

using Pkg

docs_path = joinpath(@__DIR__, "build", "index.html")

if isfile(docs_path)
    println("📖 Opening documentation at: $docs_path")

    # Try to open with the system default browser
    if Sys.isapple()
        run(`open $docs_path`)
    elseif Sys.islinux()
        run(`xdg-open $docs_path`)
    elseif Sys.iswindows()
        run(`start $docs_path`)
    else
        println("❌ Could not detect operating system. Please manually open: $docs_path")
    end
else
    println("❌ Documentation not found at: $docs_path")
    println("📚 Run 'julia docs/build.jl' first to build the documentation")
end