Each value (word, number, function, etc...) is represented by a Lua table of following structure:

```lua
 { type = ... }
```

Other fields depend on the type of the value.

Each type has a prototype (the metatable with `__index` set). Many functions that work on various data types (ie `next`, `pick` and other series functions) will first try to run it's custom implementation for given type.
