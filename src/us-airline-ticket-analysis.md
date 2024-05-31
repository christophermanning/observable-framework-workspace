---
theme: dashboard
sql:
  airports: ./data/airports.parquet
  arcs: ./data/arcs.parquet
  historical_routes: ./data/historical_routes.parquet
---

# U.S. Airline Ticket Analysis

```js
import deck from "npm:deck.gl";
const {DeckGL, GeoJsonLayer} = deck;
```

```js
// https://observablehq.com/framework/inputs/table
function sparkbar(max) {
  return (x) => htl.html`<div style="
    background: var(--theme-green);
    font: 10px/1.6 var(--sans-serif);
    color: black;
    width: ${100 * x / max}%;
    float: right;
    padding-right: 3px;
    box-sizing: border-box;
    overflow: visible;
    display: flex;
    justify-content: end;">${x.toLocaleString("en-US")}`
}

let toRGB = (color) => {
  return d3
    .color(color)
    .formatRgb()
    .match(/\((.*)\)/)[1]
    .split(",")
    .map((d) => parseInt(d.trim()));
}

let displayAirport = (d) => {
    return html`${d.display_airport_name} <small class="muted">${d.code}</small><br><small>${d.display_airport_city_name_full}</small>`
}
```

```js
// load geojson
const us = await fetch("https://cdn.jsdelivr.net/npm/us-atlas@3.0.1/states-10m.json").then((d) => d.json());
let states = topojson.feature(us, us.objects.states);
let states_with_airports = states;

let newFeatures = [];
for(const d of airports) {
    newFeatures.push({
      type: "Feature",
      geometry: {
        type: "Point",
        coordinates: [d.longitude, d.latitude]
      },
      properties: {
        name: d.code
      }
    });
}

states_with_airports.features = states_with_airports.features.concat(newFeatures);
```

```js
//const color = view(Inputs.color({value: "#c0c0c0"}))
```

```js
let selectedCodes = new Set()

let layerArcs = [...arcs].map((d, i) => {
  let origin = airportsMap.get(d.min_airport_id)
  let dest = airportsMap.get(d.max_airport_id)

  selectedCodes.add(origin.code)
  selectedCodes.add(dest.code)

  return {
    color: toRGB(routeColors.get(d.arc_id)),
    distance: d.distance,
    from: { name: origin.code, coordinates: [origin.longitude, origin.latitude] },
    to: { name: dest.code, coordinates: [dest.longitude, dest.latitude] }
  }
})

const colorScale = d3.scaleSequential(d3.interpolateBlues);
let layers = [
    // https://deck.gl/docs/api-reference/layers/geojson-layer
    new deck.GeoJsonLayer({
      id: 'states',
      data: states_with_airports,

      stroked: true,
      getLineColor: toRGB("#c0c0c0"),
      getLineWidth: 1.5,
      lineWidthUnits: 'pixels',

      getText: (f) => f.properties.name,
      getTextSize: (f) => 14,
      textFontFamily: 'monospace',
      textFontWeight: 'bold',
      getTextColor: toRGB("white"),
      getTextPixelOffset: [-15, -5],
      textBillboard: false,
      pointType: "text",

      filled: false,
    }),
    new deck.ArcLayer({
      id: "arc",
      data: layerArcs,
      getSourcePosition: (d) => d.from.coordinates,
      getTargetPosition: (d) => d.to.coordinates,
      getSourceColor: d => d.color,
      getTargetColor: d => d.color,
      getHeight: 0.3,
      getWidth: 2,
      pickable: true,
    })
];
deckgl.setProps({ layers });
```

```js
let INITIAL_VIEW_STATE = {
    latitude: 36,
    longitude: -95,
    zoom: 3,
    minZoom: 2.5,
    maxZoom: 6,
};
const deckgl = new deck.DeckGL({
    initialViewState: INITIAL_VIEW_STATE,
    container: container,
    controller: true,
    getTooltip: ({object}) => object && `${object.from.name} <-> ${object.to.name}\n${object.distance}mi`,
    getCursor: ({isHovering}) => isHovering ? 'pointer' : 'grab'
});

