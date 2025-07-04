# These return just the longitude or the latitude without a unit
get_lon(p) = first(to_raw_lonlat(p))
get_lat(p) = last(to_raw_lonlat(p))

"""
    to_cart_point(T::Type{<:AbstractFloat}, obj)
    to_cart_point(T::Type{<:AbstractFloat})
    to_cart_point(obj)

Extracts the lat/lon coordinates associated to input `obj` and return them as a `Point` from Meshes with `Cartesian2D{WGS84Latest}` as `CRS` and optionally forcing the underlying machine precision of the coordinates to `T`.

The second method simply returns `Base.Fix1(to_cart_point, T)`.

The third method, will try to extract the machine precision from `obj` by calling `BasicTypes.valuetype(obj)`.

!!! note
    This function exploits `GeoPlottingHelpers.to_row_lonlat` internally so any object that has a valid method for `to_row_lonlat` will work as input.

## Examples

```jldoctest
julia> using GeoBasics

julia> to_cart_point(Float32, (10, 20)) # Force precision to `Float32`
Point with Cartesian{WGS84Latest} coordinates
├─ x: 10.0f0 m
└─ y: 20.0f0 m

julia> to_cart_point(LatLon(20,10)) # Extract precision from `LatLon` input
Point with Cartesian{WGS84Latest} coordinates
├─ x: 10.0 m
└─ y: 20.0 m
```

See also [`to_latlon_point`](@ref).
"""
function to_cart_point(T::Type{<:AbstractFloat}, p)
    lon, lat = to_raw_lonlat(p) .|> T
    return Cartesian{WGS84Latest}(lon, lat) |> Point
end

"""
    to_latlon_point(T::Type{<:AbstractFloat}, obj)
    to_latlon_point(T::Type{<:AbstractFloat})
    to_latlon_point(obj)

Extracts the lat/lon coordinates associated to input `obj` and return them as a `Point` from Meshes with `LatLon{WGS84Latest}` as `CRS` and optionally forcing the underlying machine precision of the coordinates to `T`.

The second method simply returns `Base.Fix1(to_latlon_point, T)`.

The third method, will try to extract the machine precision from `obj` by calling `BasicTypes.valuetype(obj)`.

!!! note
    This function exploits `GeoPlottingHelpers.to_row_lonlat` internally so any object that has a valid method for `to_row_lonlat` will work as input.

## Examples

```jldoctest
julia> using GeoBasics

julia> to_latlon_point(Float32, (10, 20)) # Force precision to `Float32`
Point with GeodeticLatLon{WGS84Latest} coordinates
├─ lat: 20.0f0°
└─ lon: 10.0f0°

julia> to_latlon_point(LatLon(20,10)) # Extract precision from `LatLon` input
Point with GeodeticLatLon{WGS84Latest} coordinates
├─ lat: 20.0°
└─ lon: 10.0°
```

See also [`to_cart_point`](@ref).
"""
function to_latlon_point(T::Type{<:AbstractFloat}, p)
    lon, lat = to_raw_lonlat(p) .|> T
    return LatLon{WGS84Latest}(lat, lon) |> Point
end

for name in (:to_cart_point, :to_latlon_point)
    @eval $name(T::Type{<:AbstractFloat}) = Base.Fix1($name, T)
    @eval $name(x) = $name(common_valuetype(AbstractFloat, Float32, x), x)
end

## Enforcing or changing a geometry from LatLon to Cartesian or vice versa
"""
    cartesian_geometry([T::Type{<:AbstractFloat}, ] geom)
    cartesian_geometry(T::Type{<:AbstractFloat})

Convert geometries from LatLon to Cartesian coordinate systems, optionally changing the underlying machine type of the points to `T`

The second method simply returns a function that applies the conversion with the provided machine type to any geometry.

## Arguments
- `T::Type{<:AbstractFloat}`: The desired machine type of the points in the output geometry. If not provided, it will default to the machine type of the input geometry.
- `geom`: The geometry to convert, which can be an arbitrary Geometry either in LatLon{WGS84Latest} or Cartesian2D{WGS84Latest} coordinates.

## Returns
- The converted geometry, with points of type `POINT_CART{T}`.
"""
function cartesian_geometry(T::Type{<:AbstractFloat}, b::Union{BOX_LATLON, BOX_CART})
    b isa BOX_CART{T} && return b
    f = to_cart_point(T)
    return BOX_CART{T}(f(b.min), f(b.max))
end
function cartesian_geometry(T::Type{<:AbstractFloat}, ring::Union{RING_CART, RING_LATLON})
    ring isa RING_CART{T} && return ring
    map(to_cart_point(T), vertices(ring)) |> Ring
end
function cartesian_geometry(T::Type{<:AbstractFloat}, poly::Union{POLY_LATLON, POLY_CART})
    poly isa POLY_CART{T} && return poly
    map(cartesian_geometry(T), rings(poly)) |> splat(PolyArea)
