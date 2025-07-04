"""
    GeoBorders{T} <: FastInGeometry{T}

Basic geometry used to represent borders of countries/regions on Earth's
surface, supporting a fast algorithm for checking point inclusion.

The polygons contained within a `GeoBorders` object are expected to satisfy the following two conditions (mainly in line with the GeoJSON standard):
- The polygons must not cross the antimeridian (the 180° latitude line). If a polygon should encompass a region crossing the antimeridian, it shall be split into multiple polygons.
- Each polygon must have its exterior/outer ring following a counter-clockwise orientation, and all of its interior rings (holes) having a clockwise orientation.

The parametric type `T` represent the machine precision of the underlying coordinates and should be a subtype of `AbstractFloat`.

# Constructors
    GeoBorders{T}(inp; fix_antimeridian_crossing)
    GeoBorders(inp; fix_antimeridian_crossing)

Take an input object which can be a `Geometry`, `Domain` or a `Vector` (of geometries) and returns the `GeoBorders` instance containing all the polyareas contained in the provided object, optionally forcing the machine precision of all underlying coordinates to `T <: AbstractFloat`

For input geometries of the following plain types from `Meshes.jl`:
- `Multi`
- `PolyArea`
- `Box`
the constructor will ensure the two conditions specified above, by eventually fixing both antimeridian crossings and ensuring correct orientation of polygons rings.

For input geometries that are already satisfying the `FastInGeometry` interface, the constructor will simply extract the `polyareas` assuming they are already in a correct form.

The `fix_antimeridian_crossing` keyword argument is only respected for plain Meshes geometries and can be set to `false` to disable fixing the antimeridian crossing by splitting polygons. This can be useful in some cases where polygons are purposedly made of long segments (spanning more than 180° of longitude) which would otherwise be split into multiple polyareas.

When the input is a single `Geometry` or `Domain`, the type parameter `T` can be omitted from the constructor and will be inferred using `valuetype(input)`. **When using a vector of geometries as input to the function, the machine precision `T` must be provided explicitly.**

See also [`FastInGeometry`](@ref), [`polyareas`](@ref), [`bboxes`](@ref), [`geoborders`](@ref).
"""
struct GeoBorders{T} <: FastInGeometry{T}
    latlon_polyareas::Vector{POLY_LATLON{T}}
    latlon_bboxes::Vector{BOX_LATLON{T}}
    cart_polyareas::Vector{POLY_CART{T}}
    cart_bboxes::Vector{BOX_CART{T}}
    function GeoBorders{T}(latlon_polyareas::Vector{POLY_LATLON{T}}, latlon_bboxes::Vector{BOX_LATLON{T}}, cart_polyareas::Vector{POLY_CART{T}}, cart_bboxes::Vector{BOX_CART{T}}) where T
        all((latlon_polyareas, latlon_bboxes, cart_polyareas, cart_bboxes)) do inp
            length(inp) == length(latlon_polyareas)
        end || throw(ArgumentError("All input vectors must have the same length"))
        new{T}(latlon_polyareas, latlon_bboxes, cart_polyareas, cart_bboxes)
    end
