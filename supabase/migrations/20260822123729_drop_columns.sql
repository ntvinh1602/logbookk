-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

ALTER TABLE flight.airlines
  DROP CONSTRAINT airlines_pkey;

ALTER TABLE flight.airlines
  DROP COLUMN id;

ALTER TABLE flight.airlines
  ADD CONSTRAINT airlines_pkey PRIMARY KEY (icao_code);

ALTER TABLE flight.airports
  DROP CONSTRAINT airports_pkey;

ALTER TABLE flight.airports
  DROP COLUMN id;

ALTER TABLE flight.airports
  ADD CONSTRAINT airports_pkey PRIMARY KEY (iata_code);

ALTER TABLE flight.airlines
  ALTER COLUMN icao_code SET NOT NULL;