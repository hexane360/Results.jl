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
export unwrap, unwrap_or, to_nullable

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
convert(::Type{Result{T, E}}, x::Ok{S}) where {T, E, S <: T} = Ok{T}(convert(T, x.value))
convert(::Type{Result{T, E}}, x::Err{S}) where {T, E, S <: E} = Err{E}(convert(E, x.error))
convert(::Type{Option{T}}, x::Some{S}) where {T, S <: T} = Some{T}(convert(T, x.value))

"""[`Base.isequal`](https://docs.julialang.org/en/v1/base/base/#Base.isequal) for `Some` values"""
==(a::Some, b::Some)::Bool = a.value == b.value
"""[`Base.isequal`](https://docs.julialang.org/en/v1/base/base/#Base.isequal) for [`Ok`](@ref) values"""
==(a::Ok, b::Ok)::Bool = a.value == b.value
"""[`Base.isequal`](https://docs.julialang.org/en/v1/base/base/#Base.isequal) for [`Err`](@ref) values"""
==(a::Err, b::Err)::Bool = a.error == b.error

# taken from some.jl
"""[`show`](https://docs.julialang.org/en/v1/base/base/#https://docs.julialang.org/en/v1/base/base/#Base.show) for [`Ok`](@ref) values"""
function show(io::IO, x::Ok)
    if get(io, :typeinfo, Any) == typeof(x)
        show(io, x.value)
    else
        print(io, "Ok(")
        show(io, x.value)
        print(io, ')')
    end
end

"""[`show`](https://docs.julialang.org/en/v1/base/base/#Base.show) for [`Err`](@ref) values"""
function show(io::IO, x::Err)
    if get(io, :typeinfo, Any) == typeof(x)
        show(io, x.error)
    else
        print(io, "Err(")
        show(io, x.error)
        print(io, ')')
    end
end

"""[`iterate`](https://docs.julialang.org/en/v1/base/base/#Base.iterate) for [`Ok`](@ref) values"""
function iterate(r::Ok{T})::Tuple{T, Nothing} where {T}
	(r.value, nothing)
end
"""[`iterate`](https://docs.julialang.org/en/v1/base/base/#Base.iterate) for [`Err`](@ref) values"""
function iterate(::Err)::Nothing nothing end
function iterate(::Result, ::Nothing)::Nothing nothing end

"""[`iterate`](https://docs.julialang.org/en/v1/base/base/#Base.iterate) for `Some` values"""
function iterate(s::Some{T})::Tuple{T, Nothing} where {T}
	(s.value, nothing)
end
"""[`iterate`](https://docs.julialang.org/en/v1/base/base/#Base.iterate) for [`None`](@ref) values"""
function iterate(::None)::Nothing nothing end
function iterate(::Option, ::Nothing)::Nothing nothing end

# workaround because we can't make a tuple with element type Type{T}
function iterate(s::Ok{Type{T}})::Tuple{DataType, Nothing} where {T}
	(s.value, nothing)
end
function iterate(s::Some{Type{T}})::Tuple{DataType, Nothing} where {T}
	(s.value, nothing)
end

"""[`length`](https://docs.julialang.org/en/v1/base/base/#Base.length) for [`Ok`](@ref) values"""
length(r::Ok)::Int = 1
"""[`length`](https://docs.julialang.org/en/v1/base/base/#Base.length) for [`Err`](@ref) values"""
length(r::Err)::Int = 0
"""[`length`](https://docs.julialang.org/en/v1/base/base/#Base.length) for `Some` values"""
length(s::Some)::Int = 1
"""[`length`](https://docs.julialang.org/en/v1/base/base/#Base.length) for [`None`](@ref) values"""
length(::None)::Int = 0

"""[`eltype`](https://docs.julialang.org/en/v1/base/base/#Base.eltype) for [`Ok`](@ref) values"""
eltype(::Type{Ok{T}}) where {T} = T
"""[`eltype`](https://docs.julialang.org/en/v1/base/base/#Base.eltype) for [`Err`](@ref) values"""
eltype(::Type{<:Err}) = Union{}
eltype(::Type{Result{T,U}}) where {T, U} = T
"""[`eltype`](https://docs.julialang.org/en/v1/base/base/#Base.eltype) for `Some` values"""
eltype(::Type{Some{T}}) where {T} = T
"""[`eltype`](https://docs.julialang.org/en/v1/base/base/#Base.eltype) for [`None`](@ref) values"""
eltype(::Type{None}) = Union{}
eltype(::Type{Option{T}}) where {T} = T

