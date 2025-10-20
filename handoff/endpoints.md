Base URL: https://api.diygenieapp.com
Auth: query param `user_id` (UUID string). No `X-User-Id` header.

GET /health
- 200 OK → { "ok": true, "ts": "...", "version": "0.1.0" }

GET /api/projects?user_id={UUID}
- 200 OK → { "ok": true, "items": [ { "id": "UUID", "name": "string", "status": "draft|processing|ready", "input_image_url": null|url, "preview_url": null|url } ] }

POST /api/projects?user_id={UUID}
Body (JSON):
{
  "name": "string (min 10)",
  "goal": "string (optional)",
  "client": { "budget": "$|$$|$$$" }   // optional
}
- 201 Created → { "ok": true, "id": "UUID", "name": "...", "status": "draft", "input_image_url": null, "preview_url": null }

POST /api/projects/{id}/photo?user_id={UUID}
- multipart/form-data: field name `file` (jpeg/png), optional `note`
- 200/201 → updated project summary JSON

POST /api/projects/{id}/preview?user_id={UUID}
- 202 Accepted → { "ok": true, "id": "UUID", "state": "queued|processing|ready", "updated_at": "ISO8601" }

GET /api/projects/{id}/plan?user_id={UUID}
- 200 OK → { "ok": true, "id": "UUID", "steps": [...], "tools": [...], "materials": [...], "updated_at": "ISO8601" }
