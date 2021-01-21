module Collection

using ..Types
using ..Functions
using ..Macros

export try_pop!, try_get, try_peek, try_first, try_last

"""Try to pop a value from a collection."""
function try_pop! end

"""
    try_pop!(a::AbstractVector)::Option{T}

Try to pop a value from a vector.
"""
function try_pop!(a::AbstractVector{T})::Option{T} where {T}
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
	@some_if checkbounds(Bool, a, index...) a[index...]
end

"""
    try_get(s::AbstractString, i::Integer)::Option{AbstractChar}

Try to retrieve index `index` from a string. Uses [`Base.checkbounds`](https://docs.julialang.org/en/v1/base/base/#Base.checkbounds)
and [`Base.isvalid`](https://docs.julialang.org/en/v1/base/base/#Base.isvalid) under the hood.
"""
function try_get(s::AbstractString, i::Integer)::Option{AbstractChar}
	@some_if isvalid(s, i) s[i]
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

Try to retrieve member `k` from a [`Base.NamedTuple`](https://docs.julialang.org/en/v1/base/base/#Base.NamedTuple).
"""
try_get(t::NamedTuple, k::Union{Integer, Symbol})::Option = @some_if haskey(t, k) t[k]

"""
    try_get(collection, index...)::Option

Fallback method for `try_get`. Relies on exception-handling,
so it is slower than the specialized methods.
"""
try_get(a, index...)::Option = ok(@catch_result(Union{BoundsError, KeyError, UndefRefError},
                                                getindex(a, index...)))

"""
    try_peek(iter; state=missing)::Option

Try to get the next value from an iterator. If `state` is
not `missing`, use it in the call to [`iterate`](@ref).
"""
function try_peek end

try_peek(iter; state=missing)::Option = try_map((x) -> x[1], to_option(ismissing(state) ? iterate(iter) : iterate(iter, state)))
try_peek(iter::Iterators.Stateful)::Option = @some_if !Iterators.isdone(iter) peek(iter)

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

end # module
