module Results

include("macros.jl")

import Base: &, |, !, ==
import Base: promote_rule, convert
import Base: show
import Base: iterate, eltype, length
using Base: IteratorEltype, HasEltype

# types
export Option, Result, Ok, Err, None, none

# predicates
export is_ok, is_err, is_some, is_none, has_val

# input functions
export to_option, to_result

# output functions
export unwrap, unwrap_or

# transform functions
export ok_or, ok
export try_map, map_err
export and_then, try_collect
export flatten
#export ←, →, ⊗

# collection functions
export try_pop!, try_get, try_peek, try_first, try_last

# macros
export @try_unwrap, @unwrap_or, @some_if, @catch_result, @while_let, @if_let

"""Represents an Ok result of computation."""
struct Ok{T}
	value::T
end
#Ok(::Type{T}) where {T} = Ok{Type{T}}(T)

"""Represents an computation error."""
struct Err{E}
	error::E
end

"""
Synonym for `Union{Ok{T}, Err{E}}`.

As well as working with the `Result` combinators defined
below, `Result`s implement the following protocols:
 - `iterate`: Yields one `T` if the `Result` is `Ok`, yields nothing otherwise.
 - `length`: Returns 1 if the `Result` is `Ok`, 0 if `Err`
"""
const Result{T, E} = Union{Ok{T}, Err{E}}

"""Shorthand for `Nothing`."""
const None = Nothing
"""Shorthand for `nothing`."""
const none = nothing

"""
Synonym for `Union{Some{T}, None}`.

`Option`s implement the following protocols:
 - `iterate`: Yields one `T` if the `Option` is `Some`, yields nothing otherwise.
 - `length`: Returns 1 if the `Result` is `Ok`, 0 if `Err`
"""
const Option{T} = Union{Some{T}, None}

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
length(::None)::Int = 0

eltype(::Type{Ok{T}}) where {T} = T
eltype(::Type{<:Err}) = Union{}
eltype(::Type{Result{T,U}}) where {T, U} = T
eltype(::Type{Some{T}}) where {T} = T
eltype(::Type{None}) = Union{}
eltype(::Type{Option{T}}) where {T} = T

"""Return whether a `Result` is `Ok` or `Err`."""
function is_ok end
is_ok(r::Ok)::Bool = true
is_ok(r::Err)::Bool = false

"""Return whether a `Result` contains a value equal to `v`."""
is_ok(r::Result, v)::Bool = is_ok(r) && r.value == v

"""Return whether a `Result` is `Err`."""
function is_err end
is_err(r::Ok)::Bool = false
is_err(r::Err)::Bool = true

"""Return whether a `Result` contains an error equal to `v`."""
is_err(r::Result, v)::Bool = is_err(r) && r.error == v

"""Return whether an `Option` is `Some`."""
function is_some end

is_some(::Some)::Bool = true
is_some(::None)::Bool = false

"""Return whether an `Option` contains a value equal to `v`."""
is_some(o::Option, v)::Bool = o == Some(v)

"""Return whether an `Option` is `None`."""
is_none(::Some)::Bool = false
is_none(::None)::Bool = true

"""
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
Converts an `Option` into a `Result`, using
the supplied error value in place of `None`.

# Examples
```jldoctest
julia> ok_or(Some(5), "error")
Ok(5)
julia> ok_or(None, "error")
Err("error")
julia> ok_or(None, () -> Err("lazy error"))
Err("lazy error")
julia> None |> ok_or("partially applied")
Err("partially applied")
"""
function ok_or end

function ok_or(o::Some{T}, err)::Ok{T} where {T} Ok(o.value) end
function ok_or(::None, err::E)::Err{E} where {E} Err(err) end
function ok_or(::None, err::Function)::Err Err(err()) end

"""Partially-applied version of ok_or."""
ok_or(err)::Function = o -> ok_or(o, err)

"""
Converts a `Result` into an `Option`,
discarding any `Err` value.

# Examples
```jldoctest
julia> ok(Ok(5))
Some(5)
julia> ok(Err("error")) |> println
nothing
```
"""
function ok end
function ok(o::Ok{T})::Some{T} where {T} Some(o.value) end
function ok(::Err)::None none end

"""
Map `f` over the contents of an `Ok` or `Some` value,
leaving a `None` or `Err` value untouched.

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
try_map(f::Some, args::Option...)::None = try_collect(args)
try_map(::Nothing, ::Option...)::None = nothing

try_map(f, tup::Tuple{Vararg{Result}})::Result = try_map(f, tup...)
try_map(f, tup::Tuple{Vararg{Option}})::Option = try_map(f, tup...)

"""Partially-applied version of try_map."""
try_map(f)::Function = (opt...) -> try_map(f, opt...)

"""
Shorthand for `try_map`. Enter as `\\leftarrow`.

