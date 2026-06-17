module GeoBasics

using BasicTypes: BasicTypes, valuetype, getproperty_oftype, @fallback, NotProvided, common_valuetype, Optional, enforce_unit
using Base.ScopedValues: ScopedValue
using CoordRefSystems: CoordRefSystems, LatLon, Cartesian2D, WGS84Latest, Deg, Met, Cartesian
using Meshes: Meshes, Geometry, CRS, 🌐, Multi, 𝔼, Point, MultiPolygon, Ring, PolyArea, Box, GeometrySet, SubDomain, Domain, OrientationType, CW, CCW
using Meshes: boundingbox, rings, vertices, orientation, crs, segments, vertex
using CircularArrays: CircularArrays, CircularArray
using GeoPlottingHelpers: GeoPlottingHelpers, with_settings, extract_latlon_coords, extract_latlon_coords!, geo_plotly_trace, to_raw_lonlat, geom_iterable, crossing_latitude_flat
using Unitful: Unitful, ustrip, @u_str

# Exports from dependencies
export LatLon, Cartesian # From CoordRefSystems.jl
export @u_str # From Unitful.jl

include("constants.jl")

include("types.jl")
export FastInGeometry, FastInDomain, GeoBorders

include("geoborders.jl")

include("interface.jl")
export polyareas, bboxes, geoborders

include("deps_interface.jl")

include("helpers.jl")
export to_cartesian_point, to_latlon_point, to_point, to_multi, to_gset, get_raw_lon, get_raw_lat, get_lon, get_lat

include("antimeridian.jl")

include("point_inclusion.jl")

include("show.jl")

include("distance_resampling.jl")
export distance_resample, distance_resample!

end # module GeoBasics
