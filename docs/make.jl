#!/usr/env julia

push!(LOAD_PATH, "../src/")

using Documenter
using Results
#using Results: ←, →, ⊗, try_collect_result, try_collect_option

DocMeta.setdocmeta!(Results, :DocTestSetup,
                    :(using Results;
                      using Results: ⊗, ←, →, strip_result_type))

makedocs(
	modules = [Results],
	sitename = "Results.jl Documentation",
	authors = "Colin Gilgenbach",
	pages = [
		"Home" => "index.md",
		"Quick Reference" => "quickref.md",
		"API" => "api.md",
	],
	#checkdocs = true,
	linkcheck = true,
)
