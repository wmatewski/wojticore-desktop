import Fastify from 'fastify';
import semver from 'semver';
import { isReleaseManifest, type Architecture, type Channel, type ReleaseStore } from './releases.js';

const querySchema = {
  type: 'object',
  properties: {
    channel: { type: 'string', enum: ['stable', 'development'], default: 'stable' },
    architecture: { type: 'string', enum: ['x86_64', 'aarch64'], default: 'x86_64' },
    current: { type: 'string', minLength: 1, maxLength: 64 },
  },
  additionalProperties: false,
} as const;

export function createApp(store: ReleaseStore) {
  const app = Fastify({ logger: false });
  app.get('/health', async () => ({ status: 'ok' }));

  app.get<{ Querystring: { channel?: Channel; architecture?: Architecture } }>(
    '/v1/releases/latest', { schema: { querystring: querySchema } }, async (request, reply) => {
      const channel = request.query.channel ?? 'stable';
      const architecture = request.query.architecture ?? 'x86_64';
      try {
        const manifest = await store.latest(channel, architecture);
        if (manifest === null) return reply.code(404).send({ error: 'release_not_found' });
        if (!isReleaseManifest(manifest) || manifest.channel !== channel || manifest.architecture !== architecture) {
          return reply.code(502).send({ error: 'invalid_release_manifest' });
        }
        return manifest;
      } catch {
        return reply.code(503).send({ error: 'release_service_unavailable' });
      }
    },
  );

  app.get<{ Querystring: { channel?: Channel; architecture?: Architecture; current: string } }>(
    '/v1/updates/check', { schema: { querystring: { ...querySchema, required: ['current'] } } }, async (request, reply) => {
      const current = semver.valid(request.query.current);
      if (!current) return reply.code(400).send({ error: 'invalid_current_version' });
      const channel = request.query.channel ?? 'stable';
      const architecture = request.query.architecture ?? 'x86_64';
      try {
        const manifest = await store.latest(channel, architecture);
        if (manifest === null) return reply.code(404).send({ error: 'release_not_found' });
        if (!isReleaseManifest(manifest) || manifest.channel !== channel || manifest.architecture !== architecture) {
          return reply.code(502).send({ error: 'invalid_release_manifest' });
        }
        return { current, updateAvailable: semver.gt(manifest.version, current), latest: manifest };
      } catch {
        return reply.code(503).send({ error: 'release_service_unavailable' });
      }
    },
  );

  return app;
}
