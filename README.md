# Results.jl: Fallable computation for Julia

Results.jl provides a `Result` type for computation, as featured
in Rust, Haskell (as `Either`), OCaml, and many more.

The core Result type is simply an alias for `Union{Ok{T}, Err{E}}`,
allowing you to dispatch on `Ok` and `Err` variants separately.

## Operators

The following operators are overloaded for use with `Result` types:

| Operator | Description                                                                              |
| :---     | :---                                                                                     |
| `Base.&` | And/all operator, returns the first `Err` value. Supports closures for short-circuiting. |
| `Base.\|` | Or/any operator, returns the first `Ok` value. Supports closures for short-circuiting.   |
| `Base.∘` | Monadic bind, pipes functions that return `Result` together and returns errors early.    |
| `Base.!` | Flips Ok and Error values, turning `Result{T, E}` into `Result{E, T}`                    |

This library is distributed under the LGPL v3.0 license.

Pull requests or issues are welcome. This is my first Julia package, so I'm expecting some criticism.