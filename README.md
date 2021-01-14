# Results.jl: Fallable computation for Julia

Results.jl provides a `Result` and `Option` type for computation,
as featured in Rust, Haskell (as `Either`), OCaml, and many more.

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

## Operators

The following operators are overloaded for use with `Result` types:

| Operator | Description                                                                              |
| :---     | :---                                                                                     |
| `Base.&` | And/all operator, returns the first `Err` value. Supports closures for lazy evaluation.  |
| `Base.\|` | Or/any operator, returns the first `Ok` value. Supports closures for lazy evaluation.   |
| `Base.!` | Flips Ok and Error values, turning `Result{T, E}` into `Result{E, T}`.                   |

In addition, three new operators are introduced for use with `Result`s and `Option`s:
←→⊗⋄
| Operator | Description                                                                              |
| :---     | :---                                                                                     |
| `←`      | `try_map`: applies a function to the inside of a result type.                            |
| `→`      | Argument-flipped version of `try_map`.
| `⊗`      | `and_then`/monadic bind: connects fallable functions together and returns errors early.  |

These operators are not exported by default.

This library is distributed under the LGPL v3.0 license.

Pull requests and issues are welcome. This is my first Julia package, so I'm expecting some criticism.
