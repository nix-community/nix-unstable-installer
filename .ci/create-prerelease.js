module.exports = async ({require, context, core, github}) => {
  if (!process.env.NIX_RELEASE)
    throw new Error('NIX_RELEASE empty or undefined');

  const fs = require('fs');
  const os = require('os');
  const path = require('path');

  const nix_release = process.env.NIX_RELEASE;

  const dist_dir = './dist';
  const body_name = 'RELEASE.md';

  const tag = nix_release;
  const name = `${nix_release}`;
  const body = fs.readFileSync(path.join(dist_dir, body_name), 'utf8');

  const assets = Object.fromEntries(fs.readdirSync(dist_dir).filter((file_name) => file_name != body_name).map((file_name) => [file_name, path.join(dist_dir, file_name)]));

  core.startGroup('Release information');

  core.info(`Tag: ${tag}`);
  core.info(`Name: ${name}`);
  core.info(`Body:\n${body.split(/\r?\n/).map((line) => `  ${line}`).join(os.EOL)}`);
  core.info(`Assets:\n${Object.keys(assets).map((asset) => `  ${asset}`).join(os.EOL)}`);

  core.endGroup();

  core.startGroup('Create release');

  core.info(`Creating prerelease for tag '${tag}'`);

  const release = await github.rest.repos.createRelease({
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

    await github.rest.repos.uploadReleaseAsset({
      ...context.repo,
      release_id: release.data.id,
      name: asset_name,
      data: fs.readFileSync(asset_path),
    });
  }

  core.endGroup();
};
