#!/usr/bin/env nix-shell
#!nix-shell -p ruby -i ruby
require 'erb'
require 'fileutils'
require 'json'
require 'net/http'
require 'pp'

def fetch_json(url)
  uri = URI(url)
  Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
    http.request_get(uri.path, {"Content-Type" => "application/json"}) do |response|
      response.read_body do |str|
        return JSON.parse(str)
      end
    end
  end
end

def download(url, path, &block)
  uri = URI(url)
  Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
    http.request_get(uri.path, {"Content-Type" => "application/json"}) do |response|
      response.read_body do |str|
        if block_given?
          str = block.call(str)
        end
        File.write(path, str)
      end
    end
  end
end

def render_readme(eval_id, release_id)
  b = binding
  ERB.new(File.read('README.md.erb')).result b
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
      if release_id == nil then
        raise "oops"
      end
      puts "download installerScript"
      filename = data["buildproducts"]["1"]["name"]
      download("https://hydra.nixos.org/build/#{build_id}/download/1/#{filename}", "dist/#{filename}") do |body|
        body.gsub(
          'url="https://releases.nixos.org/nix/',
          'url="https://github.com/numtide/nix-flakes-installer/releases/download/'
        )
      end
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

  # Update the README file
  readme = render_readme(eval_id, release_id)
  File.write("README.md", readme)
end

main(ARGV[0])
