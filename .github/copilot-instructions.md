# Viro Language Copilot Instructions

Viro is a REBOL-inspired programming language implemented in Lua, focused on expressive data processing with unified operations across different data types.

## Architecture Overview

### Core Components
- **Parser** (`viro/parser.lua`): LPEG-based parser generating AST nodes
- **Processor** (`viro/processor.lua`): Tree-walking evaluator with context-based execution
- **Types** (`viro/types.lua`): Rich type system with series protocol and method dispatch
- **Environment** (`viro/env.lua`): Nested context management with prototype inheritance
- **Default Context** (`viro/default_ctx.lua`): Built-in functions and actions

### Type System Philosophy
Viro implements a **series protocol** where collections (blocks, strings) share common navigation methods:
- `next`, `back`, `head`, `tail` for navigation
- `pick`, `at`, `skip` for access
- `length?`, `empty?`, `head?`, `tail?` for queries

Types have both `type` (concrete) and `kind` (category) fields. All types implement `mold` (serialization) and `form` (display) methods.

### Function vs Action Distinction
- **Functions**: Standard operations (e.g., `do`, `if`, `print`)
- **Actions**: Type-dispatched operations using `dispatch_fn_on_type` pattern (e.g., `next`, `copy`, `mold`)

Actions automatically dispatch to type-specific implementations, enabling polymorphic operations across different data types.

## Development Patterns

### Adding New Functions
```lua
-- Simple function
default.my_func = types.makeFn(function(ctx, arg1, arg2)
    -- implementation
end, 2) -- arg_count

-- Type-dispatched action
default.my_action = dispatch_fn_on_type { 
    method_name = "my_method", 
    arg_count = 1,
    wrapper_fn = types.makeNumber -- optional result transformation
}
```

### Type Implementation
New types must implement series protocol methods if they're collections:
```lua
function my_type.length(self) end
function my_type.copy(self, from_index) end
function my_type.get_at(self, index) end
-- Plus mold/form for display
```

### Context Management
Contexts use Lua metatable inheritance. Functions receive `ctx` as first parameter for lexical scoping and variable access.

## Build & Test Workflow

### Development Commands
```bash
make run          # Start REPL
make test         # Run all specs
make shell        # Enter Nix development shell
./lua viro/repl.lua  # Direct REPL access
```

### Testing Pattern
Tests use custom `RunTests` framework in `spec/init.lua`:
```lua
RunTests({
    ["test name"] = function()
        local result = parser.parse("code")
        assert.are.same(result.type, types.expected)
    end,
})
```

### Bootstrap Process
1. REPL loads default context with built-in functions
2. Executes `boot.vro` for initial environment setup
3. Enters interactive loop with `xpcall` error handling

## Key Files for Extension
- `viro/default_ctx.lua`: Add new built-in functions
- `viro/types.lua`: Implement new data types
- `viro/parser.lua`: Extend syntax parsing
- `spec/`: Add tests using `RunTests` pattern
- `boot.vro`: Modify initial environment

## Language Conventions
- Words can contain `?`, `-`, `!`, etc. (REBOL-style naming)
- Set-words end with `:` for assignment
- Blocks use `[]`, parentheses for grouping
- Files prefixed with `%` (e.g., `%boot.vro`)
- Type predicates end with `?` (e.g., `empty?`, `head?`)

## Current Limitations
- Basic arithmetic operators implemented
- No infix operator support yet
- Limited control flow (if/either/forever)
- File I/O through `read`/`save` functions
- Error handling via Lua's `xpcall`

## Terminal Commands
The development environment uses the nix flake so before running the first terminal command 
you should run the `nix develop` first to setup the environment.