invalidation.then(() => {
    deckgl.finalize();
    container.innerHTML = "";
});
```

```js
let dairports = [...airports]
const airportsInput = Inputs.table(dairports, {
    rows: 8,
    header: {display_airport_name: "Name", total_passengers_2023: "2023 Total Passengers"},
    columns: ["display_airport_name", "total_passengers_2023"], value:[airports[3]],
    value: dairports.filter(d => { return d.code == "ORD" }),
    sort: "total_passengers_2023",
    reverse: true,
    required: false,
    format: {
        display_airport_name: (d, i, a) => {
            return displayAirport(a[i])
        },
        total_passengers_2023: sparkbar(d3.max(airports, d => d.total_passengers_2023))
    }
})
const selectedAirports = Generators.input(airportsInput)
```

```js
const bcolor = d3.scaleSequential([0, arcAverages.numRows], d3.interpolateRainbow)
const routeColors = new Map([...arcAverages].map((d, i) => [d.arc_id, bcolor(i)]))
```

```js
let allArcAverages = [...arcAverages]
const plotAvgFarePerMile = Plot.plot({
height: 200,
    marks: [
        //Plot.link([1], {
        //  x1: 0,
        //  y1: 0,
        //  x2: Math.max(allArcAverages.map(d=> d.distance)),
        //  y2: Math.max(allArcAverages.map(d=> d.average_fare)),
        //}),
        Plot.dot(arcAverages, {
            x: "distance",
            y: "average_fare",
            stroke: d => { return routeColors.get(d.arc_id) },
        }),
        Plot.tip(arcAverages, Plot.pointerX({
            x: "distance",
            y: "average_fare",
            channels: {
                name: (d) => {
                    let origin = airportsMap.get(d.origin_airport_id)
                    let dest = airportsMap.get(d.dest_airport_id)
                    return `${origin.code} <-> ${dest.code}`
                },
                per_mile: (d,i,a) => {
                    return a[i].average_fare/a[i].distance
                },
            },
            }
        )),
    ],
})

const plotAvgFarePerMileGenerator = Generators.input(plotAvgFarePerMile)
```

<div class="grid grid-cols-4">
  <div class="card grid-colspan-2 grid-rowspan-2">
    <div id="container" style="border-radius: 0.75rem; background: rgb(50,50,50); height: 500px;"></div>
    <h3><small>You can zoom, drag, and tilt this map.</small></h3>
  </div>

  <div class="card grid-colspan-2">
    <h2>Airports</h2>
    ${airportsInput}
    <h3><small>Select airports to filter. 2023 top ${airports.numRows} airports by passenger count. <a href="https://data.bts.gov/Aviation/Airports/kfcv-nyy3/about_data">Airports Source</a>, <a href="https://geodata.bts.gov/datasets/usdot::t-100-domestic-market-and-segment-data/about" target="_blank">Total Passengers Source</a></small></h3>
  </div>

  <div class="card grid-colspan-2">
    <h2>Average Fare Per Mile</h2>
    ${resize(width => plotAvgFarePerMile)}
    <h3><small>Select a point to filter flight paths. Fares are bidirectionally averaged for all time periods.</small></h3>
  </div>
</div>

<div class="grid">
  <div class="card">
    Showing data for <span style="font-family:monospace">${selectedAirports.map(d=>d.code).join(', ')}</span> and ${arcs.numRows} flight ${arcs.numRows > 1 ? "paths" : "path"}.
    <h3><small>Select an airport from the table above to filter airports and select a point on the plot above to filter flight paths.</small></h3>
  </div>
</div>


<div class="grid">
  <div class="card">
    <h2>Historical Fares</h2>
    ${
resize(width => {
    return Plot.plot({
      width: width,
      y: {grid: true},
      marks: [
        Plot.ruleY([0]),
        Plot.lineY(routes, {x: "date", y: "average_fare", z: (d) => {
            return `${d.origin_airport_id}<->${d.dest_airport_id}`
        },
        stroke: d => { return routeColors.get(d.arc_id) }
        }),
        Plot.tip(routes, Plot.pointerX({
            x: "date",
            y: "average_fare",
            channels: {
            date: "date",
            route: (d) => {
                let origin = airportsMap.get(d.origin_airport_id)
                let dest = airportsMap.get(d.dest_airport_id)
                return `${origin.code} ➡ ${dest.code}`
            },
            average_fare: "average_fare"
            }
        }))
      ]
    })
})
}
  </div>
</div>

<div class="grid">
  <div class="card">
    <h2>Historical Passengers</h2>
    ${
resize(width => {
    return Plot.plot({
      width: width,
      y: {grid: true},
      marks: [
        Plot.ruleY([0]),
        Plot.lineY(routes, {x: "date", y: "total_passengers", z: (d) => {
            return `${d.origin_airport_id}<->${d.dest_airport_id}`
        }, stroke: d => { return routeColors.get(d.arc_id) }}),
        Plot.tip(routes, Plot.pointerX({
            x: "date",
            y: "total_passengers",
            channels: {
            date: "date",
            route: (d) => {
                let origin = airportsMap.get(d.origin_airport_id)
                let dest = airportsMap.get(d.dest_airport_id)
                return `${origin.code} ➡ ${dest.code}`
            },
            total_passengers: "total_passengers"
            }
        }))
      ]
    })
})
}
  </div>
</div>

<div class="grid">
  <div class="card">
    <h2>Quarterly Routes</h2>
    ${Inputs.table([...routes], {
      height: 400,
      columns: [
          "date",
          "origin_airport_id",
          "dest_airport_id",
          "average_fare",
          "total_passengers",
      ],
      header: {date: "Date", origin_airport_id: "Origin Airport", dest_airport_id: "Destination Airport", average_fare: "Average Fare", total_passengers: "Total Passengers"},
      width: {
          date: 100,
          average_fare: 150,
          total_passengers: 150,
      },
      format: {
          origin_airport_id: (d,i,a) => {
             let origin = airportsMap.get(a[i].origin_airport_id)
             return html`${displayAirport(origin)}`
          },
          dest_airport_id: (d,i,a) => {
             let dest = airportsMap.get(a[i].dest_airport_id)
             return html`${displayAirport(dest)}`
          },
      },
      sort: "total_passengers",
      reverse: true,
      rows: 30,
    })}
    <small class="muted">Total Rows: ${routes.numRows.toLocaleString("en-US")}</small>
  </div>
</div>

<div class="note small">
<p>The <a href="https://www.transtats.bts.gov/Fields.asp?gnoyr_VQ=FHK" target="_blank">data source</a> (<a href="https://catalog.data.gov/dataset/airline-origin-and-destination-survey-ond" target="_blank">additional information</a>)
only includes a 10% sample of airline tickets and the fares are not inflation adjusted.
<p>Modifications to the original data source include multiplying the historical passenger count by 10 to extrapolate from the 10% sample size and only averaging fares within one standard deviation of the mean to remove outliers.
<p>This dashboard is an independent personal project and is not associated with any official entities.
</div>

```sql id=airports
select * from airports
```

```js
let queryArcId = ""
if(plotAvgFarePerMileGenerator) {
    queryArcId = `and arc_id='${plotAvgFarePerMileGenerator.arc_id}'`
}
```

```js
let airportsMap = new Map([...airports].map(d => [d.airport_id, d]))

