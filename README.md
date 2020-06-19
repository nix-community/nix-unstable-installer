# Nix Flakes installer

This is a temporary place to host Nix Flakes releases, until the NixOS
project publishes official releases.

## Latest release

* Release: `nix-2.4pre20200618_377345e`
* Hydra eval: https://hydra.nixos.org/eval/1594477

## Usage with GitHub Actions

```
name: "Test"
on:
  pull_request:
  push:
jobs:
  tests:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: cachix/install-nix-action@v10
      with:
        nix_path: nixpkgs=channel:nixos-unstable
        install_url:
        https://github.com/numtide/nix-flakes-installer/releases/download/nix-2.4pre20200618_377345e/install
    - run: nix-build
```
