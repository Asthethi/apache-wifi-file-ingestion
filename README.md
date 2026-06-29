# Apache WiFi File Ingestion

NiFi 2.5.0 starter flow for ingesting ZIP files, archiving parent ZIPs and extracted child files, and recording file lifecycle metadata in PostgreSQL.

## Files

- `nifi/zip-file-ingestion-flow.json` - single process group flow definition for import into NiFi.
- `database/file_metadata_postgres.sql` - PostgreSQL enum, table, indexes, and update timestamp trigger.
- `.env.example` - environment variables expected by the NiFi flow.

## Runtime Assumptions

NiFi does not automatically load `.env` files. Load the values from `.env` into the NiFi process environment before startup, or expose them as JVM/system environment variables that NiFi Expression Language can resolve.

The flow uses `PutSQL` with a `DBCPConnectionPool` controller service. After importing, enable the controller service and verify the PostgreSQL JDBC driver is available to NiFi.

## Docker Compose

Start PostgreSQL:

```bash
docker compose --env-file .env -f docker-compose.postgres.yml up -d
```

Start NiFi:

```bash
docker compose -f docker-compose.nifi.yml up -d
```

Both compose files use the shared Docker network `docker-shared-network`.

## Flow Summary

1. `ListFile` scans `${BASE_PATH}` for `*.zip`.
2. A parent UUID is generated and inserted into `file_metadata` with status `SUBMITTED`.
3. `FetchFile` fetches the ZIP and moves the source file to `${BASE_PATH}${ARCHIVE_ZIP_PATH}`.
4. The parent row is updated to `ARCHIVED` after the ZIP archive move succeeds.
5. The filename is validated against `${ZIP_NAME_REGEX}`.
6. Invalid names or extraction failures update the parent row to `FAILED`.
7. Valid ZIPs are extracted with `UnpackContent`.
8. Each child file receives a UUID, is inserted with status `SUBMITTED`, and is written to `${BASE_PATH}${FILE_ARCHIVE_PATH}`.
9. Child rows are updated to `ARCHIVED` after file archival succeeds.

The generated UUID for the parent ZIP is kept in the `zip.id` FlowFile attribute and reused as `parent_id` for every child entry extracted from that ZIP.
