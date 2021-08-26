module.exports = async ({require, context, core, github}) => {
  if (!process.env.HYDRA_EVAL || !process.env.NIX_RELEASE)
    throw new Error('HYDRA_EVAL or NIX_RELEASE empty or undefined');

  const fs = require('fs');
  const os = require('os');
  const path = require('path');

  const hydra_eval = process.env.HYDRA_EVAL;
  const nix_release = process.env.NIX_RELEASE;

  const tag = nix_release;
  const name = `${nix_release}`;
  const body = `https://hydra.nixos.org/eval/${hydra_eval}`;

  const asset_dir = './dist';

  const assets = Object.fromEntries(fs.readdirSync(asset_dir).map((file_name) => [file_name, path.join(asset_dir, file_name)]));

  core.startGroup('Release information');

  core.info(`Tag: ${tag}`);
  core.info(`Name: ${name}`);
  core.info(`Body:\n${body.split(/\r?\n/).map((line) => `  ${line}`).join(os.EOL)}`);
  core.info(`Assets:\n${Object.keys(assets).map((asset) => `  ${asset}`).join(os.EOL)}`);

  core.endGroup();

  core.startGroup('Create release');

  core.info(`Creating prerelease for tag '${tag}'`);

  const release = await github.repos.createRelease({
    ...context.repo,
    tag_name: tag,
    name: name,
    body: body,
    prerelease: true,
    draft: false,
  });

  core.endGroup();

  core.startGroup('Upload release assets');

  for (let [asset_name, asset_path] of Object.entries(assets)) {
    core.info(`Uploading '${asset_name}' from '${asset_path}'`);

    await github.repos.uploadReleaseAsset({
      ...context.repo,
      release_id: release.data.id,
      name: asset_name,
      data: fs.readFileSync(asset_path),
    });
  }

  core.endGroup();
};