# Example
```jldoctest; filter = r"#\\d+ \\(generic function"
julia> Ok(x -> 2*x) ← Ok(5)
Ok(10)
julia> x -> 2*x ← Ok(5)  # Be careful with precedence!
#1 (generic function with 1 method)
```
"""
const ← = try_map

"""
Argument-swapped version of try_map. Enter as `\\rightarrow`.

# Example
```jldoctest
julia> Ok(5) → x -> 2*x
Ok(10)
```
"""
function → end

→(rslt::Result, f)::Result = try_map(f, rslt)
→(rslt::Option, f)::Option = try_map(f, rslt)

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
function unwrap(::None)::Union{}
	throw(UnwrapError("unwrap() called on Nothing"))
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
julia> unwrap_or(none, () -> begin println("Generating error"); "error" end)
Generating error
"error"
```
"""
function unwrap_or end

function unwrap_or(r::Ok{T}, default::Union{T, Function})::T where {T} r.value end
function unwrap_or(s::Some{T}, default::Union{T, Function})::T where {T} s.value end
function unwrap_or(::Union{Err, None}, default::T)::T where {T} default end
function unwrap_or(::Union{Err, None}, default::Function) default() end

"""
Binds `result` to the proceeding functions. If `result`
is `Ok`, its contents will be passed to each function in turn.
Any `Err` value will be returned immediately.

# Examples
```jldoctest
julia> Ok("Build") ⊗ val -> Ok(string(val, " a ")) ⊗ val -> Ok(string(val, "string"))
Ok("Build a string")
julia> Err("Error") ⊗ val -> Ok(string(val, " a ")) ⊗ val -> Ok(string(val, "string"))
Err("Error")
julia> Ok("Build") ⊗ val -> Err("Error") ⊗ function (val) error("long circuited"); Ok("value") end
Err("Error")
```
"""
function and_then(result::Result, funcs::Vararg{Union{Base.Callable, Result}})::Result
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
Any `None` will be returned immediately.
julia> Some("Build") ⊗ val -> Some(string(val, " a ")) ⊗ val -> Some(string(val, "string"))
Some("Build a string")
julia> none ⊗ val -> Some(string(val, " a ")) ⊗ val -> Some(string(val, "string"))
julia> Some("Build") ⊗ val -> none ⊗ function (val) error("long circuited"); Some("value") end
"""
function and_then(option::Option, funcs::Vararg{Union{Base.Callable, Option}})::Option
	for f in funcs
		is_none(option) && return option
		option = isa(f, Option) ? f : f(option.value)
		if !isa(option, Option)
			option = Some(option)  #support functions which return a bare value
		end
	end
	option
end

"""
Partially-applied version of `and_then`.
"""
and_then(func::Base.Callable)::Function = (result) -> and_then(result, func)

"""
Shorthand for `and_then` (monadic bind). Enter with `\\otimes`
"""
const ⊗ = and_then

"""
Flattens one layer of a nested `Option` or `Result` type.

# Examples
```jldoctest
julia> Ok(Ok(5)) |> flatten
Ok(5)
julia> Ok(Err("inner")) |> flatten
Err("inner")
julia> Some(Some(Some(5))) |> flatten
Some(Some(5))
julia> Ok(Some(5)) |> flatten  # mixed Option and Result types not supported
ERROR: MethodError
```
"""
function flatten end

function flatten(s::Some{Some{T}})::Some{T} where {T} s.value end
function flatten(::Some{None})::None none end
function flatten(::None)::None none end

function flatten(o::Ok{Ok{T}})::Ok{T} where {T} o.value end
function flatten(e::Ok{Err{E}})::Err{E} where {E} e.value end
function flatten(e::Err{E})::Err{E} where {E} e end

"""Return the passed type with one layer of `Result` values stripped."""
strip_result_type(ty::Type) = Union{_strip_result_type(ty)...}

function _strip_result_type(ty::Union)
	Iterators.flatten(map(_strip_result_type, Base.uniontypes(ty)))
end
_strip_result_type(ty::Type) = Some(ty)
_strip_result_type(::Type{Ok{T}}) where {T} = Some(T)
_strip_reslut_type(::Type{Ok}) = Some(Any)
_strip_result_type(::Type{Err{T}}) where {T} = none
_strip_result_type(::Type{Err}) = none

"""Return the passed type with one layer of `Option` values stripped."""
strip_option_type(ty::Type) = Union{_strip_option_type(ty)...}

function _strip_option_type(ty::Union)
	Iterators.flatten(map(_strip_option_type, Base.uniontypes(ty)))
end
_strip_option_type(ty::Type) = Some(ty)
_strip_option_type(::Type{Some{T}}) where {T} = Some(T)
_strip_option_type(::Type{Some}) = Some(Any)
_strip_option_type(::Type{None}) = none

function in_union(union::Type, ty::Type)
	if isa(union, Union)
		union.a <: ty || in_union(union.b, ty)
	else
		union <: ty
	end
end

# TODO optimize for known size (see base/array.jl)
"""
Collect an iterator of Options or Results into a single Option or Result containing an array.
Short-circuits on error.

