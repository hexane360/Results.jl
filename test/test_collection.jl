@testset "Results.Collection" begin

	@testset "try_pop!" begin
		# AbstractVector
		vec = BitVector([1, 0])  #AbstractVector
		@test try_pop!(vec) == Some(false)
		@test try_pop!(vec) == Some(true)
		@test try_pop!(vec) == none
		@test try_pop!(vec) == none

		# Stateful
		iter = Iterators.Stateful([1,2])
		@test try_pop!(iter) == Some(1)
		@test try_pop!(iter) == Some(2)
		@test try_pop!(iter) == none
		@test try_pop!(iter) == none

		# Dict
		dict = Dict(:a => 5, :b => 6)
		first = try_pop!(dict) |> unwrap
		second = try_pop!(dict) |> unwrap
		@test (:a => 5) ∈ [first, second]
		@test (:b => 6) ∈ [first, second]
		@test try_pop!(dict) == none
		@test try_pop!(dict) == none

		dict = Dict(:a => 5, :c => 7)
		@test try_pop!(dict, :a) == Some(5)
		@test try_pop!(dict, :a) == none
		@test try_pop!(dict, :c) == Some(7)
		@test try_pop!(dict, :c) == none
		@test length(dict) == 0
	end

	@testset "try_get" begin
		#AbstractArray
		mat = [1 2; 3 4]
		@test try_get(mat, 1, 2) == Some(2)
		@test try_get(mat, 3, 1) == none
		@test try_get(mat, 4) == Some(4)
		@test try_get(mat, 5) == none
		@test try_get(mat) == none

		#AbstractString
		s = "12∈67"
		@test try_get(s, 1) == Some('1')
		@test try_get(s, 7) == Some('7')
		@test try_get(s, 8) == none
		@test try_get(s, 5) == none

		#AbstractDict
		dict = Dict(:a => 5, :b => 7)
		@test try_get(dict, :a) == Some(5)
		@test try_get(dict, :a) == Some(5)
		@test try_get(dict, :b) == Some(7)
		@test try_get(dict, :c) == none

		#NamedTuple
		tup = (name = "tup", val1 = 5, val2 = nothing)
		@test try_get(tup, :name) == Some("tup")
		@test try_get(tup, 2) == Some(5)
		@test try_get(tup, :val2) == Some(nothing)
		@test try_get(tup, :val3) == none

		#fallback (AbstractChar)
		@test try_get('∈', 1) == Some('∈')
		@test try_get('∈', 2) == none
	end

	@testset "try_peek" begin
		@test try_peek([1,2,3]) == Some(1)
		@test try_peek([1,2,3]; state=2) == Some(2)
		@test try_peek([]) == none
		stateful = Iterators.Stateful([1,2,3])
		@test try_peek(stateful) == Some(1)
		@test try_peek(stateful) == Some(1)
	end

	@testset "try_first" begin
		@test try_first([1,2,3]) == Some(1)
		@test try_first([]) == none

		@test try_first("string") == Some('s')
		@test try_first("") == none
		@test try_first("string", 3) == Some("str")
		@test try_first("string", 6) == Some("string")
		@test try_first("string", 7) == none
		@test try_first("", 1) == none
	end

	@testset "try_last" begin
		@test try_last([1,2,3]) == Some(3)
		@test try_last([]) == none

		@test try_last("string") == Some('g')
		@test try_last("") == none
	end
end
