using Test, Documenter, Results

@testset "is_ok" begin
	@test is_ok(Ok(5))
	@test !is_ok(Err(5))
	@test is_ok(Ok(Err(5)))
	@test !is_ok(Err(Ok(5)))
	@test_throws MethodError is_ok("bare")
	@test_throws MethodError is_ok(BoundsError())
end

@testset "Doctests" begin
	DocMeta.setdocmeta!(Results, :DocTestSetup, :(using Results))
	doctest(Results; manual = false)
end