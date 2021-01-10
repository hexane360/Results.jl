module Results

include("macros.jl")

import Base: &, |, !, ==
import Base: map, promote_rule, convert
import Base: iterate, eltype, length
#using Base: Some, string, repr, esc, error
#using Base: AbstractDict, AbstractArray, isempty, haskey, pop!, get
#using Base: IteratorSize, IteratorEltype, HasLength, HasShape, SizeUnknown
using Base: IteratorEltype, HasEltype

export Result, Ok, Err
export is_ok, is_err, has_val
export to_option, to_result
export map_err
export unwrap, unwrap_or
export bind, ⋄
export try_pop!, try_get
export try_collect
export @try_unwrap, @while_let

"""Represents an Ok result of computation."""
struct Ok{T}
	val::T
end
#Ok(::Type{T}) where {T} = Ok{Type{T}}(T)

"""Represents an computation error."""
struct Err{E}
	err::E
end
#Err(::Type{T}) where {T} = Err{Type{T}}(T)

promote_rule(::Type{Ok{T}}, ::Type{Ok{S}}) where {T, S <: T} = Ok{T}
promote_rule(::Type{Err{T}}, ::Type{Err{S}}) where {T, S <: T} = Err{T}
convert(::Type{Ok{T}}, x::Ok{S}) where {T, S <: T} = Ok{T}(convert(T, x.val))
convert(::Type{Err{T}}, x::Err{S}) where {T, S <: T} = Err{T}(convert(T, x.err))

"""
Synonym for `Union{Ok{T}, Err{E}}`.

As well as working with the `Result` combinators defined
below, `Result`s implement the following protocols:
 - `iterate`: Yields one `T` if the `Result` is `Ok`, yields nothing otherwise.
 - `length`: Returns 1 if the `Result` is `Ok`, 0 if `Err`
"""
const Result{T, E} = Union{Ok{T}, Err{E}}

convert(::Type{Result{T,E}}, x::Ok{S}) where {T, E, S <: T} = Ok{T}(convert(T, x.val))
convert(::Type{Result{T,E}}, x::Err{S}) where {T, E, S <: E} = Err{E}(convert(E, x.err))

==(a::Ok, b::Result) = is_ok(b) && a.val == b.val
==(a::Err, b::Result) = is_err(b) && a.err == b.err
==(a::Some, b::Some) = a.value == b.value
==(a::Some, ::Nothing) = false

"""Returns whether a `Result` is `Ok` or `Err`."""
function is_ok end
"""Returns whether a `Result` is `Ok` or `Err`."""
function is_err end

is_ok(r::Ok)::Bool = true
is_ok(r::Err)::Bool = false
is_err(r::Ok)::Bool = false
is_err(r::Err)::Bool = true

"""Return whether a `Result` contains a value equal to `v`."""
is_ok(r::Result, v)::Bool = is_ok(r) && r.val == v
"""Return whether a `Result` contains an error equal to `v`."""
is_err(r::Result, v)::Bool = is_err(r) && r.err == v

"""
Converts a `Result` to an `Option`, turning
`Ok` into `Some` and `Err` into `nothing`.
"""
function to_option end

function to_option(r::Ok{T})::Some{T} where {T} Some{T}(r.val) end
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
Map `f` over the contents of an `Ok` value, leaving an `Err` value untouched.

# Example
```jldoctest
julia> map((x) -> 2*x, Ok(5))
Ok{Int64}(10)
julia> map.((x) -> 2*x, [Ok(5), Err("missing value")])
2-element Array{Any,1}:
 Ok{Int64}(10)
 Err{String}("missing value")
```
"""
function map end

map(f, r::Ok)::Ok = Ok(f(r.val))
map(f, r::Some)::Some = Some(f(r.value))
map(::Any, r::Err)::Err = r
map(::Any, n::Nothing)::Nothing = n

"""Map `f` over the contents of an `Err` value, leaving an `Ok` value untouched."""
function map_err end

map_err(::Any, r::Ok)::Ok = r
map_err(f, r::Err)::Err = Err(f(r.err))

"""Exception thrown when `unwrap()` is called on an `Err`"""
struct UnwrapError <: Exception
	s::String
end

"""
Unwrap an `Ok` value. Throws an error if `r` is `Err` instead.

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

