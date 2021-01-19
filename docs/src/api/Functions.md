```@meta
CurrentModule = Results.Functions
```

# [`Results.Functions`: Functions and Combinators](@id functions)

## Exported members

### Input/Output functions

```@autodocs
Modules = [Functions]
Private = false
Pages = ["io.jl"]
```

### Combinators

```@autodocs
Modules = [Functions]
Private = false
Pages = ["transform.jl"]
```

### Predicate functions

```@autodocs
Modules = [Functions]
Private = false
Pages = ["predicates.jl"]
```

## Un-exported members

```@autodocs
Modules = [Functions]
Public = false
Order = [:module, :type, :constant, :function, :macro]
Filter = f -> !isa(f, Function) || parentmodule(f) != Base
```

## [`Base`](https://docs.julialang.org/en/v1/base/base/) methods extended

```@autodocs
Modules = [Functions]
Order = [:function]
Filter = f -> parentmodule(f) == Base
```
