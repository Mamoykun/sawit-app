-- Fix: V13 created period as CHAR(7) (bpchar), but Hibernate maps String to VARCHAR.
-- Schema validation fails on startup. Convert to VARCHAR(7) to match entity mapping.
ALTER TABLE ai_usage ALTER COLUMN period TYPE VARCHAR(7);
