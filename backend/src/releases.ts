import semver from 'semver';

export type Channel = 'stable' | 'development';
export type Architecture = 'x86_64' | 'aarch64';

export interface PackageArtifact {
  name: string;
  version: string;
  url: string;
  sha256: string;
}

export interface ReleaseManifest {
  version: string;
  channel: Channel;
  architecture: Architecture;
  publishedAt: string;
  changelogUrl?: string;
  packages: PackageArtifact[];
}

export interface ReleaseStore {
  latest(channel: Channel, architecture: Architecture): Promise<unknown | null>;
}

export function isReleaseManifest(value: unknown): value is ReleaseManifest {
  if (typeof value !== 'object' || value === null) return false;
  const item = value as Record<string, unknown>;
  if (typeof item.version !== 'string' || !semver.valid(item.version)) return false;
  if (item.channel !== 'stable' && item.channel !== 'development') return false;
  if (item.architecture !== 'x86_64' && item.architecture !== 'aarch64') return false;
  if (typeof item.publishedAt !== 'string' || !Number.isFinite(Date.parse(item.publishedAt))) return false;
  if (item.changelogUrl !== undefined && typeof item.changelogUrl !== 'string') return false;
  if (!Array.isArray(item.packages)) return false;
  return item.packages.every((pkg: unknown) => {
    if (typeof pkg !== 'object' || pkg === null) return false;
    const artifact = pkg as Record<string, unknown>;
    return typeof artifact.name === 'string'
      && typeof artifact.version === 'string'
      && semver.valid(artifact.version) !== null
      && typeof artifact.url === 'string'
      && /^https:\/\//.test(artifact.url)
      && typeof artifact.sha256 === 'string'
      && /^[a-f0-9]{64}$/i.test(artifact.sha256);
  });
}
