# Backend workflow

- For any backend deployment, read `docs/deployment.md` first and follow it.
- Build production images in GitHub Actions (`.github/workflows/build.yml`), not locally or on the VM. A deployment request authorizes committing and pushing the backend changes needed to trigger that build; inspect unrelated local edits and leave them out.
- Wait for successful Actions completion for the exact pushed commit. Verify the image revision label, then deploy its immutable GHCR digest.
- Preserve server configuration and secrets. Back up the database, current image, Compose configuration and changed mounted Resources before applying migrations. Validate schema-changing releases against an isolated database copy first.
- Restart only the backend app; do not restart PostgreSQL, the website, admin, MCP, registry or nginx unless the requested change requires it.
- No automatic amend/force-push unless explicitly requested. Never commit `.env` or credentials.

## Model conventions

- Use `@Field` for stored model fields, including nullable columns. Express nullability with an optional Swift type (for example, `@Field(key: "medium_url") var mediumUrl: String?`); do not use `@OptionalField`. Keep nullable columns nullable in database migrations. Relationship, ID, and timestamp wrappers retain their specialized types.
- In DTO `toModel` methods, pass initial field values through the model initializer instead of assigning them to the object after construction. Extend the initializer when adding fields.
