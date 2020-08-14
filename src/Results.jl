baremodule Results

import Base: &, |, ∘, !
using Base: Some

export Result, Ok, Err
export is_ok, is_err
export to_option, to_result
export map, map_err
export unwrap

"""Represents an Ok result of computation."""
struct Ok{T}
	val::T
end

"""Represents an computation error."""
struct Err{E}
	err::E
end

"""
Synonym for `Union{Ok{T}, Err{E}}`.

As well as working with the `Result` combinators defined
below, `Result`s implement the following protocols:
 - `iterate`: Yields one `T` if the `Result` is `Ok`, yields nothing otherwise.
 - `length`: Returns 1 if the `Result` is `Ok`, 0 if `Err`
"""
const Result{T, E} = Union{Ok{T}, Err{E}}

"""Returns whether a `Result` is `Ok` or `Err`."""
function is_ok end
"""Returns whether a `Result` is `Ok` or `Err`."""
function is_err end

is_ok(r::Ok)::Bool = true
is_ok(r::Err)::Bool = false
is_err(r::Ok)::Bool = false
is_err(r::Err)::Bool = true

"""
Converts a `Result` to an `Option`, turning
`Ok` into `Some` and `Err` into `nothing`.
"""
function to_option end

function to_option(r::Ok{T})::Some{T} where {T} Some{T}(r.val) end
function to_option(r::Err)::Nothing nothing end

"""
Converts an `Option` into a `Result`, using the
supplied error value in place of a `nothing`.
"""
function to_result end

function to_result(o::Some{T}, err::Any)::Ok{T} where {T} Ok(o.value) end
function to_result(n::Nothing, err::E)::Err{E} where {E} Err(err) end
function to_result(n::Nothing, err::Function)::Err Err(func()) end

"""Map `f` over the contents of an `Ok` value, leaving an `Err` value untouched."""
function map end

map(f, r::Ok)::Ok = Ok(f(r.val))
map(f, r::Err)::Err = r

"""Map `f` over the contents of an `Err` value, leaving an `Ok` value untouched."""
function map_err end

map_err(f, r::Ok)::Ok = r
map_err(f, r::Err)::Err = Err(f(r.err))

"""
Unwrap an `Ok` value. Throws an error if `r` is `Err` instead.
"""
function unwrap end

function unwrap(r::Ok{T})::T where {T} r.val end
function unwrap(r::Err{E}) where {E}
	isa(r.err, Exception) ? throw(r.err) : error("unwrap() called on an Err")
end

"""Unwrap an `Ok` value, or return `default`"""
function unwrap(r::Result{T, E}, default::T)::T where {T, E}
	(r | Ok(default)).val
end

"""Unwrap an `Ok` value, or return the result of evaluating `default`"""
function unwrap(r::Result{T, E}, default::Function)::T where {T, E}
	if is_ok(r)
		r.val
	else
		default()
	end
end

function iterate(r::Ok{T})::Tuple{T, Nothing} where {T}
	(r.val, nothing)
end
function iterate(r::Err)::Nothing nothing end
function iterate(r::Result, state::Nothing)::Nothing nothing end
length(r::Ok)::Int = 1
length(r::Err)::Int = 0

"""
Binds `result` to the proceeding functions. While `result`
is `Ok`, its contents will be passed to each function in turn.
Any `Err` value will be returned immediately.

# Examples
```jldoctest
julia> Ok("Build") ∘ (val) -> Ok(string(val, " a ")) ∘ (val) -> Ok(string(val, "string"))
Ok{String}("Build a string")
julia> Err("Error") ∘ (val) -> Ok(string(val, " a ")) ∘ (val) -> Ok(string(val, "string"))
Err{String}("Error")
julia> Ok("Build") ∘ (val) -> Err("Error") ∘ function (val) println("long circuited"); Ok("value") end
Err{String}("Error")
```
"""
function ∘(result::Result, funcs::Function...)::Result
	for f in funcs
		is_err(result) && return result
		result = f(result.val)
		if !isa(result, Result)
			result = Ok(result)
		end
	end
	result
end

"""
Return the final `Ok` only if every argument is `Ok`.
Otherwise return the first `Err` value.

Values can be supplied either as `Result`s
or as functions that yield a `Result`.

# Examples
```jldoctest
julia> Ok("v1") & Ok("v2") & () -> Ok("v3")
Ok{String}("v3")

julia> Ok("v1") & () -> Err(2) & () -> Ok("v2")
Err{Int64}(2)
```
"""
function (&)(result::Result, rs::Union{Result, Function}...)::Result
	for r in rs
		is_err(result) && return result
		result = isa(r, Function) ? r() : r
	end
	result
end

"""
Return the first `Ok` value found. If no arguments
are `Ok`, return the final `Err` value.

Values can be supplied either as `Result`s
or as functions that yield a `Result`.

# Examples
```jldoctest
julia> Err("err1") | Ok("v2") | () -> Ok("v3")
Ok{String}("v2")
julia> Err("err1") | () -> Err("err2") | Err("err3")
Err{String}("err3")
```
"""
function (|)(result::Result, rs::Union{Result, Function}...)::Result
	for r in rs
		is_ok(result) && return result
		result = isa(r, Function) ? r() : r
	end
	result
end

"""Flip an Ok value to an Err value and vice versa."""
function (!)(result::Ok{T})::Err{T} where {T} Err(result.val) end
"""Flip an Ok value to an Err value and vice versa."""
function (!)(result::Err{T})::Ok{T} where {T} Ok(result.err) end

end #module