@testset "predicates.jl" begin

	@testset "is_ok" begin
		@test is_ok(Ok(5))
		@test !is_ok(Err(5))
		@test is_ok(Ok(Err(5)))
		@test !is_ok(Err(Ok(5)))
		@test_throws MethodError is_ok("bare")
		@test_throws MethodError is_ok(BoundsError())

		@test possible_types(is_ok, Result) == Set([Bool])
	end

	@testset "is_err" begin
		@test !is_err(Ok(5))
		@test is_err(Err(5))
		@test !is_err(Ok(Err(5)))
		@test is_err(Err(Ok(5)))
		@test_throws MethodError is_err("bare")
		@test_throws MethodError is_err(BoundsError())

		@test possible_types(is_err, Result) == Set([Bool])
	end

end