"""
    is_ok(r::Result)::Bool

Return whether a `Result` is `Ok` or `Err`.
"""
function is_ok end
is_ok(r::Ok)::Bool = true
is_ok(r::Err)::Bool = false

"""
    is_ok(r::Result, value)::Bool

Return whether a `Result` contains a value equal to `value`.
"""
is_ok(r::Result, v)::Bool = is_ok(r) && r.value == v

"""
    is_err(r::Result)::Bool

Return whether a `Result` is `Err`.
"""
function is_err end
is_err(r::Ok)::Bool = false
is_err(r::Err)::Bool = true

"""
    is_err(r::Result, value)::Bool

Return whether a `Result` contains an error equal to `value`.
"""
is_err(r::Result, v)::Bool = is_err(r) && r.error == v

"""
    is_some(o::Option)::Bool

Return whether an `Option` is `Some`.
"""
function is_some end

is_some(::Some)::Bool = true
is_some(::None)::Bool = false

"""
    is_some(o::Option, value)::Bool

Return whether an `Option` contains a value equal to `value`.
"""
is_some(o::Option, v)::Bool = o == Some(v)

"""
    is_none(o::Option)::Bool

Return whether an `Option` is `None`. Equivalent to
[`Base.isnothing`](https://docs.julialang.org/en/v1/base/base/#Base.isnothing).
"""
is_none(::Some)::Bool = false
is_none(::None)::Bool = true

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
    ok_or(o::Some{T}, err)::Ok{T}
    ok_or(::None, err::E)::Err{E}
    ok_or(::None, err::Function)::Err

Convert an `Option` into a `Result`, using
the supplied error value in place of `None`.

# Examples
```jldoctest
julia> ok_or(Some(5), "error")
Ok(5)
julia> ok_or(None(), "error")
Err("error")
julia> ok_or(None(), () -> "lazy error")
Err("lazy error")
julia> None() |> ok_or("partially applied")
Err("partially applied")
```
"""
function ok_or end

function ok_or(o::Some{T}, err)::Ok{T} where {T} Ok(o.value) end
function ok_or(::None, err::E)::Err{E} where {E} Err(err) end
function ok_or(::None, err::Function)::Err Err(err()) end

"""
    ok_or(err)::Function

Partially-applied version of ok_or.
"""
ok_or(err)::Function = o -> ok_or(o, err)

"""
    ok(r::Result{T, E})::Option{T}

Convert a `Result` into an `Option`,
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
    try_map(f, opt::Option...)::Option
    try_map(f, rslt::Result...)::Result
    try_map(f::Option, rslt::Option...)::Option
    try_map(f::Result, rslt::Result...)::Result

Map `f` over the contents of an `Ok` or `Some` value,
leaving a `None` or `Err` value untouched.

# Example
```jldoctest; filter = r"Array{\\S+,1}|Vector{\\S+}"
julia> try_map((x) -> 2*x, Ok(5))
Ok(10)
julia> try_map(+, Err("First error"), Err("Second error"))
Err("First error")
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
try_map(::None, ::Option...)::None = none

#try_map(f, tup::Tuple{Vararg{Result}})::Result = try_map(f, tup...)
#try_map(f, tup::Tuple{Vararg{Option}})::Option = try_map(f, tup...)

"""
    try_map(f)::Function

Partially-applied version of try_map.
"""
try_map(f)::Function = (opt...) -> try_map(f, opt...)

"""
Shorthand for [`try_map`](@ref). Enter as `\\leftarrow`.

# Example
```jldoctest; filter = r"#\\d+ \\(generic function"
julia> Ok(x -> 2*x) ← Ok(5)
Ok(10)
julia> x -> 2*x ← Ok(5)  # Be careful with precedence!
#1 (generic function with 1 method)
julia> (x -> 2*x) ← (x -> x+7) ← Some(3)
Some(20)
```
"""
const ← = try_map

"""
Argument-swapped version of [`try_map`](@ref). Enter as `\\rightarrow`.

# Example
```jldoctest
julia> Some(5) → x -> 2*x
Some(10)
julia> Ok(5) → (x -> 2*x) → (x -> x+7)  # arrows in Julia are right-associative!
ERROR: MethodError
julia> Ok(5) → (x -> 2*x) ∘ (x -> x+7) # but this will work
Ok(24)
```
"""
function → end

→(rslt::Result, f)::Result = try_map(f, rslt)
→(rslt::Option, f)::Option = try_map(f, rslt)

"""
    map_err(f, result::Result)::Result

Map `f` over the contents of an `Err` value, leaving an `Ok` value untouched.
"""
function map_err end

map_err(::Any, r::Ok)::Ok = r
map_err(f, r::Err)::Err = Err(f(r.error))

"""
    map_err(f)::Function

Partially-applied version of map_err.
"""
map_err(f)::Function = (r) -> map_err(f, r)

"""Exception thrown when `unwrap()` is called on an `Err`"""
struct UnwrapError <: Exception
	s::String
end

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
ERROR: Results.UnwrapError("unwrap() called on an Err: 0")
julia> unwrap(none)
ERROR: Results.UnwrapError("unwrap() called on None")
julia> unwrap(none, "value is none")
ERROR: Results.UnwrapError("value is none")
julia> unwrap(nothing, BoundsError([1,2]))
ERROR: BoundsError: attempt to access 2-element Array{Int64,1}
julia> unwrap(Err(5), v -> "Error value '" * string(v) * "'")
ERROR: Results.UnwrapError("Error value '5'")
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

"""
    and_then(result::Result, funcs...)::Result

Bind `result` to the proceeding functions. If `result`
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
    and_then(option::Option, funcs...)::Option

Bind `option` to the proceeding functions. While `option`
is `Some`, its contents will be passed to each function in turn.
Any `None` will be returned immediately.

# Examples
```jldoctest
julia> Some("Build") ⊗ val -> Some(string(val, " a ")) ⊗ val -> Some(string(val, "string"))
Some("Build a string")
julia> none ⊗ val -> Some(string(val, " a ")) ⊗ val -> Some(string(val, "string"))

