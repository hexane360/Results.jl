@testset "transform.jl" begin

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

		@test try_collect(Ok(5), Ok(10), Ok(3)) == Ok([5, 10, 3])
		@test try_collect(Some(5), Some(10), Ok(30)) == Some([5, 10, Ok(30)])
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
		@test try_map(Some(+), Some(5), Some(10)) === Some(15)
		@test try_map(Some(+), none, Some(10)) === none
		@test try_map(none, Some(5), Some(10)) === none

		@test try_map(Err("func error"), Ok(5), Err("error")) === Err("func error")
		@test try_map(Ok(+), Err("err1"), Err("err2")) === Err("err1")
		@test @inferred(try_map(double, Ok(0))) === Ok(0)
		@test @inferred(try_map(double, Ok(8))) === Ok(16)
		@test @inferred(try_map(double, Err("error"))) === Err("error")

		f = try_map(+)
		@test f(Ok(5), Ok(10)) == Ok(15)
		@test f(Err("err")) == Err("err")

		@testset "try_map type inference" begin
			@test possible_types(try_map, (Function, Some{Int64})) == Set([unknown_some])
			@test possible_types(try_map, (Function, None)) == Set([None])
			@test possible_types(try_map, (None, Some{Int64})) == Set([None])
			@test possible_types(try_map, (Function, Ok{Int64})) == Set([unknown_ok])
			@test possible_types(try_map, (Function, Err{String})) == Set([Err{String}])
			@test possible_types(try_map, (Err{String}, Ok{Int64})) == Set([Err{String}])
			@test possible_types(try_map, (Err{String}, Err{Int64})) == Set([Err{String}])
		end
	end

	@testset "map_err" begin
		local double(x) = 2*x
		@test map_err(double, Ok(5)) == Ok(5)
		@test map_err(double, Err(5)) == Err(10)

		f = map_err(double)
		@test f(Err(10)) == Err(20)
	end

	@testset "and_then" begin
		@test and_then(Ok(5), (n) -> Ok(n*2), (n) -> Ok(n+1)) == Ok(11)
		@test and_then(Err(5), (n) -> Ok(n*2), (n) -> Ok(n+1)) == Err(5)
		@test and_then(Ok(5), Err("err1"), (n) -> Err("err2")) === Err("err1")
		f = and_then((n) -> Ok(n*2))
		@test f(Err(5)) == Err(5)
		@test f(Ok(5)) == Ok(10)
	end

	@testset "flatten" begin
		@test flatten(Ok(Ok(5))) == Ok(5)
		@test flatten(Ok(Err("err"))) == Err("err")
		@test flatten(Err("err")) == Err("err")
		@test flatten(Some(Some(5))) == Some(5)
		@test flatten(Some(none)) == none
		@test flatten(none) == none
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
		@test @inferred(none | none | () -> Some(5)) == Some(5)
		@test @inferred(none | none | none) == none
		@test @inferred(none | Some(3) | none) == Some(3)
		@test @inferred(Err("e1") | Err("e2") | () -> Ok(5)) == Ok(5)
		@test @inferred(Err("e1") | Err("e2") | Err("e5")) == Err("e5")
		@test Base.operator_associativity(:|) == :left
		@test_throws MethodError Err("e1") | 5
	end

end
