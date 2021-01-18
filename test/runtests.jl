using Test, Documenter
using Results
using Results: ⊗, ←, →

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

@testset "Results" begin

	@testset "convert" begin
		@test isa(convert(Ok{AbstractString}, Ok{String}("test")), Ok{AbstractString})
		@test isa(convert(Result{Int, Union{}}, Ok(5)), Result{Int, Union{}})
		@test isa(convert(Result{Any, String}, Ok(5)), Result{Any, String})
	end

	@testset "try_collect" begin
		@test try_collect([Ok(5), Ok(10), Ok(3)]) == Ok([5, 10, 3])
		@test try_collect([Ok(10), Err("err1"), Err("err2")]) == Err("err1")
		@test try_collect([Err("err1"), Err("err2")]) == Err("err1")
		@test_throws ErrorException try_collect([])
		@test try_collect([nothing]) === nothing
		@test try_collect([Some(5), nothing]) === nothing
		@test try_collect([Some(5), Some(10)]) == Some([5, 10])
		@test try_collect([Ok(5), nothing]) == Ok([5, nothing])

		@test try_collect(Any[Ok(5), Ok(10), Ok(3)]) == Ok([5, 10, 3])
		@test try_collect(Any[nothing]) === nothing

		@test_throws ErrorException try_collect([5, 10, 30])
		@test try_collect(Union{Int, Ok{Int}}[5, Ok(10), Ok(20)]) == Ok([5, 10, 20])
		@test_throws ErrorException try_collect(Any[5, Ok(10), Ok(20)])
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

	@testset "ok" begin
		@test @inferred(ok(Ok(5))) === Some(5)
		@test @inferred(ok(Err("err"))) === nothing
		local r::Result{Int, String} = Ok(0)
		@test @inferred(ok(r)) === Some(0)

		@testset "ok() type inference" begin
			@test possible_types(ok, Ok{Int64}) == Set([Some{Int64}])
			@test possible_types(ok, Err{Any}) == Set([Nothing])
			@test possible_types(ok, Result{Int64, Any}) == Set([Some{Int64}, Nothing])
		end
	end

	@testset "ok_or" begin
		@test @inferred(ok_or(nothing, () -> "err")) === Err("err")
		@test @inferred(ok_or(nothing, "err")) === Err("err")
		@test @inferred(ok_or(Some(5), () -> "err")) === Ok(5)
		@test @inferred(ok_or(Some(5), "err")) === Ok(5)

		@testset "ok_or() type inference" begin
			@test possible_types(ok_or, (Some{Int64}, Any)) == Set([Ok{Int64}])
			@test possible_types(ok_or, (Nothing, Int64)) == Set([Err{Int64}])
			@test possible_types(ok_or, (Nothing, Function)) == Set([unknown_err])
			@test possible_types(ok_or, (Union{Some{Int64}, Nothing}, String)) == Set([Ok{Int64}, Err{String}])
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

		@test eltype(Ok(5)) === Int
		@test eltype(Err(6)) === Union{}
		@test eltype(Result{Int64, String}) === Int64
		@test eltype(Ok(5)) === Int
		@test eltype(nothing) === Union{}
		@test eltype(Option{Int64}) === Int64
	end

	@testset "⊗ operator" begin
		@test @inferred(Ok(5) ⊗ (n) -> Ok(n*2) ⊗ (n) -> Ok(n+1)) == Ok(11)
		@test @inferred(Err(5) ⊗ (n) -> Ok(n*2) ⊗ (n) -> Ok(n+1)) == Err(5)
		@test (Ok(5) ⊗ Ok(2) ⊗ >(1)) == Ok(true)
		@test (Err(5) ⊗ Ok(2) ⊗ (n) -> Ok(n+1)) == Err(5)
	end

	@testset "& operator" begin
		@test @inferred(Ok(5) & Err(6) & Ok(10)) == Err(6)
		@test @inferred(Ok(5) & Ok(6) & Ok(7)) == Ok(7)
		@test @inferred(Ok(5) & () -> Err(6) & Ok(10)) == Err(6)
		@test @inferred(Ok(5) & Ok(6) & () -> Ok(7)) == Ok(7)
		@test Base.operator_associativity(:&) == :left
	end

	@testset "| operator" begin
		@test @inferred(Err("e1") | Err("e2") | () -> Ok(5)) == Ok(5)
		@test @inferred(Err("e1") | Err("e2") | Err("e5")) == Err("e5")
		@test Base.operator_associativity(:&) == :left
		@test_throws MethodError Err("e1") | 5
	end

	DocMeta.setdocmeta!(Results, :DocTestSetup,
	                    :(using Results;
	                      using Results: ⊗, ←, →, strip_result_type))
	doctest(Results; manual = false)

end
