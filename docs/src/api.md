```@meta
CurrentModule = Results
```
# API

`Results.jl` is structured into four modules:
 - [`Results.Types`](@ref types) defines the core types
 - [`Results.Functions`](@ref functions) defines functions for operating on `Result`s and `Option`s
 - [`Results.Macros`](@ref macros) defines macros for working with result types
 - [`Results.Collection`](@ref collection) defines Option interfaces for working with collections
 - `Results.Operators` defines operators for working with result types.

Important members of each module are re-exported, so the end user
usually does not need to import these modules directly. Operators
are not exported by default.
