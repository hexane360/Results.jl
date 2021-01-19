@testset "io.jl" begin

	@testset "unwrap" begin
		@test @inferred(unwrap(Ok(5))) === 5
		@test_throws Results.Types.UnwrapError("unwrap() called on an Err: \"error\"") @inferred(unwrap(Err("error")))
		@test_throws BoundsError @inferred(unwrap(Err(BoundsError())))
		@test_throws BoundsError @inferred(unwrap(Err(5), BoundsError()))
	end

	@testset "unwrap_or" begin
		@test @inferred(unwrap_or(Ok(5), 0)) === 5
		@test @inferred(unwrap_or(Err("e"), 0)) === 0
		@test @inferred(unwrap_or(Ok(5), () -> error("long circuit"))) === 5
		@test @inferred(unwrap_or(Err("e"), () -> 1)) === 1
	end

end