julia> Some("Build") ⊗ val -> none ⊗ function (val) error("long circuited"); Some("value") end
```
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
    and_then(func::Base.Callable)::Function

Partially-applied version of `and_then`.
"""
and_then(func::Base.Callable)::Function = (result) -> and_then(result, func)

"""
Shorthand for [`and_then`](@ref) (monadic bind). Enter with `\\otimes`
"""
const ⊗ = and_then

"""
    flatten(o::Option{Option{T}})::Option{T}
    flatten(r::Result{Result{T, E1}, E2})::Result{T, Union{E1, E2}}

Flatten one layer of a nested `Option` or `Result` type.

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

"""
    strip_result_type(ty::Type)::Type

Return the passed type with one layer of `Result` values stripped.
"""
strip_result_type(ty::Type) = Union{_strip_result_type(ty)...}

function _strip_result_type(ty::Union)
	Iterators.flatten(map(_strip_result_type, Base.uniontypes(ty)))
end
_strip_result_type(ty::Type) = Some(ty)
_strip_result_type(::Type{Ok{T}}) where {T} = Some(T)
_strip_reslut_type(::Type{Ok}) = Some(Any)
_strip_result_type(::Type{Err{T}}) where {T} = none
_strip_result_type(::Type{Err}) = none

"""
    strip_option_type(ty::Type)::Type

Return the passed type with one layer of `Option` values stripped.
"""
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
    try_collect(iter)
    try_collect(result::Result, results...)::Result{Vector}
    try_collect(option::Option, options...)::Option{Vector}

Collect an iterator of Options or Results into a single Option or Result containing an array.
Short-circuits on error.

# Examples
```jldoctest; filter = r"Int32|Int64"
julia> try_collect([Ok(5), Ok(10), Ok(3)])
Ok([5, 10, 3])
julia> try_collect([Ok(10), Err("err1"), Err("err2")])
Err("err1")
julia> try_collect([Ok(10), None(), Ok(5)])  # be careful mixing Result with Option!
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

"""
    try_collect_result(iter)::Result{Vector}
    try_collect_result(results...)::Result{Vector}

Version of [`try_collect`](@ref) specialized for use with `Result`.
Prefer this over [`try_collect`](@ref) whenever possible to prevent
surprising behavior.
"""
function try_collect_result end

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

"""
    try_collect_option(iter)::Option{Vector}
    try_collect_option(options...)::Option{Vector}

Version of [`try_collect`](@ref) specialized for use with `Option`
Prefer this over [`try_collect`](@ref) whenever possible to prevent
surprising behavior.
"""
function try_collect_option end

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
    (&)(result::Result, results...)::Result
    (&)(option::Option, options...)::Option

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

julia> Some(5) & Some(10) & None()
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
    (|)(result::Result, results...)::Result
    (|)(option::Option, options...)::Option

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

"""
    (!)(result::Result{T,E})::Result{E,T}

Flip an Ok value to an Err value and vice versa.
"""
function (!)(result::Ok{T})::Err{T} where {T} Err(result.value) end
function (!)(result::Err{T})::Ok{T} where {T} Ok(result.error) end

