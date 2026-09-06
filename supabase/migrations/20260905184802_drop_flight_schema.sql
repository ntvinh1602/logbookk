-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

SET check_function_bodies = false;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA flight REVOKE ALL ON TABLES FROM anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA flight REVOKE ALL ON SEQUENCES FROM anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA flight REVOKE ALL ON ROUTINES FROM anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA flight REVOKE ALL ON TABLES FROM authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA flight REVOKE ALL ON SEQUENCES FROM authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA flight REVOKE ALL ON ROUTINES FROM authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA flight REVOKE ALL ON TABLES FROM service_role;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA flight REVOKE ALL ON SEQUENCES FROM service_role;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA flight REVOKE ALL ON ROUTINES FROM service_role;

DROP TYPE flight.seat_type;

DROP FUNCTION
  flight.insert_flight_with_timezone(p_departure_airport_id uuid, p_departure_local text, p_arrival_airport_id uuid, p_arrival_local text, p_flight_number text, p_airline_id uuid,
  p_ticket_class flight.ticket_class, p_seat_no text, p_seat_pos flight.seat_position, p_aircraft_id uuid, p_tail_no text, p_notes text);

DROP FUNCTION
  flight.update_flight_with_timezone(p_flight_id uuid, p_departure_airport_id uuid, p_departure_local text, p_arrival_airport_id uuid, p_arrival_local text, p_flight_number text,
  p_airline_id uuid, p_ticket_class flight.ticket_class, p_seat_no text, p_seat_pos flight.seat_position, p_aircraft_id uuid, p_tail_no text, p_notes text);

DROP VIEW flight.lifetime_stats;

DROP VIEW flight.flights_summary;

DROP VIEW flight.routes_geojson;

DROP FUNCTION flight.haversine_distance_km(lat1 double precision, lng1 double precision, lat2 double precision, lng2 double precision);

DROP POLICY "Auth users can read aircrafts" ON flight.aircrafts;

DROP POLICY "Auth users can read airlines" ON flight.airlines;

DROP POLICY "Auth users can read airports" ON flight.airports;

DROP POLICY "Enable insert for users based on user_id" ON flight.flights;

DROP POLICY "Enable update for users based on user_id" ON flight.flights;

DROP POLICY "Enable users to delete their own data only" ON flight.flights;

DROP POLICY "Enable users to view their own data only" ON flight.flights;

DROP TABLE flight.flights;

DROP TYPE flight.seat_position;

DROP TYPE flight.ticket_class;

DROP TABLE flight.aircrafts;

DROP TABLE flight.airlines;

DROP TABLE flight.airports;

DROP SCHEMA IF EXISTS flight;