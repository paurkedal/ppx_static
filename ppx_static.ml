(* Copyright (C) 2017--2021  Petter A. Urkedal <paurkedal@gmail.com>
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version, with the OCaml static compilation exception.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *)

open Ppxlib

let fresh_name_for e =
  Printf.sprintf "__ppx_static_%d" e.pexp_loc.Location.loc_start.Lexing.pos_cnum

let static_bindings_of = object
  inherit [value_binding list] Ast_traverse.fold_map as super

  method! expression pexp acc =
    let loc = pexp.pexp_loc in
    (match pexp.pexp_desc with
     | Pexp_extension
         ({txt = "static"; _},
          PStr [{pstr_desc = Pstr_eval (expr, _); pstr_loc = _}]) ->
        let open Ast_builder.Default in
        let name = fresh_name_for expr in
        let expr, acc = super#expression expr acc in
        let pat = ppat_var ~loc (Located.mk ~loc name) in
        let binding = value_binding ~loc ~pat ~expr in
        let expr' = pexp_ident ~loc (Located.lident ~loc name) in
        (expr', binding :: acc)
     | _ ->
        let pexp, acc = super#expression pexp acc in
        (pexp, acc))
end

let impl str =
  let str, rev_bindings = static_bindings_of#structure str [] in
  let open Ast_builder.Default in
  let mk_let b = pstr_value ~loc:Location.none Nonrecursive [b] in
  List.rev_map mk_let rev_bindings @ str

let () = Driver.register_transformation ~impl "ppx_static"
