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

let f x =
  let g y = [%static Random.bits () mod 1000] + x - y in
  let g0 = g 0 in
  assert (g0 < 1000);
  for y = 0 to 100 do assert (g y = g0 - y) done

let fresh pfx =
  let counter = [%static ref 0] in
  incr counter;
  pfx ^ string_of_int !counter

let () =
  for x = 1 to 100 do f x done;
  assert (fresh "x" = "x1");
  assert (fresh "x" = "x2")
