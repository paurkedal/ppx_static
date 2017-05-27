## `ppx_static` - Moving Computations out of Abstractions

### Synopsis

This is a simple syntax extension to lift the computation of a value out of
any surrounding abstractions.  This allows expressing anonymous constants
close to where they are used, without the penalty of recomputing them on
each function invocation.  A secondary use is to add state deep within a
function, which persists across invocations.  In other words, this PPX is
syntactic sugar for
```ocaml
let f =
  let c1 = ... and ... and cM = ... in
  fun x1 .. xN -> ...
```

### Examples

```ocaml
let to_degrees x = x *. [%static 360.0 /. (8.0 *. atan 1.0)]
```
is translated to
```ocaml
let to_degrees =
  let _x123 = 360.0 /. (8.0 *. atan 1.0) in
  fun x -> x *. _x123
```
where `_x123` is some meant-to-be-hidden variable name.

A contrived example using regular expressions:
```ocaml
let rec unwrap s =
  (match Re.exec_opt [%static Re_pcre.regexp {|^\((.*)\)$|}] s with
   | Some g -> `Paren (unwrap (Re.Group.get g 1))
   | None ->
      (match Re.exec_opt [%static Re_pcre.regexp {|^\$\{([^{}]+)\}$|}] s with
       | Some g -> `Variable (Re.Group.get g 1)
       | None -> `Bare s))
```

### Limitations

- Local `open` or `include` statements are not in scope for [%static ...]
  expressions.
- Local variables are of course not in scope generally, though it would be
  possible to make bindings of the form `let x = [%static ...] in ...`
  available to successive static values.
- `[%static let ... = ...]` is currently disallowed, since we may want to
  interpret the equivalent `let%static x = ...` as `let x = [%static ...]`.
  But then maybe not; it may be better to keep it consistent.
