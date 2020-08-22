# Nix Flakes installer

This is a temporary place to host Nix Flakes releases, until the NixOS
project publishes official releases.

## Latest release

* Release: `nix-3.0pre20200820_4d77513`
* Hydra eval: https://hydra.nixos.org/eval/1608130

## Usage

### Systems

```sh
sh <(curl -L https://github.com/numtide/nix-flakes-installer/releases/download/nix-3.0pre20200820_4d77513/install)
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
      with:
        # Nix Flakes doesn't work on shallow clones
        fetch-depth: 0
    - uses: cachix/install-nix-action@v10
      with:
        install_url: https://github.com/numtide/nix-flakes-installer/releases/download/nix-3.0pre20200820_4d77513/install
    # Configure Nix to enable flakes
    - run: echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
    # Run the general flake checks
    - run: nix flake check
    # Verify that the main program builds
    - run: nix shell -c echo OK
```

## Current release process

* Go to https://hydra.nixos.org/jobset/nix/master
* Pick the latest successful build
* Download the `installerScript` and the `binaryTarball.*`
* Update this README.md with the release ID.
* Tag with the release ID.
* Push to GitHub
* Edit the `install` script and replace `https://releases.nixos.org/nix` with `https://github.com/numtide/nix-flakes-installer/releases/download`
* Attach all those files to the tag and make a GitHub Release.
