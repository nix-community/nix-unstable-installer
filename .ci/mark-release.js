module.exports = async ({require, context, core, github}) => {
  if (!process.env.NIX_RELEASE)
    throw new Error('NIX_RELEASE empty or undefined');

  const nix_release = process.env.NIX_RELEASE;

  const tag = nix_release;

  core.info(`Finding release for tag '${tag}'`);

  const release = await github.rest.repos.getReleaseByTag({
    ...context.repo,
    tag: tag,
  });

  core.info(`Marking as full release`);

  await github.rest.repos.updateRelease({
    ...context.repo,
    release_id: release.data.id,
    prerelease: false,
  });
};
