"""
    in_exit_early(p, polys, bboxes)
Function that checks if a point is contained one of the polyareas in vector `polys` which are associated to the bounding boxes in vector `bboxes`.

Both `polys` and `bboxes` must be iterables of the same size, with element type `POLY_CART` and `BBOX_CART` respectively (both are type aliases of `Meshes.jl` types defined within `GeoBasics.jl`).

This function is basically pre-filtering points by checking inclusion in the bounding box which is significantly faster than checking for the polyarea itself, especially if the polyareas is composed by a large number of points.

See also [`polyareas`](@ref), [`bboxes`](@ref), [`FastInGeometry`](@ref), [`geoborders`](@ref), [`GeoBorders`](@ref).
"""
function in_exit_early(p, polys, bboxes)
    T = first(polys) |> valuetype
    p = to_cart_point(T, p)
    for (poly, box) in zip(polys, bboxes)
        p in box || continue
        p in poly && return true
    end
    return false
end
# This is a catchall method for extension for other types
in_exit_early(p, x) = in_exit_early(p, polyareas(Cartesian, x), bboxes(Cartesian, x))

Base.in(p::Union{VALID_POINT, LATLON}, x::FastInType) = in_exit_early(p, x)