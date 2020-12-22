#!/usr/bin/env nix-shell
#!nix-shell -p ruby curl -i ruby
require 'erb'
require 'fileutils'
require 'json'
require 'net/http'

def fetch_json(url)
  puts "fetching #{url}"
  uri = URI(url)
  Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
    http.request_get(uri.path, {"Content-Type" => "application/json"}) do |response|
      response.read_body do |str|
        return JSON.parse(str)
      end
    end
  end
end

def download(url, path)
  system("curl", "-fL", "-o", path, url)
end

def render_readme(eval_id, release_id)
  b = binding
  ERB.new(File.read('README.md.erb')).result b
end

def rewrite(path, &block)
  body = File.read(path)
  new_body = yield body
  File.write(path, new_body)
end

def main(eval_id)
  if eval_id == nil then
    puts "ERROR: eval_id argument missing"
    exit 1
  end

  FileUtils.rm_rf "dist"
  FileUtils.mkdir_p "dist"

  release_id = nil

  # Fetch information from Hydra
  res = fetch_json("https://hydra.nixos.org/eval/#{eval_id}")
  res["builds"].each do |build_id|
    data = fetch_json("https://hydra.nixos.org/build/#{build_id}")

    case data["job"]
    when "build.x86_64-linux"
      # Get the release ID
      release_id = data["nixname"]
      puts "release ID: #{release_id}"
    when "installerScript"
      puts "download installerScript"
      filename = data["buildproducts"]["1"]["name"]
      download("https://hydra.nixos.org/build/#{build_id}/download/1/#{filename}", "dist/#{filename}")
    when "binaryTarball.aarch64-linux"
      puts "download binaryTarball.aarch64-linux"
      filename = data["buildproducts"]["1"]["name"]
      download("https://hydra.nixos.org/build/#{build_id}/download/1/#{filename}", "dist/#{filename}")
    when "binaryTarball.i686-linux"
      puts "download binaryTarball.i686-linux"
      filename = data["buildproducts"]["1"]["name"]
      download("https://hydra.nixos.org/build/#{build_id}/download/1/#{filename}", "dist/#{filename}")
    when "binaryTarball.x86_64-darwin"
      puts "download binaryTarball.x86_64-darwin"
      filename = data["buildproducts"]["1"]["name"]
      download("https://hydra.nixos.org/build/#{build_id}/download/1/#{filename}", "dist/#{filename}")
    when "binaryTarball.x86_64-linux"
      puts "download binaryTarball.x86_64-linux"
      filename = data["buildproducts"]["1"]["name"]
      download("https://hydra.nixos.org/build/#{build_id}/download/1/#{filename}", "dist/#{filename}")
    end

  end

  # Rewrite the installer
  rewrite("dist/install") do |body|
    body.gsub(
      'url=https://releases.nixos.org/nix/',
      'url=https://github.com/numtide/nix-flakes-installer/releases/download/'
    )
  end

  # Update the README file
  readme = render_readme(eval_id, release_id)
  File.write("README.md", readme)
end

main(ARGV[0])
