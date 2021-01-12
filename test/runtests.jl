using Test, Documenter, Results

function possible_types(f::Function, args::Tuple)::Set{Type}
	Set(map(c -> c.second, code_typed(f, args)))
end

possible_types(f::Function, arg::Type)::Set{Type} = possible_types(f, (arg,))

const unknown_ok =let _A = TypeVar(:_A)
	UnionAll(_A, Ok{_A})
end
const unknown_err = let _A = TypeVar(:_A)
	UnionAll(_A, Err{_A})
end

@testset "convert" begin
	@test isa(convert(Ok{AbstractString}, Ok{String}("test")), Ok{AbstractString})
	@test isa(convert(Result{Int, Union{}}, Ok(5)), Result{Int, Union{}})
end

@testset "try_collect" begin
	@test try_collect([Ok(5), Ok(10), Ok(3)]) == Ok([5, 10, 3])
	@test try_collect([Ok(10), Err("err1"), Err("err2")]) == Err("err1")
	@test try_collect([Err("err1"), Err("err2")]) == Err("err1")
	@test try_collect([]) == Ok([])
	@test try_collect([nothing]) === nothing
	@test try_collect([Some(5), nothing]) === nothing
	@test try_collect([Some(5), Some(10)]) == Some([5, 10])
	@test try_collect([Ok(5), nothing]) === nothing
end

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

@testset "to_option" begin
	@test @inferred(to_option(Ok(5))) === Some(5)
	@test @inferred(to_option(Err("err"))) === nothing
	local r::Result{Int64, String} = Ok(0)
	@test @inferred(to_option(r)) === Some(0)

	@testset "to_option type inference" begin
		@test possible_types(to_option, Ok{Int64}) == Set([Some{Int64}])
		@test possible_types(to_option, Err{Any}) == Set([Nothing])
		@test possible_types(to_option, Result{Int64, Any}) == Set([Some{Int64}, Nothing])
	end
end

@testset "to_result" begin
	@test @inferred(to_result(nothing, () -> "err")) === Err("err")
	@test @inferred(to_result(nothing, "err")) === Err("err")
	@test @inferred(to_result(Some(5), () -> "err")) === Ok(5)
	@test @inferred(to_result(Some(5), "err")) === Ok(5)

	@testset "to_result type inference" begin
		@test possible_types(to_result, (Some{Int64}, Any)) == Set([Ok{Int64}])
		@test possible_types(to_result, (Nothing, Int64)) == Set([Err{Int64}])
		@test possible_types(to_result, (Nothing, Function)) == Set([unknown_err])
		@test possible_types(to_result, (Union{Some{Int64}, Nothing}, String)) == Set([Ok{Int64}, Err{String}])
	end
end

@testset "try_map" begin
	local double(x) = 2*x
	@test @inferred(try_map(double, Ok(0))) === Ok(0)
	@test @inferred(try_map(double, Ok(8))) === Ok(16)
	@test @inferred(try_map(double, Err("error"))) === Err("error")
	@test try_map(Some(+), Some(5), Some(10)) === Some(15)

	@testset "try_map type inference" begin
		@test possible_types(try_map, (Function, Ok{Int64})) == Set([unknown_ok])
		@test possible_types(try_map, (Function, Err{String})) == Set([Err{String}])
	end
end

@testset "unwrap" begin
	@test @inferred(unwrap(Ok(5))) === 5
	@test_throws Results.UnwrapError("unwrap() called on an Err: \"error\"") @inferred(unwrap(Err("error")))
	@test_throws BoundsError @inferred(unwrap(Err(BoundsError())))
	@test_throws BoundsError @inferred(unwrap(Err(5), BoundsError()))
end

@testset "unwrap_or" begin
	@test @inferred(unwrap_or(Ok(5), 0)) === 5
	@test @inferred(unwrap_or(Err("e"), 0)) === 0
	@test @inferred(unwrap_or(Ok(5), () -> error("long circuit"))) === 5
	@test @inferred(unwrap_or(Err("e"), () -> 1)) === 1
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

	@test eltype(Ok(5)) === Int64
	@test eltype(Err(6)) === Union{}
	@test eltype(Result{Int64, String}) === Int64
	@test eltype(Ok(5)) === Int64
	@test eltype(nothing) === Union{}
	@test eltype(Option{Int64}) === Int64
end

@testset "⋄ operator" begin
	@test @inferred(Ok(5) ⋄ (n) -> Ok(n*2) ⋄ (n) -> Ok(n+1)) == Ok(11)
	@test @inferred(Err(5) ⋄ (n) -> Ok(n*2) ⋄ (n) -> Ok(n+1)) == Err(5)
	@test (Ok(5) ⋄ Ok(2) ⋄ >(1)) == Ok(true)
	@test (Err(5) ⋄ Ok(2) ⋄ (n) -> Ok(n+1)) == Err(5)
end

@testset "& operator" begin
	@test @inferred(Ok(5) & Err(6) & Ok(10)) == Err(6)
	@test @inferred(Ok(5) & Ok(6) & Ok(7)) == Ok(7)
	@test @inferred(Ok(5) & () -> Err(6) & Ok(10)) == Err(6)
	@test @inferred(Ok(5) & Ok(6) & () -> Ok(7)) == Ok(7)
end

@testset "| operator" begin
	@test @inferred(Err("e1") | Err("e2") | () -> Ok(5)) == Ok(5)
	@test @inferred(Err("e1") | Err("e2") | Err("e5")) == Err("e5")
	@test_throws MethodError Err("e1") | 5
end

@testset "Doctests" begin
	DocMeta.setdocmeta!(Results, :DocTestSetup, :(using Results))
	doctest(Results; manual = false)
end
