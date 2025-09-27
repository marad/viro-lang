<!--
Sync Impact Report:
Version change: Template → 1.0.0
New constitution creation - all principles defined from project analysis
Modified principles: All principles newly created based on Viro's architecture
Added sections: 
- I. Simplicity First (complexity management)
- II. Series Protocol Compliance (unified collections interface) 
- III. Type-Dispatched Actions (function/action distinction)
- IV. Test-Driven Development (RunTests framework)
- V. Homoiconic Consistency (code-as-data)
- Architecture Constraints (layered structure)
- Development Workflow (implementation patterns)
Templates requiring updates:
- ✅ plan-template.md (updated constitution check gates and version reference)
- ✅ tasks-template.md (updated for Viro-specific testing patterns and file structure)
- ✅ spec-template.md (already aligned with testable requirements principle)
- ✅ constitution.md (this file)
Follow-up TODOs: None - all placeholders filled, templates synchronized
-->

# Viro Language Constitution

## Core Principles

### I. Simplicity First
The language prioritizes doing simple things in simple ways. Complex solutions are only justified when simpler alternatives are demonstrably insufficient. Every feature must solve a real problem without introducing unnecessary complexity. The principle "limiting solution complexity to a necessary minimum" guides all design decisions.

### II. Series Protocol Compliance
All collection types (blocks, strings, files, network streams) MUST implement the unified series protocol with consistent navigation methods: `next`, `back`, `head`, `tail`, `skip`, `at` for navigation; `pick`, `copy`, `length?`, `empty?`, `head?`, `tail?` for queries. This enables learning once and applying everywhere.

### III. Type-Dispatched Actions (NON-NEGOTIABLE)
Functions are distinguished from actions. Actions automatically dispatch to type-specific implementations using the `dispatch_fn_on_type` pattern, enabling polymorphic operations. All new collection types MUST implement required action methods. Functions handle general operations, actions handle type-specific behavior.

### IV. Test-Driven Development
All features require tests written before implementation. Use the custom `RunTests` framework in `spec/init.lua`. Red-Green-Refactor cycle is strictly enforced. Integration tests must validate series protocol compliance for new types.

### V. Homoiconic Consistency
Code is data, data is code. Type system MUST correspond to syntactic representation. Types like `word!`, `set-word!`, `block!`, `paren!` reflect their syntax. This enables powerful metaprogramming while maintaining readability and consistency.

## Architecture Constraints

Viro follows a clear layered architecture that MUST be preserved:

- **Parser** (`viro/parser.lua`): LPEG-based AST generation only
- **Processor** (`viro/processor.lua`): Tree-walking evaluation with context management
- **Types** (`viro/types.lua`): Rich type system with series protocol and method dispatch
- **Environment** (`viro/env.lua`): Nested context management with Lua metatable inheritance
- **Default Context** (`viro/default_ctx.lua`): Built-in functions and actions only

No circular dependencies between layers. Context management uses Lua metatables for prototype inheritance. All types implement `mold` (serialization) and `form` (display) methods.

## Development Workflow

**Bootstrap Process**: REPL loads default context → executes `boot.vro` → enters interactive loop with `xpcall` error handling.

**Adding Functions**: Use `types.makeFn(function(ctx, ...), arg_count)` for standard functions. Use `dispatch_fn_on_type` pattern for actions.

**Type Implementation**: New collection types MUST implement series protocol methods. Derived types override base type behavior without creating new abstractions.

**File Organization**: Core in `viro/`, tests in `spec/`, bootstrap in `boot.vro`. Maintain separation between language implementation and user code.

## Governance

This constitution supersedes all other development practices. All pull requests and code reviews MUST verify compliance with these principles. Any violation requires documented justification and approval. 

Architecture changes that break layered design are prohibited without constitutional amendment. Series protocol changes require backward compatibility or major version increment.

Runtime development guidance is maintained in `.github/copilot-instructions.md` for implementation details not covered in this constitution.

**Version**: 1.0.0 | **Ratified**: 2025-09-27 | **Last Amended**: 2025-09-27