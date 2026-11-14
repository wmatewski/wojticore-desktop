/** Load private application values at startup; explicitly configured Cloud Run variables take precedence. */
export async function loadDopplerSecrets(env: NodeJS.ProcessEnv = process.env): Promise<void> {
  const token = env.DOPPLER_TOKEN;
  if (!token) return;
  const project = env.DOPPLER_PROJECT;
  const config = env.DOPPLER_CONFIG ?? 'prd';
  if (!project) throw new Error('DOPPLER_PROJECT is required when DOPPLER_TOKEN is set');

  const url = new URL('https://api.doppler.com/v3/configs/config/secrets/download');
  url.searchParams.set('project', project);
  url.searchParams.set('config', config);
  url.searchParams.set('format', 'json');
  const response = await fetch(url, {
    headers: { Authorization: "Bearer " + token },
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) throw new Error(`Doppler secrets download failed (${response.status})`);
  const downloaded: unknown = await response.json();
  if (typeof downloaded !== 'object' || downloaded === null || Array.isArray(downloaded)) {
    throw new Error('Doppler returned an invalid secrets document');
  }
  for (const [key, entry] of Object.entries(downloaded)) {
    const value = typeof entry === 'string'
      ? entry
      : typeof entry === 'object' && entry !== null && 'computed' in entry && typeof entry.computed === 'string'
        ? entry.computed
        : undefined;
    if (value !== undefined && env[key] === undefined) env[key] = value;
  }
}
