using ..Types
using ..Types: UnwrapError

# input functions
export to_option, to_result
# output functions
export unwrap, unwrap_or, to_nullable

"""
    to_option(value::Union{T, Nothing})::Option{T}
    to_option(value::Result)::Option

Converts a nullable value to an `Option`. Also
converts a `Result` to an `Option`, turning
`Ok` into `Some` and `Err` into `None`.

# Examples
```jldoctest
julia> to_option("value")
Some("value")
julia> to_option(Some(5))
Some(Some(5))
julia> to_option(nothing) |> println
nothing
```
"""
function to_option end

function to_option(val::T)::Some{T} where {T} Some(val) end
function to_option(::None)::None none end

function to_option(r::Ok{T})::Some{T} where {T} Some(r.value) end
function to_option(::Err)::None none end

"""
    to_result(value::T, err)::Ok{T}
    to_result(value::None, err::E)::Err{E}
    to_result(value::None, err::Function)::Err

Converts a nullable value to a `Result`, using
the supplied error value in place of a `nothing`.
Also converts an `Option` into a `Result`, turning
`Some` into `Ok` and `None` into `Err`.

# Examples
```jldoctest
julia> to_result("value", "error")
Ok("value")
julia> to_result(nothing, "error")
Err("error")
julia> to_result("value", () -> println("lazily calculates errors"))
Ok("value")
julia> to_result(Ok(5), nothing)
Ok(Ok(5))
```
"""
function to_result end

function to_result(val::T, err)::Ok{T} where {T} Ok(val) end
function to_result(::None, err::E)::Err{E} where {E} Err(err) end
function to_result(::None, err::Function)::Err Err(err()) end

"""
    to_result(err)::Function

Partially-applied version of `to_result`.

# Examples
```jldoctest
julia> 5 |> to_result("error")
Ok(5)
julia> nothing |> to_result("error")
Err("error")
```
"""
to_result(err)::Function = val -> to_result(val, err)

"""
    to_nullable(val::Option{T})::Union{T, Nothing}
    to_nullable(val::Result{T, E})::Union{T, Nothing}

Convert a `Result{T, E}` or `Option{T}` into a simple nullable
value `Union{T, Nothing}`. Note that this may lose structure
(this transformation is non-injective, as `Some(nothing)` and
`nothing` map to the same value).
"""
function to_nullable end

function to_nullable(val::Some{T})::T where {T} val.value end
function to_nullable(::None)::Nothing nothing end
function to_nullable(val::Ok{T})::T where {T} val.value end
function to_nullable(::Err)::Nothing nothing end

"""
    unwrap(o::Option{T})::T
    unwrap(r::Result{T, E})::T
    unwrap(o::Union{Option, Result}, error::Function)
    unwrap(o::Union{Option, Result}, error::Exception)
    unwrap(o::Union{Option, Result}, error::String)

Unwrap an `Ok` value. Throws an error if `r` is `Err` instead.

In the two argument form, `error` is raised if it is an `Exception`.
If it is a string, it is passed as a message to [`UnwrapError`](@ref).
If it is a function, it is called with an error value to produce an error.

# Examples
```jldoctest; filter = r"Array{\\S+,1}|Vector{\\S+}"
julia> unwrap(Ok(5))
5
julia> unwrap(Err(0))
ERROR: Results.Types.UnwrapError("unwrap() called on an Err: 0")
julia> unwrap(none)
ERROR: Results.Types.UnwrapError("unwrap() called on None")
julia> unwrap(none, "value is none")
ERROR: Results.Types.UnwrapError("value is none")
julia> unwrap(nothing, BoundsError([1,2]))
ERROR: BoundsError: attempt to access 2-element Array{Int64,1}
julia> unwrap(Err(5), v -> "Error value '" * string(v) * "'")
ERROR: Results.Types.UnwrapError("Error value '5'")
```
"""
function unwrap end

function unwrap(r::Ok{T})::T where {T} r.value end
function unwrap(r::Err{E})::Union{} where {E}
	throw(isa(r.error, Exception)
		? r.error
		: UnwrapError(string("unwrap() called on an Err: ", repr(r.error)))
	)
end
function unwrap(s::Some{T})::T where {T} s.value end
function unwrap(::None)::Union{}
	throw(UnwrapError("unwrap() called on None"))
end

function unwrap(r::Ok{T}, error)::T where {T} r.value end
function unwrap(r::Some{T}, error)::T where {T} r.value end
function unwrap(::Union{Err, None}, error::Exception)::Union{} throw(error) end
function unwrap(v::Err, error::Function)::Union{} unwrap(v, error(v.error)) end
function unwrap(v::None, error::Function)::Union{} unwrap(v, error(v)) end
function unwrap(::Union{Err, None}, error::String)::Union{}
	throw(UnwrapError(string(error)))
end

"""
    unwrap_or(o::Option{T}, default)::T
    unwrap_or(r::Result{T, E}, default)::T

Unwrap an `Ok` value, or return `default`.
`default` may be T or a function returning T.

# Examples
```jldoctest
julia> unwrap_or(Ok("value"), "error")
"value"
julia> unwrap_or(Err(5), "error")
"error"
julia> unwrap_or(Some("value"), () -> begin println("Generating error"); "error" end)
"value"
julia> unwrap_or(None(), () -> begin println("Generating error"); "error" end)
Generating error
"error"
```
"""
function unwrap_or end

function unwrap_or(r::Ok{T}, default::Union{T, Function})::T where {T} r.value end
function unwrap_or(s::Some{T}, default::Union{T, Function})::T where {T} s.value end
function unwrap_or(::Union{Err, None}, default::T)::T where {T} default end
function unwrap_or(::Union{Err, None}, default::Function) default() end
