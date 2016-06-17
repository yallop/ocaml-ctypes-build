(*
 * Copyright (c) 2016 Jeremy Yallop
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

val rules : prefix:string ->
           ?bindings_dir:string ->
           ?os:string ->
           ?ctypes_libdir:string ->
           ?lwt_libdir:string ->
            ocaml_libdir:string ->
            unit ->
            unit
