#!/usr/env julia

push!(LOAD_PATH, "../src/")

using Documenter, Results

DocMeta.setdocmeta!(Results, :DocTestSetup, :(using Rslt))
makedocs(sitename="Results.jl Documentation")
