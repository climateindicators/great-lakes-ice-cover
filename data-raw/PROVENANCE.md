# Provenance

Every file in this directory is reproduced unmodified from EPA's published
indicator page and its per-figure data downloads. To update the data, replace the
file and rerun `Rscript R/build_data.R`.

## Indicator page

- `source-page.html`  \
  <https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-great-lakes-ice-cover/index.html>  \
  sha256 `fd59ecbaff5591a170d4f35ef8933952de3a583bfab697d5bc10679cad73b3b1`

Technical documentation: <https://19january2025snapshot.epa.gov/sites/default/files/2021-04/documents/great-lakes-ice_td.pdf>

## Figure data

- `great-lakes-ice_fig-1.csv`  \
  <https://19january2025snapshot.epa.gov/sites/default/files/2021-04/great-lakes-ice_fig-1.csv>  \
  sha256 `088e4e0a98940370d315b8eecc72b5854c8bc826e39c52b5195e329495b7a57a`  \
  encoding UTF-8-BOM, 48 data rows, columns: `Year`, `Erie`, `Huron`, `Michigan`, `Ontario`, `Superior`, `All Lakes`  \
  title: Figure 1. Maximum Ice-Covered Area in the Great Lakes, 1973–2020  \
  data source: NOAA, 2021; web update: April 2021; units: maximum percent ice cover

- `great-lakes-ice_fig-2.csv`  \
  <https://19january2025snapshot.epa.gov/sites/default/files/2021-04/great-lakes-ice_fig-2.csv>  \
  sha256 `e141df51e2a59dbc23f55bd680f2d891bf8295794a7d4191fe28e68093abb6c5`  \
  encoding UTF-8-BOM, 48 data rows, columns: `Year`, `Erie`, `Huron`, `Michigan`, `Ontario`, `Superior`  \
  title: Figure 2. Duration of Ice Cover in the Great Lakes, 1973–2020  \
  data source: NOAA, 2021; web update: April 2021; units: number of days with more than 5% ice cover

- **Figure 3** has no data download on EPA's page. The narrative carries the caption; there is nothing to build.
