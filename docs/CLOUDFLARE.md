# Cloudflare Worker setup

The site is a static Astro build served with Wrangler static assets. No application server or Node runtime is deployed.

1. Verify the Cloudflare account owns or is authorized to use the wojticore.eu zone. Do not replace existing DNS records.
2. Create a scoped Cloudflare API token with Workers Scripts:Edit and permission to use the target account. Store it as the GitHub Actions secret CF_API_TOKEN; store the account ID as repository variable CLOUDFLARE_ACCOUNT_ID.
3. Confirm desktop.wojticore.eu is available for this Worker. The Wrangler production environment declares the desktop.wojticore.eu route for zone wojticore.eu.
4. Set repository variable DEPLOY_FRONTEND=true only after the token, account and route are ready.
5. Push a frontend change to main or run Deploy frontend manually. Verify the custom domain, TLS and 404 page.

The Worker serves frontend/dist as static assets. Deployment uses npm ci, Astro build and Wrangler deploy. The configuration and deploy command are in frontend/wrangler.jsonc and .github/workflows/deploy-frontend.yml.
