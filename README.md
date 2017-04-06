# ocamlbuild plugin for BuckleScript

## Installation

```sh
esy add andreypopp/ocamlbuild-bs
```

## Usage

Add these lines to `myocamlbuild.ml`:

```ocaml
let () =
  Ocamlbuild_plugin.dispatch Ocamlbuild_bs.dispatcher
```

and invoke `ocamlbuild` like this:

```sh
ocamlbuild -plugin-tag "package(ocamlbuild-bs)" ...
```
