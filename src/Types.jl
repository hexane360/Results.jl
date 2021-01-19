module Types

import Base: ==
import Base: promote_rule, convert
import Base: show
import Base: iterate, eltype, length
using Base: IteratorEltype, HasEltype

export Option, Result, Ok, Err, None, none

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

"""Exception thrown when `unwrap()` is called on an `Err`"""
struct UnwrapError <: Exception
	s::String
end

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

end #module
