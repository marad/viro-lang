TODO:
- function argument specifications - if the argument starts with `'` then it will not be evaluated before use it might also be used for type restrictions
- reading additional optional parameters/refinements




List of native functions to implement for each data type:

- also a b - returns the first value but also evaluates the second


https://www.rebol.com/r3/docs/functions.html


The https://www.rebol.com/r3/docs/concepts.html page contains number of "Functions" subpages 
that outline the core functions defined in the language.




Block Only
- all BLOCK - evaluates and returns the last value if all are thruthy, else none
- any BLOCK - evaluates and returns the first trutry value; if there is none - returns none
- apply FUNC BLOCK - apply function to reduced block of arguments
- attempt



Series functions:

https://www.rebol.com/r3/docs/concepts/series-functions.html


Creation
- make
- copy

Navigation
- next
- back
- head
- tail
- skip
- at

Extraction
- pick
- copy/part
- first
- second
- third
- fourth
- fifth
- last

Modification
- insert
- append
- remove
- clear
- change
- poke

Ordering
- sort
- reverse

Set operations
- unique
- intersect
- union
- exclude
- difference