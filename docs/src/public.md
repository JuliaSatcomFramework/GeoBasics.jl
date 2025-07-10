# Public API

## Types
```@docs
FastInGeometry
GeoBorders
FastInDomain
```

## Interface Functions
```@docs
geoborders
polyareas
bboxes
```

## Helpers
```@docs
to_multi
to_gset
to_cartesian_point
to_latlon_point
to_point
get_raw_lat
get_raw_lon
get_lat
get_lon
Base.keepat!(::GeoBorders, ::Any)
Base.deleteat!(::GeoBorders, ::Any)
```