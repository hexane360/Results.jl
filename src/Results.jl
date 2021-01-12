module Results

include("macros.jl")

import Base: &, |, !, ==
import Base: promote_rule, convert
import Base: show
import Base: iterate, eltype, length
using Base: IteratorEltype, HasEltype

# types
export Option, Result, Ok, Err

# predicates
export is_ok, is_err, has_val

# input functions
export wrap_option, wrap_result
export to_option, to_result

# output functions
export unwrap, unwrap_or

# transform functions
export try_map, map_err
export and_then, try_collect
export ⋄, ⊗

# collection functions
export try_pop!, try_get, try_next

# macros
export @try_unwrap, @while_let, @if_let

"""Represents an Ok result of computation."""
struct Ok{T}
	value::T
end
#Ok(::Type{T}) where {T} = Ok{Type{T}}(T)

"""Represents an computation error."""
struct Err{E}
	error::E
end
#Err(::Type{T}) where {T} = Err{Type{T}}(T)

promote_rule(::Type{Ok{T}}, ::Type{Ok{S}}) where {T, S <: T} = Ok{T}
promote_rule(::Type{Err{T}}, ::Type{Err{S}}) where {T, S <: T} = Err{T}
convert(::Type{Ok{T}}, x::Ok{S}) where {T, S <: T} = Ok{T}(convert(T, x.value))
convert(::Type{Err{T}}, x::Err{S}) where {T, S <: T} = Err{T}(convert(T, x.error))

==(a::Some, b::Some)::Bool = a.value == b.value
==(a::Ok, b::Ok)::Bool = a.value == b.value
==(a::Err, b::Err)::Bool = a.error == b.error

# taken from some.jl
function show(io::IO, x::Ok)
    if get(io, :typeinfo, Any) == typeof(x)
        show(io, x.value)
    else
        print(io, "Ok(")
        show(io, x.value)
        print(io, ')')
    end
end

function show(io::IO, x::Err)
    if get(io, :typeinfo, Any) == typeof(x)
        show(io, x.error)
    else
        print(io, "Err(")
        show(io, x.error)
        print(io, ')')
    end
end

"""
Synonym for `Union{Ok{T}, Err{E}}`.

As well as working with the `Result` combinators defined
below, `Result`s implement the following protocols:
 - `iterate`: Yields one `T` if the `Result` is `Ok`, yields nothing otherwise.
 - `length`: Returns 1 if the `Result` is `Ok`, 0 if `Err`
"""
const Result{T, E} = Union{Ok{T}, Err{E}}

"""
Synonym for `Union{Some{T}, Nothing}`.

`Option`s implement the following protocols:
 - `iterate`: Yields one `T` if the `Option` is `Some`, yields nothing otherwise.
 - `length`: Returns 1 if the `Result` is `Ok`, 0 if `Err`
"""
const Option{T} = Union{Some{T}, Nothing}

#convert(::Type{Result{T,E}}, x::Ok{S}) where {T, E, S <: T} = Ok{T}(convert(T, x.value))
#convert(::Type{Result{T,E}}, x::Err{S}) where {T, E, S <: E} = Err{E}(convert(E, x.error))

# ==(a::Ok, b::Ok) = a.value == b.value
# ==(a::Ok, b::Err) = false
# ==(a::Some, ::Nothing) = false

"""Returns whether a `Result` is `Ok` or `Err`."""
function is_ok end
"""Returns whether a `Result` is `Ok` or `Err`."""
function is_err end

is_ok(r::Ok)::Bool = true
is_ok(r::Err)::Bool = false
is_err(r::Ok)::Bool = false
is_err(r::Err)::Bool = true

"""Return whether a `Result` contains a value equal to `v`."""
is_ok(r::Result, v)::Bool = is_ok(r) && r.value == v
"""Return whether a `Result` contains an error equal to `v`."""
is_err(r::Result, v)::Bool = is_err(r) && r.error == v

is_some(::Some)::Bool = true
is_some(::Nothing)::Bool = false
is_some(o::Option, v)::Bool = o == Some(v)

"""
Converts a `Result` to an `Option`, turning
`Ok` into `Some` and `Err` into `nothing`.
"""
function to_option end

function to_option(r::Ok{T})::Some{T} where {T} Some(r.value) end
function to_option(::Err)::Nothing nothing end

