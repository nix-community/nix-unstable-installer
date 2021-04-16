# Nix unstable installer

This project is about making Nix unstable release available to the general
public. It allows to test and use preview features like Flakes and provide
early feedback.

All it does is copy the release tarballs from Hydra and tweak the install
script so that it fetches them from GitHub instead.

## Latest release

* Release: `nix-2.4pre20210415_76980a1`
* Hydra eval: https://hydra.nixos.org/eval/1663087

## Usage

### Systems

```sh
sh <(curl -L https://github.com/numtide/nix-flakes-installer/releases/download/nix-2.4pre20210415_76980a1/install)
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
      with:
        # Nix Flakes doesn't work on shallow clones
        fetch-depth: 0
    - uses: cachix/install-nix-action@v11
      with:
        install_url: https://github.com/numtide/nix-flakes-installer/releases/download/nix-2.4pre20210415_76980a1/install
        # Configure Nix to enable flakes
        extra_nix_config: |
          experimental-features = nix-command flakes
    # Run the general flake checks
    - run: nix flake check
    # Verify that the main program builds
    - run: nix shell -c echo OK
```

## Current release process

* Go to https://hydra.nixos.org/jobset/nix/master
* Find the latest eval ID
* Run `./update.rb <eval ID>`
* Tag with the release ID.
* Push to GitHub
* Create a new GitHub release and attach all those files in the ./dist folder.
