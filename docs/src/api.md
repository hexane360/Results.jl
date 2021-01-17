```@meta
CurrentModule = Results
```
# API

## Exported members

### Core types

```@docs
Result
Option
Ok
Err
None
none
```

### Input functions

```@docs
to_option
to_result
```

### Output functions

```@docs
unwrap
unwrap_or
to_nullable
```

### Combinators

```@docs
try_map
map_err
and_then
try_collect
flatten
ok
ok_or
```

### Predicate functions

```@docs
is_ok
is_err
is_some
is_none
has_val
```

### Collection utilities

```@docs
try_pop!
try_get
try_peek
try_first
try_last
```

### Macros

```@autodocs
Modules = [Results]
Private = false
Order = [:macro]
```

## Un-exported members

```@autodocs
Modules = [Results]
Public = false
Order = [:module, :type, :constant, :function, :macro]
Filter = f -> !isa(f, Function) || parentmodule(f) != Base
```

## [`Base`](https://docs.julialang.org/en/v1/base/base/) methods extended

```@autodocs
Modules = [Results]
Order = [:function]
Filter = f -> parentmodule(f) == Base
```
