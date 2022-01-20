module Results

include("Types.jl")

include("Macros.jl")

module Functions

using ..Types
using ..Macros

include("io.jl")
include("predicates.jl")
include("transform.jl")

end # module

module Operators

using ..Functions: ←, →, ⊗
export ←, →, ⊗

end # module

include("Collection.jl")

using .Types
using .Functions
using .Macros
using .Collection

# core types
export Option, Result, Ok, Err, None, none
# input functions
export to_option, to_result
# output functions
export unwrap, unwrap_or, to_nullable
# predicates
export is_ok, is_err, is_some, is_none, has_val
# transform functions
export ok_or, ok
export try_map, map_err
export and_then, try_collect, try_collect_option, try_collect_result
export flatten
# macros
export @try_unwrap, @unwrap_or, @catch_result
export @some_if, @if_let, @while_let
# collection functions
export try_pop!, try_get, try_peek, try_first, try_last



end #module
