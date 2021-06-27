## `ppx_static` - Moving Computations out of Abstractions

### Synopsis

This is a simple syntax extension to lift the computation of a value out of
any surrounding abstractions.  This allows expressing anonymous constants
close to where they are used, without the penalty of recomputing them on
each function invocation or module application.  A secondary use is to add
state deep within a function, which persists across invocations.

### Examples

```ocaml
module Geometry = struct
  let to_degrees x = x *. [%static 360.0 /. (8.0 *. atan 1.0)]
end
```
is translated to
```ocaml
let __ppx_static_1234 = 360.0 /. (8.0 *. atan 1.0) in

module Geometry = struct
  let to_degrees x = x *. __ppx_static_1234
end
```

A typical use case, which motivated this ppx, is to compile regular
expressions during module initialization, while expressing them at the point
they are used:
```ocaml
let rec unwrap s =
  (match Re.exec_opt [%static Re.Pcre.regexp {|^\((.*)\)$|}] s with
   | Some g -> `Paren (unwrap (Re.Group.get g 1))
   | None ->
      (match Re.exec_opt [%static Re.Pcre.regexp {|^\$\{([^{}]+)\}$|}] s with
       | Some g -> `Variable (Re.Group.get g 1)
       | None -> `Bare s))
```

### Limitations

No binding from the surrounding scope is in scope for static expressions.
This limitation could be lifted for bindings which are determined during
module initialization, though, if needed, it may be better to introduce
`open%static`, `let%static`, etc. to make bindings available for the static
scope.
