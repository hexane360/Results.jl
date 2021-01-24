export is_ok, is_err, is_some, is_none, has_val

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
    has_val(result::Union{Result, Option})::Bool

Returns true for a successful `Result` or `Option`."""
function has_val end

has_val(::Ok)::Bool = true
has_val(::Err)::Bool = false
has_val(::Some)::Bool = true
has_val(::None)::Bool = false