# Examples
```jldoctest
julia> try_collect([Ok(5), Ok(10), Ok(3)])
Ok([5, 10, 3])
julia> try_collect([Ok(10), Err("err1"), Err("err2")])
Err("err1")
julia> try_collect([Ok(10), none, Ok(5)])  # be careful mixing Result with Option!
Ok(Union{Nothing, Int64}[10, nothing, 5])
```
"""
function try_collect(iter)
	# first try to infer the type from the iterator type.
	T = IteratorEltype(iter) == HasEltype() ? eltype(iter) : Any
	is_result = if in_union(T, Result) ⊻ in_union(T, Option)
		# only one type it can be
		in_union(T, Result)
	else
		# otherwise attempt to infer the type from the first element
		@unwrap_or(
			try_peek(iter) ⊗ (val) -> if isa(val, Result) Some(true) elseif isa(val, Option) Some(false) else none end,
			error("Can't infer which result type to use. Specify the array type or explicitly" *
			      "use `try_collect_result` or `try_collect_option` instead.")
		)
	end
	is_result ? try_collect_result(iter) : try_collect_option(iter)
end

try_collect(result::Result, results...)::Result = try_collect_result(Iterators.flatten(([result], results)))
try_collect(option::Option, options...)::Option = try_collect_option(Iterators.flatten(([option], options)))

function try_collect_result(iter)::Result
	T = IteratorEltype(iter) == HasEltype() ? eltype(iter) : Any
	arr = strip_result_type(T)[]
	for elem in iter
		if !isa(elem, Result)
			elem = Ok(elem)
		end
		push!(arr, @try_unwrap elem)
	end
	Ok(arr)
end
try_collect_result(results...)::Result = try_collect_result(results)

function try_collect_option(iter)::Option
	T = IteratorEltype(iter) == HasEltype() ? eltype(iter) : Any
	arr = strip_option_type(T)[]
	for elem in iter
		if !isa(elem, Option)
			elem = Some(elem)
		end
		push!(arr, @try_unwrap elem)
	end
	Some(arr)
end
try_collect_option(options...)::Option = try_collect_option(options)

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

julia> Some(5) & Some(10) & none
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
#function (|)(result::Union{Ok{T}, Err, Some{T}, None}, default::T)::T where {T}
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
has_val(::None)::Bool = false

"""
Try to pop a value from a collection.
"""
function try_pop! end

function try_pop!(a::AbstractArray{T})::Option{T} where {T}
	isempty(a) ? none : Some(pop!(a))
end

try_pop!(iter::Iterators.Stateful)::Option = Iterators.isdone(iter) ? none : Some(popfirst!(iter))

function try_pop!(d::AbstractDict{>:K, V}, k::K)::Option{V} where {K, V}
	haskey(d, k) ? Some(pop!(d, k)) : none
end

function try_pop!(d::AbstractDict{K, V})::Option{Pair{K, V}} where {K, V}
	isempty(d) ? none : Some(pop!(d))
end

"""Try to get a value from an array or collection."""
function try_get end

function try_get(a::AbstractArray{T}, index::Integer...)::Option{T} where {T}
	@some_if isassigned(a, index...) a[index...]
end

function try_get(s::AbstractString, i::Integer)::Option{AbstractChar}
	@some_if (checkbounds(s, i) && isvalid(s, i)) s[i]
end

function try_get(d::AbstractDict{>:K, V}, k::K)::Option{V} where {K, V}
	@some_if haskey(d, k) d[k]
end
try_get(t::NamedTuple, k::Union{Integer, Symbol})::Option = @some_if haskey(t, k) t[k]

# fallback method. Slow, but should work for any type.
try_get(a, index...)::Option = ok(@catch_result(Union{BoundsError, KeyError}, getindex(a, index...)))

"""Try to get the next value from an iterator."""
function try_peek end

try_peek(iter; state=missing)::Option = try_map((x) -> x[1], to_option(ismissing(state) ? iterate(iter) : iterate(iter, state)))
try_peek(iter::Iterators.Stateful; state=missing)::Option = @some_if !Iterators.isdone(iter) peek(iter)

"""Try to get the first element from a collection."""
function try_first(c)::Option
	i = firstindex(c)
	try_get(c, i)
end

function try_first(s::AbstractString, i::Integer)::Option{AbstractString}
	length(s) >= i ? Some(first(s, i)) : none
end

"""Try to get the last element from a collection."""
function try_last(c)::Option
	i = lastindex(c)
	try_get(c, i)
end

end #module
