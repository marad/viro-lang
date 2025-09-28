# Viro Language Specification

## Overview

This document provides a comprehensive specification for the Viro programming language with REBOL-like syntax. The language combines REBOL's elegant minimal syntax with runtime compilation capabilities.

---

## Part I: Language Specification

### 1. Core Language Design

#### 1.1 Design Philosophy
- **Minimal Syntax**: Following REBOL's principle of "almost no keywords"
- **Block-Structured**: Primary data structure is the block `[...]`
- **Homoiconic**: Code and data share the same representation
- **Expression-Oriented**: Everything returns a value
- **Lua-Compatible**: Generates Lua code

#### 1.2 Basic Syntax Elements

##### 1.2.1 Comments
```
; This is a line comment
; Multi-line comments use multiple semicolons
```

##### 1.2.2 Literals
```
; Numbers
42
3.14159
-17

; Strings
"hello world"
{multi-line
string content}

; Logic values
true
false
none  ; represents no value
```

##### 1.2.3 Words and Identifiers
```
; Simple words
name
counter
user-data
file?
valid!

; Special word types
word        ; regular word
:word       ; get-word (immediate evaluation)
'word       ; lit-word (quoted word)
word:       ; set-word (assignment target)
```

#### 1.3 Data Structures

##### 1.3.1 Blocks
Primary container type:
```
[1 2 3 4]           ; simple block
[name "John" age 25] ; key-value style
```

##### 1.3.2 Objects
Objects using make function with specified type and block syntax:
```
person: make object! [
    name: "John"
    age: 25
    greet: func [] [
        print ["Hello, I'm" name]
    ]
]
```

### 2. Control Structures

#### 2.1 Conditional Expressions
```
; if-then
if condition true-branch

; if-then-else
if-else condition true-branch false-branch
either condition true-branch false-branch

; case statement
case [
    condition1 action1-branch
    condition2 action2-branch
    true default-action-branch  ; default case
]
```

For each conditional branch any Viro value can be specified and that value should be returned:

```
if true 5 ; returns 5
either false "hello" "world" ; returns "world"
case [
    0 < 1 42 
] ; returns 42
```

If the supplied value is of type `block!` then the block is executed and it's last value is returned.

For `case` and `if`, when there is no value to return, the `none` value is returned.

```
if false 42 ; returns none
case [
    1 > 2 42
] ; returns none
```

#### 2.2 Loops
```
; repeat loop
repeat i 10 [print i]

; while loop
while [condition] [action]

; for-each loop
foreach item collection [print item]

; for loop with range
for i 1 10 1 [print i]
```

#### 2.3 Function Definition
```
; Simple function
add: fn [a b] [a + b]

; Function with refinements (optional named parameters)
divide: fn [a b --safe] [
    either safe [
        either b = 0 [none] [a / b]
    ] [
        a / b
    ]
]

; Refinement with a value
example: fn [--arg argval] [ argval ]
```

Refinements, when absent, receive `none` value. Valueless (like `--safe` above) refinement receive `true` when present.

##### 2.3.1 Unquoted arguments
Functions can specify that the argument should NOT be evaluated by using the quote `'`.

```
foreach: fn ['var collection body] [...] ; the `var` argument will not be evaluated
foreach x [1 2 3] [print x]
```

In above example `x` is NOT evaluated, and the word `x` itself is passed to `foreach` as the value for the `var` argument.
It might be then used to bind the value of consecutive elements of the collection to that name before evaluation of the loop's body.

### 3. Expression Evaluation

#### 3.1 No Operator Precedence
Rvaluation is strictly left-to-right so math operations require explicit grouping:
```
2 + 3 * 4    ; equals 20, not 14
2 + (3 * 4)  ; equals 14 (explicit grouping)
```

#### 3.2 Function Calls
```
print "hello"           ; function with one argument
add 2 3                 ; function with two arguments
divide -safe 10 0       ; function with refinement
divide 10 0 --safe      ; refinements can be anywhere
example --arg 10        ; function with valued refinement
```


#### 3.3 Type system

Even though Viro is a dynamic language it's values have concrete types. 

##### 3.3.1 Basic types
Basic Viro types are:

- `string!`
- `block!` 
- `fn!` - represents a function
- `object!` - for values created with `make object! []`
- `number!` - represents both integer and floating point number
- `bool!` - represents true/false values
- `word!` - represents a word within a block (functions, operators, etc...)
- `set-word!` - represents the set word syntax in block: `x:`
- `get-word!` - represents the get word syntax in block: `:x`
- `lit-word!` - represents the literal word in block `'x` 
- `none!` - special type to represent the `none` value

##### 3.3.2 Special types

- `native!` - represents natively defined function
- `action!` - represents a polymorphic function (can behave differently for different types) 
- `type!` - represents a type for... a type (i.e. value `string!` is of `type!` value)

##### 3.3.3 User-defined types

User can define their own type using `define-type` function:

```viro
define-type my-type! [
    kind: string!
    hello: fn [self] [print ["Hello " self]]
]
```

Which can then be instantiated with `make`:

```
my-val: make my-type! "world!"
define-action hello --args [value]
hello my-val ; prints "Hello world!"
```

## Part II: Implementation guideline

### 1. Value representation in Lua

Viro values are represented by Lua table with the first element being it's value:

Examples:
- Number `{ 1 }`
- String `{ "hello" }`
- Empty block  `{ {} }`
- Block of numbers `{ {{1}, {2}, {3}} }`
- Object `{ {x=10, y=20} }`
- Boolean values `{ true }`, `{ false }`
- Word `{ "name" }`

Since in that representation the words and strings look identical, each Viro value must have the prototype table set through it's metatable:

```lua
local word_type = {
    type = types.word,
    kind = types.word,
    -- ... other type-specific code
}

function types.make_word(name)
    local value = { name }
    setmetatable(value, { __index = word_type })
    return value
end
```

The prototype must set the `type` and `kind` fields. They specify the concrete type as well as kind that value represents respectively. It'll also provide implementations for the `action!`s for that type.

The difference between `type` and `kind` is that `type` defines the logical type of the value while `kind` is bound to one of the Viro's basic type and specifies what the value really is.

For better understanding, consider this value: `{ "/home/user/notes.txt", type = "path!", kind = "string!" }`. This means that the value logically represents the `path!` but really is just a `string!` and can also be used as a string.

### 2. Type system

Since the type definitions should be accessible and modifiable from Viro language the typesystem itself must be defined using Viro values. There should be an `object!` for which every key is a type name and every value is also an `object!` that describes the type. Minimal type description must contain the `type` (type name) and `kind` (base type name).

Written in Viro it would be like this:

```viro
types: make object! [
    object!: make object! [type: kind: "object!" ]
    string!: make object! [type: kind: "string!" ]
    -- ... other types
]
```

---

This specification provides a comprehensive foundation for the Viro programming language, focusing on its REBOL-inspired syntax and homoiconic design principles.