"""
Converts an `Option` into a `Result`, using the
supplied error value in place of a `nothing`.
"""
function to_result end

function to_result(o::Some{T}, err)::Ok{T} where {T} Ok(o.value) end
function to_result(::Nothing, err::E)::Err{E} where {E} Err(err) end
function to_result(::Nothing, err::Function)::Err Err(err()) end

"""
Wraps a value in an `Option`. Useful for handling nullable values.

# Example
```jldoctest
julia> wrap_option("value")
Some("value")
julia> wrap_option(Some(5))
Some(Some(5))
julia> wrap_option(nothing)
```
"""
function wrap_option end

function wrap_option(val::T)::Some{T} where {T} Some(val) end
function wrap_option(::Nothing)::Nothing nothing end

"""
Wraps a value in a `Result`, using the
supplied error value in place of a `nothing`.
Useful for handling nullable values.

# Example
```jldoctest
julia> wrap_result("value", "error")
Ok("value")
julia> wrap_result(nothing, "error")
Err("error")
julia> wrap_result("value", () -> println("lazily calculates errors"))
Ok("value")
julia> wrap_result(Ok(5), nothing)
Ok(Ok(5))
```
"""
function wrap_result end

function wrap_result(val::T, err)::Ok{T} where {T} Ok(val) end
function wrap_result(::Nothing, err::E)::Err{E} where {E} Err(err) end
function wrap_result(::Nothing, err::Function)::Err Err(err()) end

"""
Map `f` over the contents of an `Some` value, leaving an `Err` value untouched.

# Example
```jldoctest
julia> try_map((x) -> 2*x, Ok(5))
Ok(10)
julia> try_map.((x) -> 2*x, [Ok(5), Err("missing value")])
2-element Array{Any,1}:
 Ok(10)
 Err("missing value")
julia> try_map(Ok(+), Ok(5), Ok(10))
Ok(15)
```
"""
function try_map end

try_map(f, opt::Option...)::Option = try_map(Some(f), opt...)
try_map(f, rslt::Result...)::Result = try_map(Ok(f), rslt...)

try_map(f::Ok, args::Ok...)::Ok = Ok((f.value)(map(unwrap, args)...))
try_map(f::Ok, args::Result...)::Err = try_collect(args)
function try_map(f::Err{E}, ::Result...)::Err{E} where {E} f end

try_map(f::Some, args::Some...)::Some = Some((f.value)(map(unwrap, args)...))
try_map(f::Some, args::Option...)::Nothing = try_collect(args)
try_map(::Nothing, ::Option...)::Nothing = nothing


"""Partially-applied version of try_map."""
try_map(f)::Function = (opt...) -> try_map(f, opt...)

"""Shorthand for `try_map`"""
const ⊗ = try_map

"""Map `f` over the contents of an `Err` value, leaving an `Ok` value untouched."""
function map_err end

map_err(::Any, r::Ok)::Ok = r
map_err(f, r::Err)::Err = Err(f(r.error))

"""Partially-applied version of map_err."""
map_err(f)::Function = (r) -> map_err(f, r)

"""Exception thrown when `unwrap()` is called on an `Err`"""
struct UnwrapError <: Exception
	s::String
end

