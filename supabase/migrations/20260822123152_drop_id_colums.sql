-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

ALTER TABLE flight.aircrafts
  DROP CONSTRAINT aircrafts_pkey;

ALTER TABLE flight.aircrafts
  DROP COLUMN id;

ALTER TABLE flight.aircrafts
  ADD CONSTRAINT aircrafts_pkey PRIMARY KEY (icao_code);