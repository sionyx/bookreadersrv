# Backend workflow

- For any backend deployment, read `docs/deployment.md` first and follow it.
- Build production images in GitHub Actions (`.github/workflows/build.yml`), not locally or on the VM. A deployment request authorizes committing and pushing the backend changes needed to trigger that build; inspect unrelated local edits and leave them out.
- Wait for successful Actions completion for the exact pushed commit. Verify the image revision label, then deploy its immutable GHCR digest.
- Preserve server configuration and secrets. Back up the database, current image, Compose configuration and changed mounted Resources before applying migrations. Validate schema-changing releases against an isolated database copy first.
- Restart only the backend app; do not restart PostgreSQL, the website, admin, MCP, registry or nginx unless the requested change requires it.
- No automatic amend/force-push unless explicitly requested. Never commit `.env` or credentials.
