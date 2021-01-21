using Test, Documenter
using Results
using Results.Operators

function possible_types(f::Function, args::Tuple)::Set{Type}
	Set(map(c -> c.second, code_typed(f, args)))
end

possible_types(f::Function, arg::Type)::Set{Type} = possible_types(f, (arg,))

const unknown_ok = let _A = TypeVar(:_A)
	UnionAll(_A, Ok{_A})
end
const unknown_err = let _A = TypeVar(:_A)
	UnionAll(_A, Err{_A})
end
const unknown_some = let _A = TypeVar(:_A)
	UnionAll(_A, Some{_A})
end

@testset "Results" begin

	include("test_types.jl")

	@testset "Results.Functions" begin

		include("test_io.jl")
		include("test_predicates.jl")
		include("test_transform.jl")

	end

	include("test_macros.jl")

	include("test_collection.jl")

	DocMeta.setdocmeta!(Results, :DocTestSetup,
	                    :(using Results))
	DocMeta.setdocmeta!(Results.Types, :DocTestSetup,
	                    :(using Results; using Results.Types))
	DocMeta.setdocmeta!(Results.Functions, :DocTestSetup,
	                    :(using Results; using Results.Functions; using Results.Operators))
	DocMeta.setdocmeta!(Results.Macros, :DocTestSetup,
	                    :(using Results; using Results.Macros))
	DocMeta.setdocmeta!(Results.Collection, :DocTestSetup,
	                    :(using Results; using Results.Collection))

	doctest(Results; manual = false)
end
