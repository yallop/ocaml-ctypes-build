(*
 * Copyright (c) 2016 Jeremy Yallop.
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

type configuration = {
  name: string;
  errno: Cstubs.errno_policy;
  concurrency: Cstubs.concurrency_policy;
  headers: string;
  bindings: (module Cstubs.BINDINGS)
}

val main : configuration list -> unit
