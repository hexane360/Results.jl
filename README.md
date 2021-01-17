Results.jl: Fallable computation for Julia
-------------

Results.jl provides a `Result` and `Option` type for computation,
as featured in Rust, Haskell (as `Either`), OCaml, and many more.

[![](https://img.shields.io/badge/docs-stable-blue)][docs-url] ![](https://img.shields.io/github/last-commit/hexane360/Results.jl) ![](https://img.shields.io/github/release-date/hexane360/Results.jl)

This library is distributed under the LGPL v3.0 license.

## About

The core `Result` type is simply an alias for `Union{Ok{T}, Err{E}}`,
allowing you to dispatch on `Ok` and `Err` variants separately.
The `Option` type is defined as `Union{Base.Some{T}, Base.Nothing}`,
allowing for easy compatibility with other libraries.

## Why?

`Results.jl` attempts to provide a compromise between strict type-safety
and maximum ergonomics. Compared to exceptions, `Results.jl` is faster.
Compared with a bare nullable type `Union{T, Nothing}`, `Results.jl` is
more correct. And compared to other libraries, `Results.jl` aims to be
more complete and more ergonomic.

## Documentation

Check out the documentation on [JuliaHub][docs-url].

-----

Pull requests and issues are welcome. This is my first Julia package, so I'm expecting some criticism.

[docs-url]: https://juliahub.com/docs/Results/
