CREATE TYPE file_status AS ENUM (
    'SUBMITTED',
    'ARCHIVED',
    'PROCESSING',
    'FAILED'
);

CREATE TABLE file_metadata (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    extension TEXT,
    file_size BIGINT NOT NULL CHECK (file_size >= 0),
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    file_status file_status NOT NULL,
    parent_zip_name TEXT,
    parent_id UUID REFERENCES file_metadata(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT parent_zip_metadata_shape CHECK (
        (parent_id IS NULL AND parent_zip_name = name)
        OR
        (parent_id IS NOT NULL AND parent_zip_name IS NOT NULL)
    )
);

CREATE INDEX idx_file_metadata_parent_id
    ON file_metadata(parent_id);

CREATE INDEX idx_file_metadata_parent_zip_name
    ON file_metadata(parent_zip_name);

CREATE INDEX idx_file_metadata_status
    ON file_metadata(file_status);

CREATE OR REPLACE FUNCTION set_file_metadata_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_file_metadata_updated_at
BEFORE UPDATE ON file_metadata
FOR EACH ROW
EXECUTE FUNCTION set_file_metadata_updated_at();

