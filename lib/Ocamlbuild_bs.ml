open Ocamlbuild_plugin

let bsfind = A"bsfind"
let bsc = A"ocamlc"
let bsdep = A"ocamldep"

let ocaml_include_flags path =
  let ocaml_add_include_flag x acc =
    if x = Pathname.current_dir_name then acc else A"-I" :: A x :: acc
  in
  S (List.fold_right ocaml_add_include_flag (Pathname.include_dirs_of (Pathname.dirname path)) [])

let read_dependencies ml =
  let depends = ml -.- "bsdepends" in
  let dir = Pathname.dirname depends in
  let module_names = match string_list_of_file depends with
    | _::_::deps -> deps
    | _::[] -> [] (* colon : *)
    | [] -> [] (* module name *)
  in
  let module_to_pathname module_name =
    let dep_name = module_name ^ ".js" in
    let dep_path = Pathname.mk dep_name in
    Pathname.concat dir dep_path
  in
  List.map module_to_pathname module_names

let build_dependencies build ml =
  let depends = List.map (fun p -> [p]) (read_dependencies ml) in
  List.map Outcome.good (build depends)

let init () =

  let extract_dependencies input env _build =
    let ml = env input in
    let tags = (tags_of_pathname ml) ++ "ocamldep" ++ "ocaml" in
    Cmd(S[
        bsfind;
        bsdep;
        A"-one-line";
        A"-modules";
        T(tags);
        ocaml_include_flags ml;
        P(ml);
        Sh(">"); P(env (input ^ ".bsdepends"))
      ])
  in

  let build_js env build =
    let ml = env "%.ml" in
    let _ = build_dependencies build ml in
    let tags = (tags_of_pathname ml) ++ "byte" ++ "compile" ++ "ocaml" in
    Cmd(S[
        bsfind;
        bsc;
        T(tags);
        ocaml_include_flags ml;
        P(env "%.ml")
      ])
  in

  rule "bs dependencies ml"
    ~prods:["%.ml.bsdepends"]
    ~deps:["%.ml"]
    (extract_dependencies "%.ml");

  rule "bs dependencies mli"
    ~prods:["%.mli.bsdepends"]
    ~deps:["%.mli"]
    (extract_dependencies "%.mli");

  rule "bs: ml -> js"
    ~prods:["%.js"]
    ~deps:["%.ml"; "%.ml.bsdepends"]
    build_js

let dispatcher = function
  | After_rules -> init ()
  | _ -> ()
