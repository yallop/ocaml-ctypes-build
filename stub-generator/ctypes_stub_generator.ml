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

let name { name } = name

let rec assoc n = function
    [] -> raise Not_found
  | { name } as c :: _ when name = n -> c
  | _ :: configs -> assoc n configs

let main configs =
  let config_names = List.map name configs in
  let configuration = ref (fun () -> failwith "--config must be specified")
  and ml_file = ref ""
  and c_file = ref "" in
  let argspec : (Arg.key * Arg.spec * Arg.doc) list = [
    "--ml-file", Arg.Set_string ml_file, "set the ML output file";
    "--c-file", Arg.Set_string c_file, "set the C output file";
    "--config", Arg.Symbol (config_names,
                            fun sym ->
                              configuration := fun () -> assoc sym configs),
    ("select the config (one of "^ String.concat ", " config_names^ ")")
  ]
  in
  let () = Arg.parse argspec failwith "" in
  if !ml_file = "" || !c_file = "" then
    failwith "Both --ml-file and --c-file arguments must be supplied";
  let {name; errno; concurrency; headers; bindings} = !configuration () in
  let prefix = name ^"_prefix_" in
  let stubs_oc = open_out !c_file in
  let fmt = Format.formatter_of_out_channel stubs_oc in
  Format.fprintf fmt "%s@." headers;
  Cstubs.write_c ~errno ~concurrency fmt ~prefix bindings;
  close_out stubs_oc;

  let generated_oc = open_out !ml_file in
  let fmt = Format.formatter_of_out_channel generated_oc in
  Cstubs.write_ml ~errno ~concurrency fmt ~prefix bindings;
  close_out generated_oc
