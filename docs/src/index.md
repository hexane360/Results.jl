```@meta
CurrentModule = Results
```

# Results.jl Documentation

Results.jl provides a [`Result`](@ref) and [`Option`](@ref) type for computation,
as featured in Rust, Haskell (as `Either`), OCaml, and many more.

The core [`Result`](@ref) type is simply an alias for `Union{Ok{T}, Err{E}}`,
allowing you to dispatch on [`Ok`](@ref) and [`Err`](@ref) variants separately.
The [`Option`](@ref) type is defined as `Union{Base.Some{T}, Base.Nothing}`,
allowing for easy compatibility with other libraries.

For a quick overview of the supported functions, visit the [Quick Reference](@ref).
For a detailed description of each function, visit the [API](@ref).
A tutorial and examples are under construction.

## Outline

```@contents
Pages = ["index.md", "quickref.md", "api.md", "api/Types.md",
         "api/Functions.md", "api/Macros.md", "api/Collection.md"]
Depth = 5
```

## Index

```@index

```
