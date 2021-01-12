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
