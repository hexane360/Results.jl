"""
Unwraps an Ok or Some value, while returning error values upstream.
Highly useful for chaining computations together.

# Example
```jldoctest
julia> function test(x::Result)::Result
           y = @try_unwrap(x) .- 5
           z = @try_unwrap try_pop!(y, "Empty array")
           Ok(z)
       end
test (generic function with 1 method)

julia> test(Ok([5, 8]))
Ok{Int64}(3)
julia> test(Ok([]))
Err{String}("Empty array")
julia> test(Err(5))
Err{Int64}(5)
```
"""
macro try_unwrap(ex)
	return quote
		val = $(esc(ex))
		has_val(val) ? unwrap(val) : return val
	end
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
"""
macro while_let(assign::Expr, block::Expr)
	if !(assign.head === :(=) && length(assign.args) == 2)
		error("Expected assignment expression, instead got '$assign'")
	end
	place = assign.args[1]
	expr = assign.args[2]
	return quote
		while true
			opt = $(esc(expr))
			$(esc(place)) = has_val(opt) ? unwrap(opt) : break
			$(esc(block))
		end
	end
end
