# Nix unstable installer

This project is about making Nix unstable release available to the general
public. It allows to test and use preview features like Flakes and provide
early feedback.

All it does is copy the release tarballs from Hydra and tweak the install
script so that it fetches them from GitHub instead.

## Latest release

* Release: `nix-2.6.0pre20211223_af553b2`
* Hydra eval: https://hydra.nixos.org/eval/1733072

## Usage

### Systems

```sh
sh <(curl -L https://github.com/numtide/nix-unstable-installer/releases/download/nix-2.6.0pre20211223_af553b2/install)
```

### GitHub Actions

Here is an example using Flakes:

```yaml
name: "Test"
on:
  pull_request:
  push:
jobs:
  tests:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: cachix/install-nix-action@v16
      with:
        install_url: https://github.com/numtide/nix-unstable-installer/releases/download/nix-2.6.0pre20211223_af553b2/install
    # Run the general flake checks
    - run: nix flake check
    # Verify that the main program builds
    - run: nix shell -c echo OK
```

## Current release process

* Run `./update.rb [eval_id]` (uses latest successful if no eval ID given)
* Tag with the release name
* Push to GitHub
* Create a new GitHub release and attach all files in the ./dist folder