let selectedAirportsList = selectedAirports.map(d=>d.airport_id)
if(selectedAirportsList.length == 0) {
    selectedAirportsList = [0]
}
```

```js
let arcs = await sql([`
select r.*
from arcs r
join airports oa on oa.airport_id = r.min_airport_id
join airports da on da.airport_id = r.max_airport_id
where (r.min_airport_id in(${selectedAirportsList}) or r.max_airport_id in(${selectedAirportsList}))
${queryArcId}
`])
```

```js
var startTime = performance.now()
let arcAverages = await sql([`
    select
        r.arc_id
        , r.min_airport_id as origin_airport_id
        , r.max_airport_id as dest_airport_id
        , r.distance
        , avg(hr.average_fare) as average_fare
    from arcs r
    left join historical_routes hr using(arc_id)
    left join airports oa on oa.airport_id = r.min_airport_id
    left join airports da on da.airport_id = r.max_airport_id
    where r.min_airport_id in(${selectedAirportsList}) or r.max_airport_id in(${selectedAirportsList})
    group by 1,2,3,4
`])
```

```js
let routes = await sql([`
select hr.*
from historical_routes hr
join airports oa on oa.airport_id = hr.origin_airport_id
join airports da on da.airport_id = hr.dest_airport_id
where (hr.origin_airport_id in(${selectedAirportsList}) or hr.dest_airport_id in(${selectedAirportsList}))
${queryArcId}
`])
```

```js
const showDebug = view(Inputs.checkbox(["show raw data"]))
```

```js
if(showDebug.length > 0) {
    display(Inputs.table(airports))
    display(Inputs.table(arcs))
    display(Inputs.table(arcAverages))
    display(Inputs.table(routes))
    display(states_with_airports)
}
```
