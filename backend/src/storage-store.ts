import { Storage } from '@google-cloud/storage';
import type { Architecture, Channel, ReleaseStore } from './releases.js';

export class GcsReleaseStore implements ReleaseStore {
  constructor(private readonly bucketName: string, private readonly storage = new Storage()) {
    if (!bucketName) throw new Error('RELEASES_BUCKET is required');
  }

  async latest(channel: Channel, architecture: Architecture): Promise<unknown | null> {
    const file = this.storage.bucket(this.bucketName).file(`channels/${channel}/${architecture}/latest.json`);
    try {
      const [contents] = await file.download();
      return JSON.parse(contents.toString('utf8')) as unknown;
    } catch (error) {
      if (typeof error === 'object' && error !== null && 'code' in error && error.code === 404) return null;
      throw error;
    }
  }
}
