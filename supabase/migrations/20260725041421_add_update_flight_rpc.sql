SET check_function_bodies = false;

CREATE OR REPLACE FUNCTION "flight"."update_flight_with_timezone"(
  "p_flight_id" "uuid",
  "p_departure_airport_id" "uuid",
  "p_departure_local" "text",
  "p_arrival_airport_id" "uuid",
  "p_arrival_local" "text",
  "p_flight_number" "text",
  "p_airline_id" "uuid",
  "p_ticket_class" "flight"."ticket_class",
  "p_seat_no" "text" DEFAULT NULL::"text",
  "p_seat_pos" "flight"."seat_position" DEFAULT NULL::"flight"."seat_position",
  "p_aircraft_id" "uuid" DEFAULT NULL::"uuid",
  "p_tail_no" "text" DEFAULT NULL::"text",
  "p_notes" "text" DEFAULT NULL::"text"
) RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'flight'
    AS $$
declare
  dep_tz text;
  arr_tz text;
  dep_utc timestamptz;
  arr_utc timestamptz;
begin
  select timezone into dep_tz
  from airports
  where id = p_departure_airport_id;

  select timezone into arr_tz
  from airports
  where id = p_arrival_airport_id;

  dep_utc := (p_departure_local::timestamp at time zone dep_tz);
  arr_utc := (p_arrival_local::timestamp at time zone arr_tz);

  update flights set
    departure_airport_id = p_departure_airport_id,
    departure_time = dep_utc,
    arrival_airport_id = p_arrival_airport_id,
    arrival_time = arr_utc,
    flight_number = p_flight_number,
    airline_id = p_airline_id,
    ticket_class = p_ticket_class,
    seat_number = p_seat_no,
    seat_position = p_seat_pos,
    aircraft_id = p_aircraft_id,
    tail_number = p_tail_no,
    notes = p_notes
  where id = p_flight_id
    and user_id = auth.uid();
end;
$$;

GRANT ALL ON FUNCTION "flight"."update_flight_with_timezone"("p_flight_id" "uuid", "p_departure_airport_id" "uuid", "p_departure_local" "text", "p_arrival_airport_id" "uuid", "p_arrival_local" "text", "p_flight_number" "text", "p_airline_id" "uuid", "p_ticket_class" "flight"."ticket_class", "p_seat_no" "text", "p_seat_pos" "flight"."seat_position", "p_aircraft_id" "uuid", "p_tail_no" "text", "p_notes" "text") TO "anon";
GRANT ALL ON FUNCTION "flight"."update_flight_with_timezone"("p_flight_id" "uuid", "p_departure_airport_id" "uuid", "p_departure_local" "text", "p_arrival_airport_id" "uuid", "p_arrival_local" "text", "p_flight_number" "text", "p_airline_id" "uuid", "p_ticket_class" "flight"."ticket_class", "p_seat_no" "text", "p_seat_pos" "flight"."seat_position", "p_aircraft_id" "uuid", "p_tail_no" "text", "p_notes" "text") TO "authenticated";
GRANT ALL ON FUNCTION "flight"."update_flight_with_timezone"("p_flight_id" "uuid", "p_departure_airport_id" "uuid", "p_departure_local" "text", "p_arrival_airport_id" "uuid", "p_arrival_local" "text", "p_flight_number" "text", "p_airline_id" "uuid", "p_ticket_class" "flight"."ticket_class", "p_seat_no" "text", "p_seat_pos" "flight"."seat_position", "p_aircraft_id" "uuid", "p_tail_no" "text", "p_notes" "text") TO "service_role";