"""
Unwrap an `Ok` value. Throws an error if `r` is `Err` instead.#

In the two argument form, `error` is raised if `r` is `Err`.

# Examples
```jldoctest
julia> unwrap(Ok(5))
5
julia> unwrap(Err(0))
ERROR: Results.UnwrapError("unwrap() called on an Err: 0")
julia> unwrap(nothing)
ERROR: Results.UnwrapError("unwrap() called on Nothing")
julia> unwrap(nothing, "value is none")
ERROR: Results.UnwrapError("value is none")
julia> unwrap(nothing, BoundsError([1,2]))
ERROR: BoundsError: attempt to access 2-element Array{Int64,1}
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
function unwrap(::Nothing)::Union{}
	throw(UnwrapError("unwrap() called on Nothing"))
end

function unwrap(r::Ok{T}, error)::T where {T} r.value end
function unwrap(r::Some{T}, error)::T where {T} r.value end
function unwrap(::Union{Err, Nothing}, error::Exception)::Union{} throw(error) end
function unwrap(v::Err, error::Function)::Union{} unwrap(v, error(v.error)) end
function unwrap(v::Nothing, error::Function)::Union{} unwrap(v, error(v)) end
function unwrap(::Union{Err, Nothing}, error::String)::Union{}
	throw(UnwrapError(string(error)))
end

"""
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
julia> unwrap_or(nothing, () -> begin println("Generating error"); "error" end)
Generating error
"error"
```
"""
function unwrap_or end

function unwrap_or(r::Ok{T}, default::Union{T, Function})::T where {T} r.value end
function unwrap_or(s::Some{T}, default::Union{T, Function})::T where {T} s.value end
function unwrap_or(::Union{Err, Nothing}, default::T)::T where {T} default end
function unwrap_or(::Union{Err, Nothing}, default::Function) default() end

function iterate(r::Ok{T})::Tuple{T, Nothing} where {T}
	(r.value, nothing)
end
function iterate(::Err)::Nothing nothing end
function iterate(::Result, ::Nothing)::Nothing nothing end

function iterate(s::Some{T})::Tuple{T, Nothing} where {T}
	(s.value, nothing)
end
function iterate(::Nothing)::Nothing nothing end
function iterate(::Option, ::Nothing)::Nothing nothing end

length(r::Ok)::Int = 1
length(r::Err)::Int = 0
length(s::Some)::Int = 1
length(::Nothing)::Int = 0

eltype(::Type{Ok{T}}) where {T} = T
eltype(::Type{<:Err}) = Union{}
eltype(::Type{Result{T,U}}) where {T, U} = T
eltype(::Type{Some{T}}) where {T} = T
eltype(::Type{Nothing}) = Union{}
eltype(::Type{Option{T}}) where {T} = T

"""
Binds `result` to the proceeding functions. If `result`
is `Ok`, its contents will be passed to each function in turn.
Any `Err` value will be returned immediately.

# Examples
```jldoctest
julia> Ok("Build") ⋄ val -> Ok(string(val, " a ")) ⋄ val -> Ok(string(val, "string"))
Ok("Build a string")
julia> Err("Error") ⋄ val -> Ok(string(val, " a ")) ⋄ val -> Ok(string(val, "string"))
Err("Error")
julia> Ok("Build") ⋄ val -> Err("Error") ⋄ function (val) error("long circuited"); Ok("value") end
Err("Error")
```
"""
function and_then(result::Result, funcs...)::Result
	for f in funcs
		is_err(result) && return result
		result = isa(f, Result) ? f : f(result.value)
		if !isa(result, Result)  #support functions which return a bare value
			result = Ok(result)
		end
	end
	result
end

"""
Binds `option` to the proceeding functions. While `option`
is `Some`, its contents will be passed to each function in turn.
Any `Nothing` will be returned immediately.
julia> Some("Build") ⋄ val -> Some(string(val, " a ")) ⋄ val -> Some(string(val, "string"))
Some("Build a string")
julia> nothing ⋄ val -> Some(string(val, " a ")) ⋄ val -> Some(string(val, "string"))
julia> Some("Build") ⋄ val -> nothing ⋄ function (val) error("long circuited"); Some("value") end
"""
function and_then(option::Option, funcs...)::Option
	for f in funcs
		is_err(option) && return option
		option = isa(f, Option) ? f : f(option.value)
		if !isa(option, Option)
			option = Some(option)
		end
	end
	option
end

"""
Partially-applied version of `and_then`
"""
and_then(option::Option)::Function = (funcs...) -> and_then(option, funcs...)
"""
Partially-applied version of `and_then`
"""
and_then(result::Result)::Function = (funcs...) -> and_then(result, funcs...)

"""
Shorthand for `and_then` (monadic bind).
"""
const ⋄ = and_then

"""Flattens a nested `Option` or `Result` type."""
function flatten end

function flatten(s::Some{Some{T}})::Some{T} where {T} s.value end
function flatten(::Some{Nothing})::Nothing nothing end
function flatten(::Nothing)::Nothing nothing end
function flatten(o::Ok{Ok{T}})::Ok{T} where {T} o.value end
function flatten(e::Ok{Err{E}})::Err{E} where {E} e.value end
function flatten(e::Err{E})::Err{E} where {E} e end

"""Return the passed type with one layer of `Result` values stripped."""
function strip_result_type end

function strip_result_type(ty::Union)::Array{Type}
	collect(Iterators.flatten(map(strip_result_type, Base.uniontypes(ty))))
end
function strip_result_type(ty::Type{Some{T}})::Array{Type} where {T}; [T] end
function strip_result_type(::Type{Nothing})::Array{Type}; [] end
function strip_result_type(ty::Type{Ok{T}})::Array{Type} where {T}; [T] end
function strip_result_type(::Type{Err{E}})::Array{Type} where {E}; [] end
strip_result_type(ty::Type)::Array{Type} = [ty]

# TODO optimize for known type/size (see base/array.jl)
"""
Collect an iterator of Options or Results into a single Option or Result containing an array.
Short-circuits on error.

# Examples
```jldoctest
julia> try_collect([Ok(5), Ok(10), Ok(3)])
Ok([5, 10, 3])
julia> try_collect([Ok(10), Err("err1"), Err("err2")])
Err("err1")
```
"""
function try_collect(iter)
	#this is a mess
	T = IteratorEltype(iter) == HasEltype() ? eltype(iter) : Any
	arr = Union{strip_result_type(T)...}[]
	first = true
	wrap_type = Ok
	for elem in iter
		if first
			wrap_type = typeof(elem).name.wrapper
		end
		push!(arr, @try_unwrap elem)
	end
	wrap_type(arr)
end

"""
Return the final `Ok`/`Some` only if every argument is `Ok`/`Some`.
Otherwise return the first `Err` value.

Values can be supplied either as `Result`/`Option`s
or as functions that yield a `Result`/`Option`.

# Examples
```jldoctest
julia> Ok("v1") & Ok("v2") & () -> Ok("v3")
Ok("v3")

