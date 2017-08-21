(* Copyright (C) 2017  Petter A. Urkedal <paurkedal@gmail.com>
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

open Migrate_parsetree
open Ast_404
let ocaml_version = Versions.ocaml_404

open Ast_mapper
open Asttypes
open Parsetree
open Longident

let null_expr = {
  pexp_desc = Pexp_unreachable;
  pexp_loc = Location.none;
  pexp_attributes = [];
}

let error ~loc msg = raise (Location.Error (Location.error ~loc msg))

let dyn_istop = ref true
let dyn_bindings = ref []
let clear_bindings () = dyn_bindings := []
let add_binding binding = dyn_bindings := binding :: !dyn_bindings
let get_bindings () = !dyn_bindings

let name_for e =
  Printf.sprintf "_x%d" e.pexp_loc.Location.loc_start.Lexing.pos_cnum

let rewrite_expr mapper maybe_extension =
  (match maybe_extension.pexp_desc with
   | Pexp_extension ({txt = "static"; loc},
                     PStr [{pstr_desc = Pstr_eval (pexp, []); _}]) ->
      (match pexp.pexp_desc with
       | Pexp_let _ ->
          error ~loc "The semantics of let%static is left undecided for now."
       | _ ->
          (* [%static ...] *)
          let var = name_for pexp in
          let binding = {
            pvb_pat = {ppat_desc = Ppat_var {txt = var; loc};
                       ppat_loc = loc; ppat_attributes = []};
            pvb_expr = pexp;
            pvb_attributes = [];
            pvb_loc = loc;
          } in
          add_binding binding;
          default_mapper.expr mapper
            {pexp_desc = Pexp_ident {txt = Lident var; loc};
             pexp_loc = loc; pexp_attributes = []})
   | _ ->
      default_mapper.expr mapper maybe_extension)

let rewrite_value_binding mapper pvb =
  let istop = !dyn_istop in
  dyn_istop := false;
  let pvb = default_mapper.value_binding mapper pvb in
  dyn_istop := istop;
  if not istop then pvb else
  (match get_bindings () with
   | [] -> pvb
   | bindings ->
      clear_bindings ();
      let e_let = {pexp_desc = Pexp_let (Nonrecursive, bindings, pvb.pvb_expr);
                   pexp_loc = pvb.pvb_loc; pexp_attributes = []} in
      {pvb with pvb_expr = e_let})

let static_mapper _config _cookies = {
  default_mapper with
  value_binding = rewrite_value_binding;
  expr = rewrite_expr;
}

let () = Driver.register ~name:"ppx_static" ocaml_version static_mapper
