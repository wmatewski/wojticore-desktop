import assert from 'node:assert/strict';
import test from 'node:test';
import { createApp } from '../src/app.js';
import type { ReleaseManifest, ReleaseStore } from '../src/releases.js';

const manifest: ReleaseManifest = {
  version: '0.1.0-alpha.2', channel: 'development', architecture: 'x86_64',
  publishedAt: '2026-11-13T12:00:00Z', packages: [{
    name: 'glass-shell', version: '0.1.0-alpha.2', url: 'https://downloads.example/glass-shell.rpm', sha256: 'a'.repeat(64),
  }],
};
const store = (value: unknown | null | Error): ReleaseStore => ({
  latest: async () => { if (value instanceof Error) throw value; return value; },
});

test('health responds without touching GCS', async () => {
  const app = createApp(store(new Error('unavailable')));
  const response = await app.inject('/healthz');
  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.json(), { status: 'ok' });
  await app.close();
});

test('latest release returns the manifest and rejects invalid stored data', async () => {
  const app = createApp(store(manifest));
  assert.equal((await app.inject('/v1/releases/latest?channel=development')).statusCode, 200);
  await app.close();
  const invalid = createApp(store({ ...manifest, packages: [{ ...manifest.packages[0], sha256: 'bad' }] }));
  assert.equal((await invalid.inject('/v1/releases/latest?channel=development')).statusCode, 502);
  await invalid.close();
});

test('update check validates inputs and compares semver', async () => {
  const app = createApp(store(manifest));
  const update = await app.inject('/v1/updates/check?channel=development&current=0.1.0-alpha.1');
  assert.equal(update.statusCode, 200);
  assert.equal(update.json().updateAvailable, true);
  assert.equal((await app.inject('/v1/updates/check?current=not-a-version')).statusCode, 400);
  await app.close();
});

test('release lookup reports missing GCS objects and outages', async () => {
  const missing = createApp(store(null));
  assert.equal((await missing.inject('/v1/releases/latest')).statusCode, 404);
  await missing.close();
  const down = createApp(store(new Error('network')));
  assert.equal((await down.inject('/v1/releases/latest')).statusCode, 503);
  await down.close();
});
