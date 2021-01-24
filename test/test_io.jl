@testset "io.jl" begin

	@testset "to_result" begin
		@test to_result(5, "error") == Ok(5)
		@test to_result(nothing, "error") == Err("error")
		@test to_result(5, () -> error("Not lazy")) == Ok(5)
		@test to_result(nothing, () -> "lazy") == Err("lazy")

		f = to_result("error")
		@test isa(f, Function)
		@test f(5) == Ok(5)
		@test f(nothing) == Err("error")
	end

	@testset "to_option" begin
		@test to_option(5) == Some(5)
		@test to_option(nothing) == none

		@test to_option(Ok(5)) == Some(5)
		@test to_option(Err("error")) == none
	end

	@testset "to_nullable" begin
		@test to_nullable(Some(5)) == 5
		@test to_nullable(Some(Some(5))) == Some(5)
		@test to_nullable(none) === nothing

		@test to_nullable(Ok(5)) == 5
		@test to_nullable(Err("err")) === nothing
	end

	@testset "unwrap" begin
		@test @inferred(unwrap(Some(5))) == 5
		@test @inferred(unwrap(Ok(5))) == 5
		@test @inferred(unwrap(Ok(5), BoundsError())) == 5

		@test_throws Results.Types.UnwrapError("unwrap() called on an Err: \"error\"") @inferred(unwrap(Err("error")))
		@test_throws Results.Types.UnwrapError("unwrap() called on None") unwrap(none)
		@test @inferred(unwrap(Ok(5), (e) -> error("test"))) == 5
		@test_throws ErrorException("err 'test'") unwrap(Err("test"), e -> error("err '$e'"))
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