end
function GeoBorders{T}(geoms::AbstractVector; fix_antimeridian_crossing::Optional{Bool} = NotProvided()) where T <: AbstractFloat
    latlon_polyareas = POLY_LATLON{T}[]
    cart_polyareas = POLY_CART{T}[]
    latlon_bboxes = BOX_LATLON{T}[]
    cart_bboxes = BOX_CART{T}[]
    for geom in geoms
        latlon, cart = _geoborders_inputs(geom; fix_antimeridian_crossing)
        for (latp, cartp) in zip(latlon, cart)
            latp = latlon_geometry(T, latp)
            cartp = cartesian_geometry(T, cartp)
            push!(latlon_polyareas, latp)
            push!(cart_polyareas, cartp)
            push!(latlon_bboxes, boundingbox(latp))
            push!(cart_bboxes, boundingbox(cartp))
        end
    end
    # We remove duplicate polyareas
    idxs = eachindex(latlon_polyareas)
    # Unique needs both `isequal` and `hash` to be defined to work, so it does not remove duplicate polyareas. We do unique based on the polyarea vertices as that works
    unique_idxs = unique(i -> vertices(latlon_polyareas[i]), idxs)
    if length(unique_idxs) < length(idxs)
        # We remove entries for related to duplicate polyareas
        latlon_polyareas = keepat!(latlon_polyareas, unique_idxs)
        latlon_bboxes = keepat!(latlon_bboxes, unique_idxs)
        cart_polyareas = keepat!(cart_polyareas, unique_idxs)
        cart_bboxes = keepat!(cart_bboxes, unique_idxs)
    end
    return GeoBorders{T}(latlon_polyareas, latlon_bboxes, cart_polyareas, cart_bboxes)
end
GeoBorders{T}(geometry::Geometry; fix_antimeridian_crossing::Optional{Bool} = NotProvided()) where T <: AbstractFloat = GeoBorders{T}([geometry]; fix_antimeridian_crossing)
GeoBorders{T}(dmn::Domain; fix_antimeridian_crossing::Optional{Bool} = NotProvided()) where T <: AbstractFloat = GeoBorders{T}(collect(dmn); fix_antimeridian_crossing)
GeoBorders(obj::Union{Geometry, Domain}; fix_antimeridian_crossing::Optional{Bool} = NotProvided()) = GeoBorders{common_valuetype(AbstractFloat, Float32, obj)}(obj; fix_antimeridian_crossing)



### Getter
"""
    geoborders(geom)

Extract the Geo borders of the region/geometry provided as input. 

**This function expects the output to be an instance of the `GeoBorders` type.**

By default, this function will try to extract the first field in the given type whose type is `GeoBorders`, so custom types do not need to add a method for this function explicitly if they do have a field that satisfies `field isa GeoBorders`.

Having a valid method of this function for custom geometries is sufficient to satisfy the `FastInGeometry` interface, as `polyareas` and `bboxes` have a default fallback which exploit this method.

See also [`polyareas`](@ref), [`bboxes`](@ref), [`FastInGeometry`](@ref), [`to_multi`](@ref).
"""
function geoborders(geom; exception = NotProvided())  
    exception = @fallback exception ArgumentError("No field of type `GeoBorders` was found in the provided input.\nYou need to define a custom method for the `geoborders` function.")
    getproperty_oftype(geom, GeoBorders; exception)::GeoBorders
end

# Constructor helper
# This function is used to extract both cart and latlon polyareas from a Geometry object supporting PolyAreas
function _geoborders_inputs(geom::Union{VALID_MULTI, VALID_POLY, VALID_BOX}; fix_antimeridian_crossing::Optional{Bool} = NotProvided())
    T = valuetype(geom)
    cart_polyareas = collect(polyareas(Cartesian, geom; nowarn = true))
    fix_antimeridian_crossing = @fallback fix_antimeridian_crossing true
    cart_polyareas = if fix_antimeridian_crossing
        split_antimeridian(cart_polyareas)
    else
        # If we don't fix the antimeridian, we ensure that the orientation is consistent
        map(fix_orientation, cart_polyareas)
    end
    latlon_polyareas = map(latlon_geometry(T), cart_polyareas)
    return latlon_polyareas, cart_polyareas
end
function _geoborders_inputs(geom; fix_antimeridian_crossing::Optional{Bool} = NotProvided())
    if fix_antimeridian_crossing isa Bool
        @warn "The `fix_antimeridian_crossing` is ignored when working with geometries that subtype `FastInGeometry`." maxlog = 1
    end
    cart_polyareas = polyareas(Cartesian, geom) |> collect
    latlon_polyareas = polyareas(LatLon, geom) |> collect
    return latlon_polyareas, cart_polyareas
end