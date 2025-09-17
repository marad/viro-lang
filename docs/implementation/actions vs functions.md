

Viro obviously has functions, as you would expect from a programming language. But there are also `action!`s. What is the difference? 
They both sure look very similar! Take a look at this:

```viro
do [print "Hello"] ; the 'do' here is a function
next [1 2 3] ; 'next' is an action
```

Well for the user - there is no difference. Both work as operations with arguments.

The distinction becomes important when you want to define a new type. Actions, you see, are dispatched on the type the value represents.
So calling `next` with a `string!` or `block!` do the same semantically, but the implementation is quite different.

Actions look at the type of the first argument and find the action implementation for given type in it's context. If action is not
defined for given type, it will result in an error.