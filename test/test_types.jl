@testset "Results.Types" begin

	@testset "convert" begin
		@test isa(convert(Ok{AbstractString}, Ok{String}("test")), Ok{AbstractString})
		@test isa(convert(Result{Int, Union{}}, Ok(5)), Result{Int, Union{}})
		@test isa(convert(Result{Any, String}, Ok(5)), Result{Any, String})

		@test isa(convert(Err{AbstractString}, Err{String}("test")), Err{AbstractString})
		@test isa(convert(Result{Union{}, Int}, Err(5)), Result{Union{}, Int})
		@test isa(convert(Result{String, Any}, Err(5)), Result{String, Any})

		@test_throws MethodError convert(Ok{String}, Ok(5))
	end

	@testset "promote" begin
		@test promote_type(Ok{Int32}, Ok{Int64}) == Ok{Int64}
		@test promote_type(Err{Int32}, Err{Int64}) == Err{Int64}
		@test promote_type(Err{String}, Ok{Int32}) == Result{Int32, String}
		@test promote(Ok{Int32}(5), Ok{Int64}(6)) == (Ok{Int64}(5), Ok{Int64}(6))
		@test promote(Err{Int32}(5), Err{Int64}(6)) == (Err{Int64}(5), Err{Int64}(6))
	end

	@testset "iterate" begin
		@test iterate(none) === nothing

		@test collect(Ok(5)) == [5]
		@test collect(Err(5)) == []
		@test collect(Some(5)) == [5]
		@test collect(nothing) == []
	end

	@testset "==" begin
		@test Some([1,2,3]) == Some([1,2,3])
		@test Some([1,2,3]) != Some([1,2])
		@test Ok([1,2,3]) == Ok([1,2,3])
		@test Ok([1,2,3]) != Ok([1,2])
		@test Err([1,2,3]) == Err([1,2,3])
		@test Err([1,2,3]) != Err([1,2])
	end

	@testset "show" begin
		io = IOBuffer()

		show(io, Some(5))
		@test io |> take! |> String == "Some(5)"
		show(io, Some{Int32}[Some(5), Some(6)])
		@test io |> take! |> String == "Some{Int32}[5, 6]"

		show(io, Ok(5))
		@test io |> take! |> String == "Ok(5)"
		show(io, Ok{Int32}[Ok(5), Ok(6)])
		@test io |> take! |> String == "Ok{Int32}[5, 6]"

		show(io, Err(5))
		@test io |> take! |> String == "Err(5)"
		show(io, Err{Int32}[Err(5), Err(6)])
		@test io |> take! |> String == "Err{Int32}[5, 6]"
	end

	@testset "length" begin
		@test length(Ok(5)) === 1
		@test length(Err(5)) === 0
		@test length(Some(5)) === 1
		@test length(nothing) === 0
	end

	@testset "IteratorSize" begin
		@test Base.IteratorSize(Ok(5)) === Base.HasLength()
		@test Base.IteratorSize(Err(5)) === Base.HasLength()
		@test Base.IteratorSize(Some(5)) === Base.HasLength()
		@test Base.IteratorSize(nothing) === Base.HasLength()
	end

	@testset "eltype" begin
		@test eltype(Ok(5)) === Int
		@test eltype(Err(6)) === Union{}
		@test eltype(Result{Int64, String}) === Int64
		@test eltype(Ok(5)) === Int
		@test eltype(nothing) === Union{}
		@test eltype(Option{Int64}) === Int64
	end

	@testset "iterate Type{}" begin
		# needed because of https://github.com/JuliaLang/julia/commit/0413ef0e4de83b41b637ba02cc63314da45fe56b
		@test iterate(Ok{Type{Int32}}(Int32)) == (Int32, nothing)
		@test iterate(Ok{Type{Int32}}(Int32), nothing) === nothing
		@test iterate(Some{Type{Int32}}(Int32)) == (Int32, nothing)
		@test iterate(Some{Type{Int32}}(Int32), nothing) === nothing
	end
end
