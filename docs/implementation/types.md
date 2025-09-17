
Types in Viro are a bit different than other languages. They are mainly used to dispatch methods on so that functions
like `next` or `mold` know how to handle the provided value. The main difference though is that types correspond to their syntactic representation because Viro is homoiconic (code is data, and data is code).

This means that there types like `word!` (like `if` or `x`), `set-word!` (like `x:`), `block!` (like `[1 2 3]`) or even `paren!` that represents a block in parens instead of square brackets `(1 2 3)`. There are also basic types: `number!`, `string!`, `bool!` and `binary!`.

Apart from syntax-related and basic value types there are also derrived types. They might be represented differently in the syntax - for example `file!` paths are written with `%` in front: `%some/file.txt` and `url!`s start with `[scheme]://` - but they also might override the functions or implement new ones. This might sound like OOP, but it's not. The derrived type does not create any new abstraction. It's more like an alias for existing base type that allows redefinition of functions.


# Lua implementation details
Each value (word, number, function, etc...) is represented by a Lua table of following structure:

```lua
 { type = ... }
```

Other fields depend on the type of the value.

Each type has a prototype (the metatable with `__index` set). Many functions that work on various data types (ie `next`,
`pick` and other series functions) will first try to run it's custom implementation for given type.


The prototypes should be accessible within Viro as `object!`. There should also be a way to bind a prototype to a value (basically set the `__index` in the metatable to that prototype).


