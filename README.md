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
<https://github.com/nix-community/nix-unstable-installer/releases/latest>

## How it works

Every day, a GitHub Action is fired, that does a few things:

* Find the last successful build of jobset
[`nix:master`](https://hydra.nixos.org/jobset/nix/master) in Hydra
* If there is already a git tag in this repo for that build, abort
* Pull all of the build artefacts
* Update the URL in the installer script to point to this repo
* Render the RELEASE.md.erb file
* Create a git tag in this repo for the build
* Publish the artefacts and rendered release notes as a GitHub pre-release
* Test the install script on the pre-release on both Linux and macOS
* Publish the container images to GitHub Container Registry on this repo
* Mark the release as a full release

## Contributing

Contributions and discussions are welcome. Please make sure to send a WIP PR
or issue before doing large refactors, so your work doesn't get wasted (in
case of disagreement).

A big thanks to [@lilyinstarlight](https://github.com/lilyinstarlight) who
took this project from its hacky state to something well finished.

## License

This project is copyright Numtide and contributors, and licensed under the
[MIT](LICENSE).
