"""
    geoborders(geom)

Extract the Geo borders of the region/geometry provided as input. 

**This function expects the output to be an instance of the `GeoBorders` type.**

By default, this function will try to extract the first field in the given type whose type is `GeoBorders`, so custom types do not need to add a method for this function explicitly if they do have a field that satisfies `field isa GeoBorders`.

Having a valid method of this function for custom geometries is sufficient to satisfy the `FastInGeometry` interface, as `polyareas` and `bboxes` have a default fallback which exploit this method.

See also [`polyareas`](@ref), [`bboxes`](@ref), [`FastInGeometry`](@ref).
"""
function geoborders(geom; exception = NotProvided())  
    exception = @fallback exception ArgumentError("No field of type `GeoBorders` was found in the provided input.\nYou need to define a custom method for the `geoborders` function.")
    getproperty_oftype(geom, GeoBorders; exception)::GeoBorders
end

# Basic functions for GeoBorders
"""
    polyareas([crs, ]geom)

Returns an iterable of the 2D `PolyArea`s associated to the input geometry defined over the Earth's surface.

It is possible to specify whether the returned `PolyArea`s should contains `Point` in either `LatLon` or `Cartesian` coordinates by passing `LatLon` or `Cartesian` as first argument.

If not provided, the crs defaults to `Cartesian`.

See also [`geoborders`](@ref), [`bboxes`](@ref), [`FastInGeometry`](@ref).

# Extended Help
When adding a method to this function to satisfy the `FastInGeometry` interface, it is currently only necessary to add a method with the following signature (as that is what is used in the fast point inclusion algorithm):
    polyareas(::Type{Cartesian}, custom_geom)

!!! note
    To ensure optimal speed for the inclusion algorithm, it is recommended that this function returns a pre-computed iterable of `PolyArea`s rather than computing it at runtime
"""
polyareas(::Type{LatLon}, b::GeoBorders) = b.latlon_polyareas
polyareas(::Type{Cartesian}, b::GeoBorders) = b.cart_polyareas

"""
    bboxes([crs, ]geom)

Returns an iterable of the 2D `Box`s associated to the input geometry defined over the Earth's surface.

It is possible to specify whether the returned `Box`s should contains `Point` in either `LatLon` or `Cartesian` coordinates by passing `LatLon` or `Cartesian` as first argument.

If not provided, the crs defaults to `Cartesian`.

See also [`geoborders`](@ref), [`polyareas`](@ref), [`FastInGeometry`](@ref).

# Extended Help
When adding a method to this function to satisfy the `FastInGeometry` interface, it is currently only necessary to add a method with the following signature (as that is what is used in the fast point inclusion algorithm):
    bboxes(::Type{Cartesian}, custom_geom)

!!! note
    To ensure optimal speed for the inclusion algorithm, it is recommended that this function returns a pre-computed iterable of `Box`s rather than computing it at runtime
"""
bboxes(::Type{LatLon}, b::GeoBorders) = b.latlon_bboxes
bboxes(::Type{Cartesian}, b::GeoBorders) = b.cart_bboxes

# Fallbacks
for nm in (:polyareas, :bboxes)
    # Version without CRS which defaults to LatLon
    @eval $nm(x) = $nm(Cartesian, x)
    # Version which tries to extract the `GeoBorders` field from the input
    @eval function $nm(T::VALID_CRS, x) 
        exception = ArgumentError($(string("The `GeoBorders` connected to the input could not be automatically extracted.\nConsider adding a custom method for `geoborders` or more explicitly for the called `", nm, "` function.")))
        return $nm(T, geoborders(x; exception))
    end
end

bboxes(T::VALID_CRS, dmn::FastInDomain) = Iterators.flatten(bboxes(T, el) for el in dmn)

# Methods for polyareas for types from Meshes. This are mostly used for the construction of GeoBorders objects
function polyareas(T::VALID_CRS, m::VALID_MULTI)
    f = T === LatLon ? latlon_geometry : cartesian_geometry
    Iterators.map(f, parent(m))
end
function polyareas(T::VALID_CRS, b::VALID_BOX)
	lo, hi = extrema(b) .|> to_raw_lonlat
    lo_lon, lo_lat = lo
    hi_lon, hi_lat = hi
    f = T === LatLon ? latlon_geometry : cartesian_geometry
    p = Ring([
        f(LatLon(hi_lat, lo_lon)),
        f(LatLon(hi_lat, hi_lon)),
        f(LatLon(lo_lat, hi_lon)),
        f(LatLon(lo_lat, lo_lon)),
    ]) |> PolyArea
    return (p, )
end
function polyareas(T::VALID_CRS, p::VALID_POLY)
    f = T === LatLon ? latlon_geometry : cartesian_geometry
    Iterators.map(f, (p, ))
end
function polyareas(T::VALID_CRS, dmn::Domain)
    Iterators.flatten(polyareas(T, el) for el in dmn)
end
