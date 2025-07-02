module GeoBasics

using BasicTypes: BasicTypes, valuetype, getproperty_oftype, @fallback, NotProvided, common_valuetype
using CoordRefSystems: CoordRefSystems, LatLon, Cartesian2D, WGS84Latest, Deg, Met, Cartesian
using Meshes: Meshes, Geometry, CRS, 🌐, Multi, 𝔼, Point, MultiPolygon, printelms, Ring, PolyArea, Box, GeometrySet, SubDomain, Domain, OrientationType, CW, CCW
using Meshes: measure, nvertices, nelements, paramdim, centroid, boundingbox, to, volume, element, discretize, rings, vertices, simplexify, pointify, convexhull, orientation, crs, segments, vertex
using CircularArrays: CircularArrays, CircularArray
using GeoPlottingHelpers: GeoPlottingHelpers, with_settings, extract_latlon_coords, extract_latlon_coords!, geo_plotly_trace, to_raw_lonlat, geom_iterable, crossing_latitude_flat
using Unitful: Unitful, ustrip, @u_str

include("types.jl")
export FastInGeometry, GeoBorders

include("interface.jl")
export polyareas, bboxes, geoborders

include("helpers.jl")

include("antimeridian.jl")

include("point_inclusion.jl")

end # module GeoBasics
