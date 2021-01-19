```@meta
CurrentModule = Results
```

# Quick Reference

## Functions

The functions provided fall into a few main types:

 - Input functions convert values into result types
 - Output functions convert result types back into values
 - Transform functions operate on result types
 - Predicate functions return booleans
 - Collection functions provide an interface to access collections
   without exceptions.

### Input Functions

| Works on | Function                     | Description                                                                                                                                                |
| :------- | :------------                | :------------------------------------                                                                                                                      |
| Result   | [`to_result`](@ref)          | Convert nullable to [`Result`](@ref)                                                                                                                       |
| Option   | [`to_option`](@ref)          | Convert nullable to [`Option`](@ref)                                                                                                                       |

### Output Functions

| Works on | Function                     | Description                                                                                                                                                |
| :------- | :------------                | :------------------------------------                                                                                                                      |
| Both     | [`unwrap`](@ref)             | Return inner value or throw an error                                                                                                                       |
| Both     | [`unwrap_or`](@ref)          | Return inner value or default value                                                                                                                        |
| Both     | [`to_nullable`](@ref)        | Convert [`Result`](@ref)/[`Option`](@ref) into a nullable value                                                                                            |

### Transform Functions

| Works on | Function                     | Description                                                                                                                                                |
| :------- | :------------                | :------------------------------------                                                                                                                      |
| Result   | [`ok`](@ref)                 | Convert [`Result`](@ref) to [`Option`](@ref)                                                                                                               |
| Option   | [`ok_or`](@ref)              | Convert [`Option`](@ref) to [`Result`](@ref)                                                                                                               |
| Both     | [`try_map`](@ref)            | Map a function over one or more result values                                                                                                              |
| Result   | [`map_err`](@ref)            | Map a function over an error value                                                                                                                         |
| Both     | [`and_then`](@ref)           | Chain fallable functions together                                                                                                                          |
| Both     | [`try_collect`](@ref)        | Collect an iterable of results into a result containing an array                                                                                           |
| Option   | [`try_collect_option`](@ref Functions.try_collect_option) | Version of [`try_collect`](@ref) specialized for [`Option`](@ref). Unexported.                                                |
| Result   | [`try_collect_result`](@ref Functions.try_collect_result) | Version of [`try_collect`](@ref) specialized for [`Result`](@ref). Unexported.                                                |
| Both     | [`flatten`](@ref)            | Flatten a nested result type                                                                                                                               |

### Predicate Functions

| Works on | Function                     | Description                                                                                                                                                |
| :------- | :------------                | :------------------------------------                                                                                                                      |
| Result   | [`is_ok`](@ref)              | Return if a [`Result`](@ref) is [`Ok`](@ref)                                                                                                               |
| Result   | [`is_err`](@ref)             | Return if a [`Result`](@ref) is [`Err`](@ref)                                                                                                              |
| Option   | [`is_some`](@ref)            | Return if an [`Option`](@ref) is [`Some`](https://docs.julialang.org/en/v1/base/base/#Base.Some).                                                          |
| Option   | [`is_none`](@ref)            | Return if an [`Option`](@ref) is [`None`](@ref)                                                                                                            |
| Both     | [`has_val`](@ref)            | Return if a result type is a success.                                                                                                                      |

### Collection Functions

| Works on | Function                     | Description                                                                                                                                                |
| :------- | :------------                | :------------------------------------                                                                                                                      |
| Option   | [`try_pop!`](@ref)           | Try to `pop!` a value from a collection. Also works with [`Iterators.Stateful`](https://docs.julialang.org/en/v1/base/iterators/#Base.Iterators.Stateful). |
| Option   | [`try_get`](@ref)            | Try to `get` a value from a collection                                                                                                                     |
| Option   | [`try_peek`](@ref)           | Try to `peek` a value from an iterator                                                                                                                     |
| Option   | [`try_first`](@ref)          | Try to get the first value in a collection                                                                                                                 |
| Option   | [`try_last`](@ref)           | Try to get the last value in a collection                                                                                                                  |

## Macros

| Macro                   | Description                                                                                                       |
| :------------           | :---------                                                                                                        |
| [`@unwrap_or`](@ref)    | Short-circuiting version of `unwrap_or`, which allows for the embedding of control statements.                    |
| [`@try_unwrap`](@ref)   | Unwraps a value or bubbles an error upstream.                                                                     |
| [`@some_if`](@ref)      | Evaluates and returns [`Some`](https://docs.julialang.org/en/v1/base/base/#Base.Some) if a predicate is satisfied |
| [`@catch_result`](@ref) | Catch an exception and return it as a [`Result`](@ref) instead                                                    |
| [`@if_let`](@ref)       | Conditionally unwrap a value inside of a block                                                                    |
| [`@while_let`](@ref)    | Run a loop while successful                                                                                       |

## Operators

The following operators are overloaded for use with `Result` types:

| Operator           | Description                                                                                     |
| :---               | :---                                                                                            |
| [`Base.:&`](@ref)  | And/all operator, returns the first [`Err`](@ref) value. Supports closures for lazy evaluation. |
| [`Base.:\|`](@ref) | Or/any operator, returns the first [`Ok`](@ref) value. Supports closures for lazy evaluation.   |
| [`Base.:!`](@ref)  | Flips Ok and Error values, turning `Result{T, E}` into `Result{E, T}`.                          |

In addition, three new operators are introduced for use with `Result`s and `Option`s:

| Operator                | Description                                                                                     |
| :---                    | :---                                                                                            |
| [`←`](@ref Functions.:←)  | [`try_map`](@ref): applies a function to the inside of a result type.                           |
| [`→`](@ref Functions.:→)  | Argument-flipped version of [`try_map`](@ref).                                                  |
| [`⊗`](@ref Functions.:⊗) | [`and_then`](@ref)/monadic bind: connects fallable functions together and returns errors early. |

These new operators are not exported by default.
