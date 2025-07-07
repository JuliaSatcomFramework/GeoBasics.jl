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
    FastInGeometry{T} <: Geometry{🌐, LatLon{WGS84Latest,Deg{T}}}

Abstract type identifying geometries over Earth's surface where a fast custom algorithm for checking point inclusion is available. 

This package define a single concrete subtype [`GeoBorders`](@ref). Custom subtypes in downstream packages should in most cases contain a field with `GeoBorders` type.

# Extended Help
## Type Parameter
The type parameter `T` represents the machine precision of the underlying coordinates and is expected to be a subtype of `AbstractFloat` for the public API. This is in line with the public API of `Meshes.jl` and `CoordRefSystems.jl` that this package heavily relies on.

## Fast Inclusion Algorithm
The fast inclusion algorithm is quite simple and relies on having a bounding box defined for each polygon part of the `FastInGeometry`. The custom inclusion algorithm simply iterates through all polygons and prefilter points by checking inclusion in the bounding box (which is an almost free operation). This can have significant speed ups especially if the polygons have a lot of points.

The following methods are added to `Base.in` to exploit the fast inclusion algorithm for custom subtypes adhering to the `FastInGeometry` (or `FastInDomain`) interface:
- `Base.in(p, x::FastInGeometry)`
- `Base.in(p, x::VALID_DOMAINS)`

!!! note "Input Types"
    The point `p` provided as input is internally converted to within the function by using `to_cart_point(valuetype(x), p)`, so custom types representing points on the Earth's surface can also be used with `Base.in` by having a valid method for `to_cart_point` or to `GeoPlottingHelpers.to_raw_lonlat` which the former falls back to.

    The `VALID_DOMAINS` type alias encompasses `FastInDomain`, `GeometrySet` with `FastInGeometry` elements and `SubDomain`s of either of the previous domains.

## Interface
For custom subtypes of `FastInGeometry` that do not contain a field that is a subtype of `GeoBorders`, the following methods are expected to be implemented:
- [`geoborders`](@ref): This should return the `GeoBorders` instance associated to the input. If this method is implemented, all the others are not strictly needed
- [`polyareas`](@ref): This should return an iterable of `PolyArea` instances contained in the custom geometry. 
- [`bboxes`](@ref): This should return an iterable of `Box` instances representing the boundingboxes of each `PolyArea` returned by [`polyareas`](@ref).

See the docstrings of the respective methods for more details.
"""
abstract type FastInGeometry{T} <: Geometry{🌐,LATLON{T}} end

"""
    FastInDomain{T} <: Domain{🌐, LatLon{WGS84Latest, Deg{T}}}

Abstract type representing a domain of `FastInGeometry{T}` geometries.

This type can be subtypes by custom types that represent domains and want to participate in the `FastInGeometry` interface for fast point inclusion.

See also: [`FastInGeometry`](@ref), [`to_gset`](@ref)

# Extended Help
## Type Parameter
The type parameter `T` represents the machine precision of the underlying coordinates and is expected to be a subtype of `AbstractFloat` for the public API. This is in line with the public API of `Meshes.jl` and `CoordRefSystems.jl` that this package heavily relies on.

## Fast Inclusion Algorithm
The fast inclusion algorithm is quite simple and relies on having a bounding box defined for each polygon part of the `FastInGeometry`. The custom inclusion algorithm simply iterates through all polygons and prefilter points by checking inclusion in the bounding box (which is an almost free operation). This can have significant speed ups especially if the polygons have a lot of points.

The following methods are added to `Base.in` to exploit the fast inclusion algorithm for custom subtypes adhering to the `FastInGeometry` (or `FastInDomain`) interface:
- `Base.in(p, x::FastInGeometry)`
- `Base.in(p, x::VALID_DOMAINS)`

!!! note "Input Types"
    The point `p` provided as input is internally converted to within the function by using `to_cart_point(valuetype(x), p)`, so custom types representing points on the Earth's surface can also be used with `Base.in` by having a valid method for `to_cart_point` or to `GeoPlottingHelpers.to_raw_lonlat` which the former falls back to.

    The `VALID_DOMAINS` type alias encompasses `FastInDomain`, `GeometrySet` with `FastInGeometry` elements and `SubDomain`s of either of the previous domains.

## Interface
To properly work for fast point inclusion, the custom subtypes of `FastInDomain` need as a minimum to add valid methods to the following two functions from Meshes.jl:
- `Meshes.nelements(custom_domain)`: This should return the number of geometries within the domain
- `Meshes.element(custom_domain, ind)`: This should return the `ind`-th geometry from the domain
"""
abstract type FastInDomain{T} <: Domain{🌐,LATLON{T}} end

# Forwarding relevant meshes functions for the FastInGeometry type
const VALID_CRS = Union{Type{LatLon}, Type{Cartesian}}

const FastInGeometrySet{T, G <: FastInGeometry{T}} = GeometrySet{🌐, LATLON{T}, G}
const FastInDomainUnion{T} = Union{FastInDomain{T}, FastInGeometrySet{T}}
const FastInSubDomain{T, D <: FastInDomainUnion{T}, I <: AbstractVector{Int}} = SubDomain{🌐, LATLON{T}, D, I}

"""
    VALID_DOMAINS{T}
This is the union representing all domains for which fast point inclusion algorithm is defined. It contains both [`FastInDomain`](@ref) defined in this package as well as a plain `GeometrySet` of `FastInGeometry` objects as well as `SubDomain`s of either of the previous domains
"""
const VALID_DOMAINS{T} = Union{FastInDomainUnion{T}, FastInSubDomain{T}}