function unwrap(r::Ok{T})::T where {T} r.val end
function unwrap(r::Err{E})::Union{} where {E}
	throw(isa(r.err, Exception)
		? r.err
		: UnwrapError(string("unwrap() called on an Err: ", repr(r.err)))
	)
end
function unwrap(s::Some{T})::T where {T} s.value end
function unwrap(::Nothing)::Union{}
	throw(UnwrapError("unwrap() called on Nothing"))
end

function unwrap(r::Ok{T}, error)::T where {T} r.val end
function unwrap(r::Some{T}, error)::T where {T} r.value end
function unwrap(::Union{Err, Nothing}, error::Exception)::Union{} throw(error) end
function unwrap(v::Err, error::Function)::Union{} unwrap(v, error(v.err)) end
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
julia> unwrap_or(Some("value"), (e) -> begin println("Generating error"); "error" end)
"value"
julia> unwrap_or(nothing, (e) -> begin println("Generating error"); "error" end)
Generating error
"error"
```
"""
function unwrap_or end

function unwrap_or(r::Ok{T}, default::Union{T, Function})::T where {T} r.val end
function unwrap_or(s::Some{T}, default::Union{T, Function})::T where {T} s.value end
function unwrap_or(::Union{Err, Nothing}, default::T)::T where {T} default end
function unwrap_or(e::Union{Err, Nothing}, default::Function) default(e) end

function iterate(r::Ok{T})::Tuple{T, Nothing} where {T}
	(r.val, nothing)
end
function iterate(::Err)::Nothing nothing end
function iterate(::Result, ::Nothing)::Nothing nothing end

length(r::Ok)::Int = 1
length(r::Err)::Int = 0

eltype(::Type{Ok{T}}) where {T} = T
eltype(::Type{<:Err}) = Union{}
eltype(::Type{Result{T,U}}) where {T, U} = T


"""
Binds `result` to the proceeding functions. While `result`
is `Ok`, its contents will be passed to each function in turn.
Any `Err` value will be returned immediately.

# Examples
```jldoctest
julia> Ok("Build") ⋄ (val) -> Ok(string(val, " a ")) ⋄ (val) -> Ok(string(val, "string"))
Ok{String}("Build a string")
julia> Err("Error") ⋄ (val) -> Ok(string(val, " a ")) ⋄ (val) -> Ok(string(val, "string"))
Err{String}("Error")
julia> Ok("Build") ⋄ (val) -> Err("Error") ⋄ function (val) error("long circuited"); Ok("value") end
Err{String}("Error")
```
"""
function bind(result::Result, funcs::Function...)::Result
	for f in funcs
		is_err(result) && return result
		result = f(result.val)
		if !isa(result, Result)  #support functions which return a bare value
			result = Ok(result)
		end
	end
	result
end

const ⋄ = bind

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
Collect an iterator of Results into a single Result containing an array.
Short-circuits on error.

# Examples
```jldoctest
julia> try_collect([Ok(5), Ok(10), Ok(3)])
Ok{Array{Int64,1}}([5, 10, 3])
julia> try_collect([Ok(10), Err("err1"), Err("err2")])
Err{String}("err1")
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

"""
Synonym for unwrap_or. Note that it returns a T, while | usually returns a Result{T, E}
"""
function (|)(result::Union{Ok{T}, Err, Some{T}, Nothing}, default::T)::T where {T}
	unwrap_or(result, default)
end

"""Flip an Ok value to an Err value and vice versa."""
function (!)(result::Ok{T})::Err{T} where {T} Err(result.val) end
"""Flip an Ok value to an Err value and vice versa."""
function (!)(result::Err{T})::Ok{T} where {T} Ok(result.err) end

has_val(result::Result)::Bool = is_ok(result)
has_val(::Some)::Bool = true
has_val(::Nothing)::Bool = false

function try_pop!(a::AbstractArray{T})::Union{Some{T}, Nothing} where {T}
	isempty(a) ? nothing : Some(pop!(a))
end

try_pop!(a, e)::Result = to_result(try_pop!(a), e)

function try_get(d::AbstractDict{K, V}, k::K)::Union{Some{V}, Nothing} where {K, V}
	haskey(d, k) ? Some(d[k]) : nothing
end

try_get(d, k, e)::Result = to_result(try_get(d, k), e)



end #module