end
function cartesian_geometry(T::Type{<:AbstractFloat}, multi::Union{MULTI_LATLON, MULTI_CART})
    multi isa MULTI_CART{T} && return multi
    map(cartesian_geometry(T), parent(multi)) |> Multi
end
cartesian_geometry(T::Type{<:AbstractFloat}) = Base.Fix1(cartesian_geometry, T)
cartesian_geometry(x) = cartesian_geometry(valuetype(x), x)

"""
    latlon_geometry([T::Type{<:AbstractFloat}, ] geom)
    latlon_geometry(T::Type{<:AbstractFloat})

Convert geometries from Cartesian to LatLon coordinate systems, optionally changing the underlying machine type of the points to `T`

The second method simply returns a function that applies the conversion with the provided machine type to any geometry. 

## Arguments
- `T::Type{<:AbstractFloat}`: The desired machine type of the points in the output geometry. If not provided, it will default to the machine type of the input geometry.
- `geom`: The geometry to convert, which can be an arbitrary Geometry either in LatLon{WGS84Latest} or Cartesian2D{WGS84Latest} coordinates.

## Returns
- The converted geometry, with points of type `POINT_LATLON{T}`.

"""
function latlon_geometry(T::Type{<:AbstractFloat}, b::Union{BOX_LATLON, BOX_CART})
    b isa BOX_LATLON{T} && return b
    f = to_latlon_point(T)
    return BOX_LATLON{T}(f(b.min), f(b.max))
end
function latlon_geometry(T::Type{<:AbstractFloat}, ring::Union{RING_CART, RING_LATLON})
    ring isa RING_LATLON{T} && return ring
    map(to_latlon_point(T), vertices(ring)) |> Ring
end
function latlon_geometry(T::Type{<:AbstractFloat}, poly::Union{POLY_LATLON, POLY_CART})
    poly isa POLY_LATLON{T} && return poly
    map(latlon_geometry(T), rings(poly)) |> splat(PolyArea)
end
function latlon_geometry(T::Type{<:AbstractFloat}, multi::Union{MULTI_LATLON, MULTI_CART})
    multi isa MULTI_LATLON{T} && return multi
    map(latlon_geometry(T), parent(multi)) |> Multi
end
latlon_geometry(T::Type{<:AbstractFloat}) = Base.Fix1(latlon_geometry, T)
latlon_geometry(x) = latlon_geometry(valuetype(x), x)

"""
    to_multi(crs, geom)
    to_multi(crs)

Returns a `Multi` object containing the `PolyArea`s associated to the input geometry and returned by calling `polyareas(crs, geom)`.

When called with just the crs type as argument, it simply returns `Base.Fix1(to_multi, crs)`.

This is intended to simplify the generation of a plain `Multi` object for further processing using standard functions from `Meshes.jl`.

GeoBasics explicitly avoids extending methods from `Meshes.jl` on `FastInGeometry` objects to encourage users to explicitly decide whether to use the `LatLon` or `Cartesian` CRS instead of *magically* taking a decision on their behalf.

!!! note
    The computational cost of this function for types which have a valid method for [`geoborders`](@ref) is almost free (~1-2 nanoseconds).

See also [`geoborders`](@ref), [`polyareas`](@ref), [`bboxes`](@ref), [`FastInGeometry`](@ref). 
"""
to_multi(T::VALID_CRS, geom) = Multi(polyareas(T, geom))
to_multi(T::VALID_CRS) = Base.Fix1(to_multi, T)

#= 
Methods for polyareas for types from Meshes. This are mostly used for the construction of GeoBorders objects
=#
warn_internal_polyareas() = @warn "The `polyareas` function for `Multi`, `PolyArea` and `Box` objects is considered internal. You can suppress this warning by calling the function with the `nowarn` keyword argument set to true." maxlog = 1
function polyareas(T::VALID_CRS, m::VALID_MULTI; nowarn = false)
    nowarn || warn_internal_polyareas()
    f = T === LatLon ? latlon_geometry : cartesian_geometry
    Iterators.map(f, parent(m))
end
function polyareas(T::VALID_CRS, b::VALID_BOX; nowarn = false)
    nowarn || warn_internal_polyareas()
	lo, hi = extrema(b) .|> to_raw_lonlat
    lo_lon, lo_lat = lo
    hi_lon, hi_lat = hi
    Δlon = hi_lon - lo_lon
    # We make a range because with a Box we might have a valid segment longer than 180° of longitude, which would otherwise be split into multiple polyareas
    lon_range = range(lo_lon, hi_lon; length = floor(Int, Δlon / 180) + 2)
    f = T === LatLon ? to_latlon_point : to_cart_point
    p = Ring(vcat(
        map(lon -> f(LatLon(lo_lat, lon)), lon_range),
        map(lon -> f(LatLon(hi_lat, lon)), reverse(lon_range)),
    )) |> PolyArea
    return (p, )
end
function polyareas(T::VALID_CRS, p::VALID_POLY; nowarn = false)
    nowarn || warn_internal_polyareas()
    f = T === LatLon ? latlon_geometry : cartesian_geometry
    Iterators.map(f, (p, ))
end

