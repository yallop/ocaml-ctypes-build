(*
 * Copyright (c) 2016 David Sheets, Jeremy Yallop
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

open Ocamlbuild_plugin
open Ocamlbuild_pack

let sprintf = Printf.sprintf

let rules ~prefix ?(bindings_dir="unix") ?(os="unix")
  ?ctypes_libdir ?lwt_libdir ~ocaml_libdir () =
  begin
    rule "cstubs: lib_gen/x_types_detect.c -> x_types_detect"
      ~prods:["lib_gen/%_types_detect"]
      ~deps:["lib_gen/%_types_detect.c"]
      (fun env build ->
         Cmd (S([A"cc"] @
                (match ctypes_libdir with None -> [] | Some d -> [A("-I"); A d]) @
                [A("-I"); A ocaml_libdir;
                 A"-o";
                 A(env "lib_gen/%_types_detect");
                 A(env "lib_gen/%_types_detect.c")]);
             ));

    rule "cstubs: lib_gen/x_types_detect -> x_types_detected.ml"
      ~prods:[bindings_dir ^"/%_types_detected.ml"]
      ~deps:["lib_gen/%_types_detect"]
      (fun env build ->
         Cmd (S[A(env "lib_gen/%_types_detect");
                Sh">";
                A(env (bindings_dir ^"/%_types_detected.ml"));
               ]));

    rule "cstubs: lib_gen/x_types.ml -> x_types_detect.c"
      ~prods:["lib_gen/%_types_detect.c"]
      ~deps: ["lib_gen/%_typegen.byte"]
      (fun env build ->
         Cmd (A(env "lib_gen/%_typegen.byte")));

    copy_rule "cstubs: lib_gen/x_types.ml -> x_types.ml"
      "lib_gen/%_types.ml" (bindings_dir ^"/%_types.ml");

    rule "cstubs: x_bindings.ml -> x_stubs.c, x_generated.ml"
      ~prods:[bindings_dir ^"/%_stubs.c";
              bindings_dir ^"/%_generated.ml"]
      ~deps: ["lib_gen/%_bindgen.byte"]
      (fun env build ->
        Cmd (S[A(env "lib_gen/%_bindgen.byte");
               A"--config";
               A bindings_dir;
               A"--c-file";
               A(env (bindings_dir ^"/%_stubs.c"));
                 A"--ml-file";
               A(env (bindings_dir ^"/%_generated.ml"))]));

    rule "cstubs: lwt/x_bindings.ml -> x_stubs.c, x_generated.ml"
      ~prods:["lwt/%_lwt_stubs.c"; "lwt/%_lwt_generated.ml"]
      ~deps: ["lib_gen/%_bindgen.byte"]
      (fun env build ->
        Cmd (S[A(env "lib_gen/%_bindgen.byte");
               A"--config";
               A"lwt";
               A"--c-file";
               A(env "lwt/%_lwt_stubs.c");
                 A"--ml-file";
               A(env "lwt/%_lwt_generated.ml")]));

    rule (prefix ^"_maps: maps/x -> lib/"^ prefix ^"_map_x.ml")
      ~prods:["lib/"^ prefix ^"_map_%.ml"]
      ~deps: ["src/"^ prefix ^"_srcgen.byte"; "maps/%"]
      (fun env build ->
         Cmd (S[A("src/"^ prefix ^"_srcgen.byte");
                Sh"<";
                A(env "maps/%");
                Sh">";
                A(env ("lib/"^ prefix ^"_map_%.ml"));
               ]));

    copy_rule "cstubs: lib_gen/x_bindings.ml -> x_bindings.ml"
      "lib_gen/%_bindings.ml" (bindings_dir ^"/%_bindings.ml");

    flag ["c"; "compile"] & S[A"-ccopt"; A"-I/usr/local/include"];
    flag ["c"; "ocamlmklib"] & A"-L/usr/local/lib";
    flag ["ocaml"; "link"; "native"; "program"] &
      S[A"-cclib"; A"-L/usr/local/lib"];

    (* Linking cstubs *)
    dep ["c"; "compile"; "use_"^ prefix ^"_util"]
      [bindings_dir ^"/"^ os ^"_"^ prefix ^"_util.o";
       bindings_dir ^"/"^ os ^"_"^ prefix ^"_util.h"];
    (match ctypes_libdir with
       None -> ()
     | Some ctypes_libdir ->
       flag ["c"; "compile"; "use_ctypes"] & S[A"-I"; A ctypes_libdir]);
    (match lwt_libdir with
       None -> ()
     | Some lwt_libdir ->
       flag ["c"; "compile"; "use_lwt"] & S[A"-I"; A lwt_libdir]);
    flag ["c"; "compile"; "debug"] & A"-g";

    (* Linking generated stubs *)
    dep ["ocaml"; "link"; "byte"; "library"; "use_"^ prefix ^"_stubs"]
      [bindings_dir ^"/dll"^ os ^"_"^ prefix ^"_stubs"-.-(!Options.ext_dll)];
    flag ["ocaml"; "link"; "byte"; "library"; "use_"^ prefix ^"_stubs"] &
      S[A"-dllib"; A("-l"^ os ^"_"^ prefix ^"_stubs")];

    dep ["ocaml"; "link"; "native"; "library"; "use_"^ prefix ^"_stubs"]
      [bindings_dir ^"/lib"^ os ^"_"^ prefix ^"_stubs"-.-(!Options.ext_lib)];
    flag ["ocaml"; "link"; "native"; "library"; "use_"^ prefix ^"_stubs"] &
      S[A"-cclib"; A("-l"^ os ^"_"^ prefix ^"_stubs")];

    flag ["ocaml"; "link"; "byte"; "library"; "use_"^ prefix ^"_lwt_stubs"] &
      S[A"-dllib"; A("-l"^ os ^"_"^ prefix ^"_lwt_stubs")];
    flag ["ocaml"; "link"; "native"; "library"; "use_"^ prefix ^"_lwt_stubs"] &
      S[A"-cclib"; A("-l"^ os ^"_"^ prefix ^"_lwt_stubs")];

    (* Linking tests *)
    flag ["ocaml"; "link"; "byte"; "program"; "use_"^ prefix ^"_stubs"] &
      S[A"-dllib"; A("-l"^ os ^"_"^ prefix ^"_stubs"); A"-I"; A(bindings_dir ^"/")];
    dep ["ocaml"; "link"; "native"; "program"; "use_"^ prefix ^"_stubs"]
      [bindings_dir ^"/lib"^ os ^"_"^ prefix ^"_stubs"-.-(!Options.ext_lib)];

    flag ["ocaml"; "link"; "byte"; "program"; "use_"^ prefix ^"_lwt_stubs"] &
      S[A"-dllib"; A("-l"^ os ^"_lwt_"^ prefix ^"_stubs")];
  end
