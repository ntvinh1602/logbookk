import 'leaflet/dist/leaflet.css'
import airportPin from '@/assets/airport-pin.png'
import { Fragment, useRef } from 'react'
import {
  MapContainer,
  Polyline,
  Popup,
  TileLayer,
  Pane,
  Marker,
} from 'react-leaflet'
import L from 'leaflet'
import type { AirportRow, UniqueRoutes } from '@/features/flight/types'

type Props = {
  data: UniqueRoutes[]
  airports: AirportRow[]
}

function interpolateColor(start: number[], end: number[], factor: number) {
  return start.map((s, i) => Math.round(s + factor * (end[i] - s)))
}

function getColor(freq: number, max: number) {
  const normalized = Math.log(freq + 1) / Math.log(max + 1)

  const green = [21, 128, 61]
  const yellow = [202, 138, 4]
  const red = [185, 28, 28]

  const rgb =
    normalized <= 0.5
      ? interpolateColor(green, yellow, normalized / 0.5)
      : interpolateColor(yellow, red, (normalized - 0.5) / 0.5)

  return `rgb(${rgb[0]}, ${rgb[1]}, ${rgb[2]})`
}

const airportIcon = L.icon({
  iconUrl: airportPin,
  iconSize: [32, 32],
  iconAnchor: [13, 27],
  popupAnchor: [0, -27],
})

export default function LeafletMap({ data, airports }: Props) {
  const maxFreq = Math.max(...data.map((route) => route.route_frequency), 1)

  const mapKeyRef = useRef<string | null>(null)

  if (!mapKeyRef.current) {
    mapKeyRef.current = crypto.randomUUID()
  }

  return (
    <div className="h-150 w-full overflow-hidden isolate">
      <MapContainer
        center={[15, 105]}
        zoom={4}
        scrollWheelZoom={false}
        className="h-full w-full"
      >
        <Pane name="routes-hitbox" style={{ zIndex: 400 }} />
        <Pane name="routes" style={{ zIndex: 401 }} />

        <TileLayer url="https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png" />

        {/* Routes */}
        {data.map((route) => {
          const positions: [number, number][] = [
            [route.airport_a_lat, route.airport_a_lng],
            [route.airport_b_lat, route.airport_b_lng],
          ]

          return (
            <Fragment key={`${route.airport_a_code}-${route.airport_b_code}`}>
              <Polyline
                positions={positions}
                pane="routes-hitbox"
                pathOptions={{
                  color: 'transparent',
                  weight: 14,
                  opacity: 0,
                }}
              >
                <Popup>
                  <div className="text-sm">
                    <strong>
                      {route.airport_a_code} ↔ {route.airport_b_code}
                    </strong>
                    <br />
                    <strong>Total Flights:</strong> {route.route_frequency}
                  </div>
                </Popup>
              </Polyline>

              <Polyline
                positions={positions}
                pane="routes"
                interactive={false}
                pathOptions={{
                  color: getColor(route.route_frequency, maxFreq),
                  weight: 2,
                  lineCap: 'round',
                  lineJoin: 'round',
                }}
              />
            </Fragment>
          )
        })}

        {/* Airports */}
        {airports.map((airport) => (
          <Marker
            key={airport.iata_code}
            position={[airport.lat, airport.lng]}
            icon={airportIcon}
          >
            <Popup>
              {airport.name} ({airport.iata_code})
            </Popup>
          </Marker>
        ))}
      </MapContainer>
    </div>
  )
}
