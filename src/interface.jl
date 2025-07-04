function geoborders end # Defined in geoborders.jl

# Basic functions for GeoBorders
"""
    polyareas(crs, geom)
    polyareas(crs)

Returns an iterable of the 2D `PolyArea`s associated to the input geometry defined over the Earth's surface.

# Arguments
- `crs::Union{Type{LatLon}, Type{Cartesian}}`: Specifies whether the returned vector of `PolyArea` elements should have `LatLon{WGS84LatLon}` or `Cartesian2D{WGS84Latest}` as underlying CRS.
- `geom`: The input geometry. 

When only the `crs` argument is provided, the function simply returns `Base.Fix1(polyareas, crs)`.

See also [`geoborders`](@ref), [`bboxes`](@ref), [`FastInGeometry`](@ref), [`to_multi`](@ref).

# Extended Help

When implementing the `FastInGeometry` interface for types where `geoborders` does not return a valid `GeoBorders` object (or for which a custom implementation of `polyareas` is preferred), one should implement the following two methods:
- `polyareas(::Type{Cartesian}, custom_geom)`
- `polyareas(::Type{LatLon}, custom_geom)`


!!! note
    To ensure optimal speed for the inclusion algorithm, it is recommended that this function returns a pre-computed iterable of `PolyArea`s rather than computing it at runtime, at least for the method with `Cartesian` as crs as that is used by the fast point inclusion algorithm.
"""
polyareas(::Type{LatLon}, b::GeoBorders) = b.latlon_polyareas
polyareas(::Type{Cartesian}, b::GeoBorders) = b.cart_polyareas

"""
    bboxes(crs, geom)
    bboxes(crs)

Returns an iterable of the 2D `Box`s associated to the input geometry defined over the Earth's surface.

# Arguments
- `crs::Union{Type{LatLon}, Type{Cartesian}}`: Specifies whether the returned vector of `Box` elements should have `LatLon{WGS84LatLon}` or `Cartesian2D{WGS84Latest}` as underlying CRS.
- `geom`: The input geometry.

When only the `crs` argument is provided, the function simply returns `Base.Fix1(bboxes, crs)`.

See also [`geoborders`](@ref), [`polyareas`](@ref), [`FastInGeometry`](@ref).

# Extended Help
When implementing the `FastInGeometry` interface for types where `geoborders` does not return a valid `GeoBorders` object (or for which a custom implementation of `bboxes` is preferred), one should implement the following two methods:
- `bboxes(::Type{Cartesian}, custom_geom)`
- `bboxes(::Type{LatLon}, custom_geom)`

!!! note
    To ensure optimal speed for the inclusion algorithm, it is recommended that this function returns a pre-computed iterable of `Box`s rather than computing it at runtime, at least for the method with `Cartesian` as crs as that is used by the fast point inclusion algorithm.
"""
bboxes(::Type{LatLon}, b::GeoBorders) = b.latlon_bboxes
bboxes(::Type{Cartesian}, b::GeoBorders) = b.cart_bboxes

# Fallbacks
for nm in (:polyareas, :bboxes)
    # Function with CRS as only argument
    @eval $nm(T::VALID_CRS) = Base.Fix1($nm, T)
    # Version which tries to extract the `GeoBorders` field from the input
    @eval function $nm(T::VALID_CRS, x) 
        exception = ArgumentError($(string("The `GeoBorders` connected to the input could not be automatically extracted.\nConsider adding a custom method for `geoborders` or more explicitly for the called `", nm, "` function.")))
        return $nm(T, geoborders(x; exception))
    end
end
