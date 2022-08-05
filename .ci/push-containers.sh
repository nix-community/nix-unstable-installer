#!/usr/bin/env bash
set -e

[ -n "$NIX_RELEASE" ] || (echo 'NIX_RELEASE empty or undefined' >&2; exit 1)

image_tags=()

for url in $(curl -sfL "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/releases/tags/$NIX_RELEASE" |
    jq -r '(.assets[] | select(.name | test("-container\\.tar\\.gz$"; "s"))).browser_download_url'); do
  echo "downloading $url"
  image_name="$(curl -sfL "$url" | docker load --quiet | sed -e 's/^Loaded image: //')"

  image_filename="${url##*/}"
  arch_release="${image_filename%-container.tar.gz}"
  arch_name="ghcr.io/$GITHUB_REPOSITORY/nix:${arch_release#nix-}"

  docker image tag "$image_name" "$arch_name"
  docker image rm "$image_name"

  image_tags+=("$arch_name")
  echo "image tag: ${image_tags[-1]}"

  docker image push "$arch_name"
done

docker manifest create "ghcr.io/$GITHUB_REPOSITORY/nix:${NIX_RELEASE#nix-}" "${image_tags[@]}"
docker manifest push "ghcr.io/$GITHUB_REPOSITORY/nix:${NIX_RELEASE#nix-}"

docker manifest create "ghcr.io/$GITHUB_REPOSITORY/nix:latest" "${image_tags[@]}"
docker manifest push "ghcr.io/$GITHUB_REPOSITORY/nix:latest"
