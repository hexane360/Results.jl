```@meta
CurrentModule = Results.Types
```

# [`Results.Types`: Core types](@id types)

## Exported members

```@autodocs
Modules = [Types]
Private = false
Order = [:module, :type, :constant, :function, :macro]
```

## Un-exported members

```@autodocs
Modules = [Types]
Public = false
Order = [:module, :type, :constant, :function, :macro]
Filter = f -> !isa(f, Function) || parentmodule(f) != Base
```

## [`Base`](https://docs.julialang.org/en/v1/base/base/) methods extended

```@autodocs
Modules = [Types]
Order = [:function]
Filter = f -> parentmodule(f) == Base
```
