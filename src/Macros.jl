module Macros

using Results

export @try_unwrap, @unwrap_or, @catch_result
export @some_if, @if_let, @while_let

"""
Unwraps an Ok or Some value, while returning error values upstream.
Highly useful for chaining computations together.

# Example
```jldoctest
julia> function test(x::Result)::Result
           y = @try_unwrap(x) .- 5
           z = @try_unwrap try_pop!(y) |> ok_or("Empty array")
           Ok(z)
       end
test (generic function with 1 method)

julia> test(Ok([5, 8]))
Ok(3)
julia> test(Ok([]))
Err("Empty array")
julia> test(Err(5))
Err(5)
```
"""
macro try_unwrap(ex)
	return quote
		val = $(esc(ex))
		has_val(val) ? unwrap(val) : return val
	end
end

"""
Macro version of `unwrap_or`, which allows for the
embedding of control statements in the or clause.

# Example
```jldoctest
julia> for v in [[2,3,4], [3,4,5], [], [1]]
           println(@unwrap_or(try_get(v, 1), break))
       end
2
3
```
"""
macro unwrap_or(expr, or)
	quote
		v = $(esc(expr))
		has_val(v) ? unwrap(v) : $(esc(or))
	end
end

"""
Catches an exception inside `expr` and returns a `Result` instead.

If a type is given, only exceptions of that type will be caught.

# Examples
```jldoctest; filter = r"Array{\\S+,1}|Vector{\\S+}"
julia> @catch_result begin
           arr = [5,3,2]
           arr[4]
       end
Err(BoundsError([5, 3, 2], (4,)))
julia> @catch_result [5,3,2][3]
Ok(2)
julia> @catch_result TypeError [5,3,2][4]
ERROR: BoundsError: attempt to access 3-element Array{Int64,1} at index [4]
```
"""
macro catch_result(exception_type, expr)
	quote
		try
			Ok($(esc(expr)))
		catch e
			isa(e, $exception_type) ? Err(e) : rethrow(e)
		end
	end
end

macro catch_result(expr) :(@catch_result(Exception, $(esc(expr)))) end

"""
If `predicate`, evaluate the enclosed expression wrapped in `Some`.
Otherwise, return `None`.

# Example
```jldoctest
julia> try_get(a, index) = @some_if isassigned(a, index) a[index]
try_get (generic function with 1 method)
julia> try_get([2,3,4], 2)
Some(3)
julia> try_get([1,2,3], 10)

```
"""
macro some_if(predicate, expr)
	:($(esc(predicate)) ? Some($(esc(expr))) : none)
end

"""
Loop `block` while the assignment expression `assign` returns an Ok or Some value.

# Example
```jldoctest
julia> a = [1,2,3];

julia> @while_let val = try_pop!(a) begin
           print(val)
       end
321
```
"""
macro while_let(assign::Expr, block::Expr)
	if !(assign.head === :(=) && length(assign.args) == 2)
		error("Expected assignment expression, instead got '$assign'")
	end
	place = assign.args[1]
	expr = assign.args[2]
	quote
		while true
			opt = $(esc(expr))
			$(esc(place)) = has_val(opt) ? unwrap(opt) : break
			$(esc(block))
		end
	end
end

"""
Run `then_block` if the assignment expression returns an `Ok` or `Some` value.
Runs `else_block` otherwise.

# Example
```jldoctest
julia> @if_let val = Some(5) begin
           2*val
       end begin
           0
       end
10
julia> @if_let val = Err("error") begin
           2*val
       end begin
           0
       end
0
julia> @if_let val = Err("error") begin
           println(val)
       end
```
"""
macro if_let(assign::Expr, then_block::Expr, else_block::Expr)
	if !(assign.head === :(=) && length(assign.args) == 2)
		error("Expected assignment expression, instead got '$assign'")
	end
	place = assign.args[1]
	expr = assign.args[2]
	return quote
		opt = $(esc(expr))
		if has_val(opt)
			$(esc(place)) = unwrap(opt)
			$(esc(then_block))
		else
			$(esc(else_block))
		end
	end
end

macro if_let(assign::Expr, then_block::Expr)
	:(@if_let $assign $then_block begin nothing end)
end

end # module