"""
    has_val(result::Union{Result, Option})::Bool

Returns true for a successful `Result` or `Option`."""
function has_val end

has_val(::Ok)::Bool = true
has_val(::Err)::Bool = false
has_val(::Some)::Bool = true
has_val(::None)::Bool = false

"""Try to pop a value from a collection."""
function try_pop! end

"""
    try_pop!(a::AbstractArray{T})::Option{T}

Try to pop a value from an array.
"""
function try_pop!(a::AbstractArray{T})::Option{T} where {T}
	isempty(a) ? none : Some(pop!(a))
end

"""
    try_pop!(iter::Iterators.Stateful)::Option

Try to pop a value from a Stateful iterator.
"""
try_pop!(iter::Iterators.Stateful)::Option = Iterators.isdone(iter) ? none : Some(popfirst!(iter))

"""
	try_pop!(d::AbstractDict{>:K, V}, key::K)::Option{V}

Try to pop the value corresponding to key `key` from a dictionary.
"""
function try_pop!(d::AbstractDict{>:K, V}, k::K)::Option{V} where {K, V}
	haskey(d, k) ? Some(pop!(d, k)) : none
end

"""
	try_pop!(d::AbstractDict{>:K, V}, key::K)::Option{Pair{K, V}}

Try to pop a key-value pair from a dictionary.
"""
function try_pop!(d::AbstractDict{K, V})::Option{Pair{K, V}} where {K, V}
	isempty(d) ? none : Some(pop!(d))
end

"""Try to get a value from an array or collection."""
function try_get end

"""
    try_get(a::AbstractArray{T}, index::Integer...)::Option{T}

Try to retrieve index `index` from an array. Uses [`Base.isassigned`](https://docs.julialang.org/en/v1/base/base/#Base.isassigned)
under the hood.
"""
function try_get(a::AbstractArray{T}, index::Integer...)::Option{T} where {T}
	@some_if isassigned(a, index...) a[index...]
end

"""
    try_get(s::AbstractString, i::Integer)::Option{AbstractChar}

Try to retrieve index `index` from a string. Uses [`Base.checkbounds`](https://docs.julialang.org/en/v1/base/base/#Base.checkbounds)
and [`Base.isvalid`](https://docs.julialang.org/en/v1/base/base/#Base.isvalid) under the hood.
"""
function try_get(s::AbstractString, i::Integer)::Option{AbstractChar}
	@some_if (checkbounds(s, i) && isvalid(s, i)) s[i]
end

"""
    try_get(d:AbstractDict{>:K, V}, k::K)::Option{V}

Try to retrive key `k` from a dictionary.
"""
function try_get(d::AbstractDict{>:K, V}, k::K)::Option{V} where {K, V}
	@some_if haskey(d, k) d[k]
end

"""
    try_get(t::NamedTuple, k::Union{Integer, Symbol})::Option

Try to retrieve member `k` from a [`NamedTuple`](@ref).
"""
try_get(t::NamedTuple, k::Union{Integer, Symbol})::Option = @some_if haskey(t, k) t[k]

"""
    try_get(collection, index...)::Option

Fallback method for `try_get`. Relies on exception-handling,
so it is slower than the specialized methods.
"""
try_get(a, index...)::Option = ok(@catch_result(Union{BoundsError, KeyError}, getindex(a, index...)))

"""
    try_peek(iter; state=missing)::Option

Try to get the next value from an iterator. If `state` is
not `missing`, use it in the call to [`iterate`](@ref).
"""
function try_peek end

try_peek(iter; state=missing)::Option = try_map((x) -> x[1], to_option(ismissing(state) ? iterate(iter) : iterate(iter, state)))
try_peek(iter::Iterators.Stateful; state=missing)::Option = @some_if !Iterators.isdone(iter) peek(iter)

"""
    try_first(c)::Option

Try to get the first element from a collection. Uses
[`Base.firstindex`](https://docs.julialang.org/en/v1/base/base/#Base.firstindex) under the hood.
"""
function try_first(c)::Option
	i = firstindex(c)
	try_get(c, i)
end

"""
    try_first(s::AbstractString, n::Integer)::Option{AbstractString}

Try to get the first `n` chars from a string.
"""
function try_first(s::AbstractString, i::Integer)::Option{AbstractString}
	length(s) >= i ? Some(first(s, i)) : none
end

"""
    try_last(c)::Option

Try to get the last element from a collection.
"""
function try_last(c)::Option
	i = lastindex(c)
	try_get(c, i)
end

end #module
