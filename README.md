# Nix unstable installer

This project is about making Nix unstable release available to the general
public. It allows to test and use preview features like Flakes and provide
early feedback.

All it does is copy the release tarballs from Hydra and tweak the install
script so that it fetches them from GitHub instead.

## Latest release

* Release: `nix-2.10.0pre20220808_73fde9e`
* Hydra eval: <https://hydra.nixos.org/eval/1775204>

## Usage

### Systems

```sh
sh <(curl -L https://github.com/numtide/nix-unstable-installer/releases/download/nix-2.10.0pre20220808_73fde9e/install)
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
    - uses: actions/checkout@v3
    - uses: cachix/install-nix-action@v17
      with:
        install_url: https://github.com/numtide/nix-unstable-installer/releases/download/nix-2.10.0pre20220808_73fde9e/install
    # Run the general flake checks
    - run: nix flake check
    # Verify that the main program builds
    - run: nix shell -c echo OK
```

### Docker

```sh
docker run --rm -ti ghcr.io/numtide/nix-unstable-installer/nix:2.10.0pre20220808_73fde9e
```

## Current release process

* Run `./update.rb [eval_id]` (uses latest successful if no eval ID given)
* Commit and tag with the release name
* Push to GitHub
* Create a new GitHub release and attach all files in the ./dist folder
