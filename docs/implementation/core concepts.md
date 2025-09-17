

Viro is all about processing data. 

The core concept is that we have a number of core functions that you learn once and then are able to use for working with data collections, files or network communication. The functions should do what you expect them to depending on the context.

For example if you want to read a file, does it always matter if the file is in the local file system or the network?

```viro
read %some/file.txt
read https://other.com/file.txt
```

Many times it really doesn't - you either have the contents, or you don't. The point is that doing simple things should also be simple. You should only reach for dedicated HTTP API when you specifically need it, not because there is no alternative.

It is NOT about unifying everything and removing dedicated APIs. It's about limiting the solution complexity to a necessary minimum.