# Nix Unstable Installer

This project is a companion project to
[NixOS/nix](https://github.com/NixOS/nix). It takes the latest successful
builds of the project, and makes them available as GitHub Releases on this
project.

It's mainly useful if you want to test changes in the Nix project before it
becomes available in an official release. Or if you like living on the edge.

## Usage

Pick the release that you want to use. Each release has usage instructions
attached to it:
<https://github.com/numtide/nix-unstable-installer/releases/latest>

## How it works

Every day, a GitHub Action is fired, that does a few things:

* find the last successful build in [Hydra](https://hydra.nixos.org/jobset/nix/master)
* if there is already a git tag for that build, abort
* pull all the build artefacts
* update the URL in the installer script to point to this repo
* render the RELEASE.md.erb file
* publish all of that as a github release.

## Contributing

Contributions and discussions are welcome. Please make sure to send a WIP PR
or issue before doing large refactors, so your work doesn't get wasted (in
case of disagreement).

A big thanks to [@lilyinstarlight](https://github.com/lilyinstarlight) who
took this project from its hacky state to a something well finished.

## License

This project is copyright Numtide and contributors, and licensed under the
[MIT](LICENSE).
