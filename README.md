# YSL-C Rewrite
This is a rewrite of the YSL-C compiler

## Why?
The old YSL-C was bad because it generated platform dependent assembly, which makes it very hard to port it to other platforms

The solution is YSL-M, it's very easy to implement and it has just enough features to use as a compile target

# Build
```
dub build
```
