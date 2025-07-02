# These return just the longitude or the latitude without a unit
get_lon(p) = first(to_raw_lonlat(p))
get_lat(p) = last(to_raw_lonlat(p))

function to_cart_point(T::Type{<:AbstractFloat}, p)
    lon, lat = to_raw_lonlat(p) .|> T
    return Cartesian{WGS84Latest}(lon, lat) |> Point
end

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
