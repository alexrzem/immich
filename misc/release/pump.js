import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import semver, { SemVer } from 'semver';

const PROJECT_ROOT = join(dirname(fileURLToPath(import.meta.url)), '../..');

const Files = {
  PackageJson: join(PROJECT_ROOT, 'package.json'),
  ExampleEnv: join(PROJECT_ROOT, 'docker/example.env'),
  Docs: {
    Env: join(PROJECT_ROOT, 'docs/docs/install/environment-variables.md'),
    Upgrading: join(PROJECT_ROOT, 'docs/docs/install/upgrading.md'),
  },
};

export class PumpUsageError extends Error {}
export class PumpInvalidError extends Error {
  constructor(options) {
    super(`Invalid pump`);

    this.version = options.version;
    this.newVersion = options.newVersion;
  }
}

/**
 * @param {string} type
 */
export const pump = (type) => {
  const currentVersionRaw = getCurrentVersion();
  const nextVersionRaw = getNextVersion(currentVersionRaw, type);
  const nextVersion = semver.parse(normalize(nextVersionRaw));

  if (nextVersion && type === 'release') {
    const major = `v${nextVersion.major}`;

    // sync major tag references in docs and example env file
    findAndReplace(
      Files.ExampleEnv,
      /^IMMICH_VERSION=v\d+$/m,
      `IMMICH_VERSION=${major}`,
    );
    findAndReplace(
      Files.Docs.Env,
      /(`IMMICH_VERSION`.*?)`v\d+`/,
      `$1\`${major}\``,
    );
    findAndReplace(Files.Docs.Upgrading, /:v\d+/, `:${major}`);
  }

  return nextVersionRaw;
};

const getCurrentVersion = () =>
  JSON.parse(readFileSync(Files.PackageJson, 'utf8')).version;

/**
 * @param {string} versionRaw
 * @param {string} type
 */
export const getNextVersion = (versionRaw, type) => {
  if (!versionRaw) {
    throw new PumpUsageError();
  }

  versionRaw = normalize(versionRaw);

  const version = semver.parse(versionRaw);
  if (!version) {
    throw new PumpUsageError();
  }

  let newVersionRaw;
  let valid = true;

  switch (type) {
    case 'patch':
    case 'prepatch':
    case 'minor':
    case 'preminor':
    case 'premajor': {
      newVersionRaw = inc(version, type);
      // can only use while not in a prerelease
      valid = !isPrerelease(version);
      break;
    }

    case 'prerelease': {
      newVersionRaw = inc(version, type);
      // can only use while in a prerelease
      valid = isPrerelease(version);
      break;
    }

    case 'release': {
      // drop prerelease part
      newVersionRaw = `${version.major}.${version.minor}.${version.patch}`;
      // can only use to promote a prerelease to a release (no version change)
      valid = isPrerelease(version);
      break;
    }

    default: {
      throw new PumpUsageError();
    }
  }

  if (!newVersionRaw) {
    throw new PumpUsageError();
  }

  newVersionRaw = normalize(newVersionRaw);

  const newVersion = semver.parse(newVersionRaw);
  if (!newVersion) {
    throw new PumpUsageError();
  }

  const invalidUpgrade =
    isPrerelease(version) &&
    !isPrerelease(newVersion) &&
    (version.major !== newVersion.major ||
      version.minor !== newVersion.minor ||
      version.patch !== newVersion.patch);

  if (!valid || invalidUpgrade) {
    throw new PumpInvalidError({
      type,
      version: versionRaw,
      newVersion: newVersionRaw,
    });
  }

  return newVersionRaw;
};

const findAndReplace = (path, pattern, replacement) =>
  writeFileSync(path, readFileSync(path, 'utf8').replace(pattern, replacement));

const isPrerelease = (version) => version.prerelease.length > 0;

/**
 * @param {SemVer} version
 * @returns {boolean}
 */
const inc = (version, type) => `v${semver.inc(version, type, {}, 'rc')}`;

/** @param {string} version */
const normalize = (version) => {
  if (version.startsWith('v')) {
    version = version.slice(1);
  }

  return version;
};
