#!/usr/env julia

push!(LOAD_PATH, "../src/")

using Documenter
using Results

DocMeta.setdocmeta!(Results, :DocTestSetup,
                    :(using Results))
DocMeta.setdocmeta!(Results.Types, :DocTestSetup,
                    :(using Results; using Results.Types))
DocMeta.setdocmeta!(Results.Functions, :DocTestSetup,
                    :(using Results; using Results.Functions; using Results.Operators))
DocMeta.setdocmeta!(Results.Macros, :DocTestSetup,
                    :(using Results; using Results.Macros))
DocMeta.setdocmeta!(Results.Collection, :DocTestSetup,
                    :(using Results; using Results.Collection))

pages = [
	"Home" => "index.md",
	"Quick Reference" => "quickref.md",
	"API" => [
		"Results" => "api.md",
		"Results.Types" => "api/Types.md",
		"Results.Functions" => "api/Functions.md",
		"Results.Macros" => "api/Macros.md",
		"Results.Collection" => "api/Collection.md",
	],
]

makedocs(
	modules = [Results],
	sitename = "Results.jl Documentation",
	authors = "Colin Gilgenbach",
	pages = pages,
	#checkdocs = true,
	linkcheck = true,
)

deploydocs(
	repo = "github.com/hexane360/Results.jl.git",
	branch = "gh-pages",
	devbranch = "master",
	devurl = "dev"
)
