import Base: &, |, !
using Base: IteratorEltype, HasEltype, eltype

export ok_or, ok
export try_map, map_err
export and_then, try_collect
export flatten

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
		unwrap(
			(to_option(iterate(iter)) → x -> x[1]) ⊗ (
				function (val)
					if isa(val, Result)
						Some(true)
					elseif isa(val, Option)
						Some(false)
					else
						none
					end
				end
			),
			(_) -> ErrorException(
				"Can't infer which result type to use. Specify the" *
				" array type or explicitly use `try_collect_result" *
				" or `try_collect_option` instead."
			)
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
