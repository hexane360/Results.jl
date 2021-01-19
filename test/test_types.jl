@testset "Results.Types" begin

	@testset "convert" begin
		@test isa(convert(Ok{AbstractString}, Ok{String}("test")), Ok{AbstractString})
		@test isa(convert(Result{Int, Union{}}, Ok(5)), Result{Int, Union{}})
		@test isa(convert(Result{Any, String}, Ok(5)), Result{Any, String})
	end

	@testset "iterate" begin
		@test collect(Ok(5)) == [5]
		@test collect(Err(5)) == []
		@test collect(Some(5)) == [5]
		@test collect(nothing) == []

		@test length(Ok(5)) === 1
		@test length(Err(5)) === 0
		@test length(Some(5)) === 1
		@test length(nothing) === 0

		@test Base.IteratorSize(Ok(5)) === Base.HasLength()
		@test Base.IteratorSize(Err(5)) === Base.HasLength()
		@test Base.IteratorSize(Some(5)) === Base.HasLength()
		@test Base.IteratorSize(nothing) === Base.HasLength()

		@test eltype(Ok(5)) === Int
		@test eltype(Err(6)) === Union{}
		@test eltype(Result{Int64, String}) === Int64
		@test eltype(Ok(5)) === Int
		@test eltype(nothing) === Union{}
		@test eltype(Option{Int64}) === Int64
	end

end