julia> Ok("v1") & () -> Err(2) & () -> Ok("v2")
Err(2)

julia> Some(5) & Some(10) & nothing
```
"""
function (&)(result::Result, rs...)::Result
	for r in rs
		has_val(result) || return result
		result = isa(r, Result) ? r : r()
	end
	result
end

function (&)(option::Option, os...)::Option
	for o in os
		has_val(option) || return option
		option = isa(o, Option) ? o : o()
	end
	option
end

"""
Return the first `Ok` value found. If no arguments
are `Ok`, return the final `Err` value.

Values can be supplied either as `Result`s
or as functions that yield a `Result`.

# Examples
```jldoctest
julia> Err("err1") | Ok("v2") | () -> Ok("v3")
Ok("v2")
julia> Err("err1") | () -> Err("err2") | Err("err3")
Err("err3")
```
"""
function (|)(result::Result, rs...)::Result
	for r in rs
		has_val(result) && return result
		result = isa(r, Result) ? r : r()
	end
	result
end

function (|)(option::Option, os...)::Option
	for o in os
		has_val(option) && return option
		option = isa(o, Option) ? o : o()
	end
	option
end

#"""
#Synonym for unwrap_or. Note that it returns a T, while | usually returns a Result{T, E}
#"""
#function (|)(result::Union{Ok{T}, Err, Some{T}, Nothing}, default::T)::T where {T}
#	unwrap_or(result, default)
#end

"""Flip an Ok value to an Err value and vice versa."""
function (!)(result::Ok{T})::Err{T} where {T} Err(result.value) end
"""Flip an Ok value to an Err value and vice versa."""
function (!)(result::Err{T})::Ok{T} where {T} Ok(result.error) end

"""Returns true for a successful `Result` or `Option`."""
function has_val end

has_val(::Ok)::Bool = true
has_val(::Err)::Bool = false
has_val(::Some)::Bool = true
has_val(::Nothing)::Bool = false

"""
Try to pop a value from an array.
"""
function try_pop!(a::AbstractArray{T})::Union{Some{T}, Nothing} where {T}
	isempty(a) ? nothing : Some(pop!(a))
end

try_pop!(a, e)::Result = to_result(try_pop!(a), e)

"""
Try to get a value out of a dictionary.
"""
function try_get(d::AbstractDict{>:K, V}, k::K)::Union{Some{V}, Nothing} where {K, V}
	haskey(d, k) ? Some(d[k]) : nothing
end

try_get(d, k, e)::Result = to_result(try_get(d, k), e)

"""
Try to get a value out of an iterator.
"""
try_next(iter; state=nothing)::Union{Some, Nothing} = map((x) -> x[1], wrap_option(iterate(iter, state)))
try_next(iter, e; state=nothing)::Result = to_result(try_next(iter, state=state), e)

end #module
