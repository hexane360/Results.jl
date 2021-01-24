@testset "predicates.jl" begin

	@testset "is_ok" begin
		@test is_ok(Ok(5))
		@test !is_ok(Err(5))
		@test is_ok(Ok(Err(5)))
		@test !is_ok(Err(Ok(5)))
		@test_throws MethodError is_ok("bare")
		@test_throws MethodError is_ok(BoundsError())

		@test is_ok(Ok(5), 5)
		@test !is_ok(Ok(5), 6)
		@test !is_ok(Err(5), 5)

		@test possible_types(is_ok, Result) == Set([Bool])
		@test possible_types(is_ok, (Result, Any)) == Set([Bool])
	end

	@testset "is_err" begin
		@test !is_err(Ok(5))
		@test is_err(Err(5))
		@test !is_err(Ok(Err(5)))
		@test is_err(Err(Ok(5)))
		@test_throws MethodError is_err("bare")
		@test_throws MethodError is_err(BoundsError())

		@test is_err(Err(5), 5)
		@test !is_err(Err(5), 6)
		@test !is_err(Ok(5), 5)

		@test possible_types(is_err, Result) == Set([Bool])
		@test possible_types(is_err, (Result, Any)) == Set([Bool])
	end

	@testset "is_some" begin
		@test is_some(Some(none))
		@test !is_some(none)
		@test_throws MethodError is_some("bare")

		@test is_some(Some(5), 5)
		@test !is_some(Some(5), 6)
		@test !is_some(none, 5)

		@test possible_types(is_some, Option) == Set([Bool])
		@test possible_types(is_some, (Option, Any)) == Set([Bool])
	end

	@testset "is_none" begin
		@test !is_none(Some(none))
		@test is_none(none)
		@test_throws MethodError is_none("bare")

		@test possible_types(is_none, Option) == Set([Bool])
	end

	@testset "has_val" begin
		@test has_val(Ok(5))
		@test !has_val(Err(5))
		@test has_val(Some(5))
		@test !has_val(none)
		@test_throws MethodError has_val("bare")

		@test possible_types(has_val, Union{Result, Option}) == Set([Bool])
	end
end
