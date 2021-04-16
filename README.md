# Nix Flakes installer

This is a temporary place to host Nix Flakes releases, until the NixOS project
publishes official releases.

NOTE: Nix went backwards in the pre-releases from 3.0 to 2.4.

## Latest release

* Release: `nix-2.4pre20210126_f15f0b8`
* Hydra eval: https://hydra.nixos.org/eval/1644847

## Usage

### Systems

```sh
sh <(curl -L https://github.com/numtide/nix-flakes-installer/releases/download/nix-2.4pre20210126_f15f0b8/install)
```

### GitHub Actions

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
    - uses: cachix/install-nix-action@v11
      with:
        install_url: https://github.com/numtide/nix-flakes-installer/releases/download/nix-2.4pre20210126_f15f0b8/install
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
