import { createApp } from './app.js';
import { loadDopplerSecrets } from './doppler.js';
import { GcsReleaseStore } from './storage-store.js';

await loadDopplerSecrets();
const app = createApp(new GcsReleaseStore(process.env.RELEASES_BUCKET ?? ''));
const port = Number(process.env.PORT ?? '8080');
if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('PORT must be a valid TCP port');
await app.listen({ host: '0.0.0.0', port });
