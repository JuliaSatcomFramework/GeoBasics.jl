const LATLON{T} = LatLon{WGS84Latest,Deg{T}}
const CART{T} = Cartesian2D{WGS84Latest,Met{T}}

const POINT_LATLON{T} = Point{🌐, LATLON{T}}
const POINT_CART{T} = Point{𝔼{2}, CART{T}}
const VALID_POINT{T} = Union{POINT_LATLON{T}, POINT_CART{T}}

const RING_LATLON{T} = Ring{🌐, LATLON{T}, CircularArray{POINT_LATLON{T}, 1, Vector{POINT_LATLON{T}}}}
const RING_CART{T} = Ring{𝔼{2}, CART{T}, CircularArray{POINT_CART{T}, 1, Vector{POINT_CART{T}}}}
const VALID_RING{T} = Union{RING_LATLON{T}, RING_CART{T}}

const POLY_LATLON{T} = PolyArea{🌐, LATLON{T}, RING_LATLON{T}, Vector{RING_LATLON{T}}}
const POLY_CART{T} = PolyArea{𝔼{2}, CART{T}, RING_CART{T}, Vector{RING_CART{T}}}
const VALID_POLY{T} = Union{POLY_LATLON{T}, POLY_CART{T}}

const MULTI_LATLON{T} = Multi{🌐, LATLON{T}, POLY_LATLON{T}}
const MULTI_CART{T} = Multi{𝔼{2}, CART{T}, POLY_CART{T}}
const VALID_MULTI{T} = Union{MULTI_LATLON{T}, MULTI_CART{T}}

const BOX_LATLON{T} = Box{🌐, LATLON{T}}
const BOX_CART{T} = Box{𝔼{2}, CART{T}}
const VALID_BOX{T} = Union{BOX_LATLON{T}, BOX_CART{T}}

"""
    FastInGeometry{T} <: Geometry{🌐,LATLON{T}}

Abstract type identifying geometries over Earth's surface where a fast custom algorithm for checking point inclusion is available. 

This package define a single concrete subtype [`GeoBorders`](@ref). Custom subtypes in downstream packages should in most cases contain a field with `GeoBorders` type.

# Extended Help
## Type Parameter
The type parameter `T` represents the machine precision of the underlying coordinates and is expected to be a subtype of `AbstractFloat` for the public API. This is in line with the public API of `Meshes.jl` and `CoordRefSystems.jl` that this package heavily relies on.

## Fast Inclusion Algorithm
The fast inclusion algorithm is quite simple and relies on having a bounding box defined for each polygon part of the `FastInGeometry`. The custom inclusion algorithm simply iterates through all polygons and prefilter points by checking inclusion in the bounding box (which is an almost free operation). This can have significant speed ups especially if the polygons have a lot of points.

For subtypes if `FastInGeometry`, the following methods are added to exploit the fast inclusion algorithm by default:
- `Base.in(p::VALID_POINT, g::FastInType)`
- `Base.in(p::LATLON, g::FastInType)`
where `VALID_POINT`, `LATLON` and `FastInType` are type aliases defined (but not exported) in the package.

## Interface
For custom subtypes of `FastInGeometry` that do not contain a field that is a subtype of `GeoBorders`, the following methods are expected to be implemented:
- [`geoborders`](@ref): This should return the `GeoBorders` instance associated to the input. If this method is implemented, all the others are not strictly needed
- [`polyareas`](@ref): This should return an iterable of `PolyArea` instances contained in the custom geometry. 
- [`bboxes`](@ref): This should return an iterable of `Box` instances representing the boundingboxes of each `PolyArea` returned by [`polyareas`](@ref).

See the docstrings of the respective methods for more details.
"""
abstract type FastInGeometry{T} <: Geometry{🌐,LATLON{T}} end

# Forwarding relevant meshes functions for the FastInGeometry type
const VALID_CRS = Union{Type{LatLon}, Type{Cartesian}}

const FastInGeometrySet{T, G <: FastInGeometry{T}} = GeometrySet{🌐, LATLON{T}, G}
const FastInSubDomain{T, G} = SubDomain{🌐, LATLON{T}, FastInGeometrySet{T, G}, Vector{Int}}
const FastInDomain{T, G} = Union{FastInSubDomain{T, G}, FastInGeometrySet{T, G}}
# This is the generic UnionAll containig all types where a fast point inclusion algorithm is defined
const FastInType{T, G <: FastInGeometry{T}} = Union{G, FastInDomain{T, G}}
