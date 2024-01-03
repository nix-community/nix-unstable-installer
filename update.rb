#!/usr/bin/env nix-shell
#!nix-shell -p ruby curl -i ruby
require 'erb'
require 'fileutils'
require 'json'
require 'net/http'
require 'yaml'

def fetch_json(url, tries = 10)
  if tries <= 0
    raise "error fetching #{url}: too many retries/redirects"
  end

  puts "fetching #{url}"

  uri = URI(url)
  Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == "https") do |http|
    http.request_get(uri.path + (uri.query.nil? ? "" : "?" + uri.query), {"Accept" => "application/json"}) do |response|
      case response
      when Net::HTTPSuccess
        begin
          return JSON.parse(response.read_body)
        rescue JSON::JSONError
          puts "received invalid JSON"
          sleep 1
          return fetch_json(url, tries - 1)
        end
      when Net::HTTPRedirection
        puts "received HTTP redirect to #{response['location']}"
        return fetch_json(response["location"], tries - 1)
      else
        puts "received HTTP error: #{response.code} #{response.message}"
        sleep 1
        return fetch_json(url, tries - 1)
      end
    end
  end
end

def download(url, path)
  system("curl", "-sfL", "-o", path, url)
end

def render_release(eval_id, release_name, server_url, repository, install_nix_action_version)
  b = binding
  ERB.new(File.read("RELEASE.md.erb")).result b
end

def rewrite(path, &block)
  body = File.read(path)
  new_body = yield body
  File.write(path, new_body)
end

def get_eval(eval_id, skip_existing_tag = false)
  release_name = nil

  dist_jobs = [
    "binaryTarball.aarch64-darwin",
    "binaryTarball.aarch64-linux",
    "binaryTarball.i686-linux",
    "binaryTarball.x86_64-darwin",
    "binaryTarball.x86_64-linux",
    "buildStatic.aarch64-linux",
    "buildStatic.x86_64-linux",
    "dockerImage.aarch64-linux",
    "dockerImage.x86_64-linux",
    "installerScript",
  ]
  extra_prefixes = ["build.", "buildStatic.", "tests.", "installTests.", "installerTests."]
  exclude_jobs = ["tests.setuid.i686-linux"]

  downloads = []

  # Fetch information from Hydra
  res = fetch_json("https://hydra.nixos.org/eval/#{eval_id}")
  res["builds"].each do |build_id|
    data = fetch_json("https://hydra.nixos.org/build/#{build_id}")
    job = data["job"]

    if dist_jobs.none?(job) and extra_prefixes.none? { |prefix| job.start_with? prefix } or exclude_jobs.include?(job)
      next
    end

    if data["buildstatus"].nil? or data["buildstatus"] > 0
      puts "evaluation #{eval_id} has failed or queued jobs"
      return :failure
    end

    case job
    when "build.x86_64-linux"
      # Get the release name
      release_name = data["nixname"]
      puts "release name: #{release_name}"
    when *dist_jobs
      filename = data["buildproducts"]["1"]["name"]

      downloads.push([
        job,
        build_id,
        filename
      ])
    end
  end

  # Skip existing tags
  tag_exists = system("git", "show-ref", "--tags", release_name, "--quiet")
  if skip_existing_tag
    if tag_exists.nil?
      raise "git tag checking error"
    end

    if tag_exists
      puts "skipping existing release"
      return :skip
    end
  end

  # Download files
  downloads.each do |job, build_id, filename|
    puts "downloading #{job}"

    case job.split(".", 2).first
    when "buildStatic"
      dest = release_name + "-" + job.split(".", 2).last + "-static"
    when "dockerImage"
      dest = release_name + "-" + job.split(".", 2).last + "-container.tar.gz"
    else
      dest = filename
    end

    download("https://hydra.nixos.org/build/#{build_id}/download/1/#{filename}", "dist/#{dest}")
  end

  server_url = ENV.fetch('GITHUB_SERVER_URL', 'https://github.com')
  repository = ENV.fetch('GITHUB_REPOSITORY', 'nix-community/nix-unstable-installer')

  # Rewrite the installer
  rewrite("dist/install") do |body|
    body.gsub(
      "url=https://releases.nixos.org/nix/",
      "url=#{server_url}/#{repository}/releases/download/"
    )
  end

  # Get cachix/install-nix-action version for the RELEASE file
  begin
    install_nix_action_version = YAML.load_file(".github/workflows/release.yml")["jobs"]["update"]["steps"].find { |step| step.has_key? "uses" and step["uses"].start_with? "cachix/install-nix-action@" }["uses"].split("@", 2).last
  rescue Errno::ENOENT
    install_nix_action_version = "master"
  end

  # Generate the RELEASE file
  release_body = render_release(eval_id, release_name, server_url, repository, install_nix_action_version)
  File.write("dist/RELEASE.md", release_body)

  return release_name
end

def main(eval_id)
  FileUtils.rm_rf "dist"
  FileUtils.mkdir_p "dist"

  if eval_id == nil
    # Get latest evaluations from Hydra
    latest_url = "https://hydra.nixos.org/jobset/nix/master/evals"

    latest = fetch_json(latest_url)

    # Iterate over evaluations
    release_name = nil
    eval_idx = 0
    evals_checked = 0
    while release_name.nil?
      # Give up when too many evals have been tried
      if evals_checked > 60
        raise "error finding latest successful evaluation: too many evaluations checked"
      end

      # Implement Hydra pagination
      if eval_idx >= latest["evals"].length
        eval_idx = 0
        latest = fetch_json(latest_url + latest["next"])
        next
      end

      evals_checked += 1

      eval_id = latest["evals"][eval_idx]["id"]

      # Get evaluation details
      eval_result = get_eval(eval_id, skip_existing_tag = true)
      case eval_result
      when :failure
        eval_idx += 1
        next
      when :skip
        release_name = ""
        updated = false
      else
        release_name = eval_result
        updated = true
      end
    end

    # Output for CI automation
    if ENV.fetch("GITHUB_ACTIONS", "false") == "true"
      File.open(ENV.fetch("GITHUB_OUTPUT"), "a") do |file|
        file.puts "nix_release=#{release_name}"
        file.puts "updated=#{updated}"
      end
    end
  else
    get_eval(eval_id)
  end
end

main(ARGV[0])
