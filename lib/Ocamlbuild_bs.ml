open Ocamlbuild_plugin

let bs = A"bsc.exe"
let bsdep = A"bsdep.exe"

let ocaml_add_include_flag x acc =
  if x = Pathname.current_dir_name then acc else A"-I" :: A x :: acc

let ocaml_include_flags path =
  S (List.fold_right ocaml_add_include_flag (Pathname.include_dirs_of (Pathname.dirname path)) [])

let read_dependencies ml =
  let depends = ml -.- "depends" in
  let dir = Pathname.dirname depends in
  let module_names = match string_list_of_file depends with
    | [] -> []
    | _::deps -> deps
  in
  List.map
    (fun module_name ->
       let dep_name = module_name ^ ".js" in
       let dep_path = Pathname.mk dep_name in
       Pathname.concat dir dep_path) module_names

let build_dependencies build ml =
  let depends = List.map (fun p -> [p]) (read_dependencies ml) in
  List.map Outcome.good (build depends)

let init () =

  rule "bs dependencies ml"
    ~prods:["%.ml.depends"]
    ~deps:["%.ml"]
    begin fun env _build ->
      Cmd(S[bsdep; A"-one-line"; P(env "%.ml"); P(env "%.ml.depends")])
    end;

  rule "bs dependencies mli"
    ~prods:["%.mli.depends"]
    ~deps:["%.mli"]
    begin fun env _build ->
      Cmd(S[bsdep; A"-one-line"; P(env "%.mli"); P(env "%.mli.depends")])
    end;

  rule "bs: ml -> js"
    ~prods:["%.js"]
    ~deps:["%.ml"; "%.ml.depends"]
    begin fun env build ->
      let ml = env "%.ml" in
      let _ = build_dependencies build ml in
      Cmd(S[
          bs;
          ocaml_include_flags ml;
          A"-bs-files";
          P(env "%.ml")])
    end

let dispatcher = function
  | After_rules -> init ()
  | _ -> ()
