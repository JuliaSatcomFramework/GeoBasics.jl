module GeoBasics

using BasicTypes: BasicTypes, valuetype, getproperty_oftype, @fallback, NotProvided, common_valuetype, Optional
using CoordRefSystems: CoordRefSystems, LatLon, Cartesian2D, WGS84Latest, Deg, Met, Cartesian
using Meshes: Meshes, Geometry, CRS, 🌐, Multi, 𝔼, Point, MultiPolygon, Ring, PolyArea, Box, GeometrySet, SubDomain, Domain, OrientationType, CW, CCW
using Meshes: boundingbox, rings, vertices, orientation, crs, segments, vertex
using CircularArrays: CircularArrays, CircularArray
using GeoPlottingHelpers: GeoPlottingHelpers, with_settings, extract_latlon_coords, extract_latlon_coords!, geo_plotly_trace, to_raw_lonlat, geom_iterable, crossing_latitude_flat
using Unitful: Unitful, ustrip, @u_str

# Exports from dependencies
export LatLon, Cartesian # From CoordRefSystems.jl
export @u_str # From Unitful.jl

include("types.jl")
export FastInGeometry, GeoBorders

include("geoborders.jl")

include("interface.jl")
export polyareas, bboxes, geoborders

include("deps_interface.jl")

include("helpers.jl")
export to_cart_point, to_latlon_point, to_multi

include("antimeridian.jl")

include("point_inclusion.jl")

include("show.jl")

end # module GeoBasics
