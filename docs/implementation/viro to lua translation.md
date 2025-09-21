# Viro to Lua translation

This document outlines how Viro syntax is translated into Lua. 

Viro code is first translated into REBOL-like blocks that are then treated as
list tokens to build the AST tree which is then translated into Lua code.


## Syntax elements

### Literal values

Literals are translated directly to Lua's values. We have `string`, `number`,
`boolean`. Compiling this Viro code

```viro
1
true
"hello"
```

results in exactly the same Lua code:

```lua
1
true
return "hello"
```

### Words

Words in Viro may represent different values so their representation depends on the context. This example shows it pretty well:

```viro
x: 10
mold 1 + x
```

the resulting Lua code would look something like this:

```lua 
x = 10
return viro.mold(1 + x)
```

### Set-Word


### Set-Path




## Loading into Lua 

After generating the code the Lua's `load` function is called. This function
accepts `env` which corresponds directly to the Viro's execution context. Scope
layering might be done through the `__index` field in the `env` metatable:
`setmetatable(env, { __index = parent })`.
