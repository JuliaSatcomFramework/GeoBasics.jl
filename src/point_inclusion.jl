# This is the actual method with the actual implementation. It expects a cartesian point already as input and expects all polyareas and bboxes provided to have the same `valuetype` T as the input point
function in_exit_early(p::POINT_CART{T}, polys, bboxes) where T
    # Note that t
    for (poly, box) in zip(polys, bboxes)
        p in box || continue
        p in poly && return true
    end
    return false
end
"""
    in_exit_early(p, geom)

Function that checks if a point is contained within the geometry `geom` using the fast point inclusion algorithm that relies on availability `geom` has valid methods for [`polyareas`](@ref) and [`bboxes`](@ref).

It is expected that the input `geom` also has a valid method for `BasicTypes.valuetype` in order to extract the `T` type parameter to convert `p` to a valid cartesian point.

!!! note
    This method is basically pre-filtering points by checking inclusion in the bounding box which is significantly faster than checking for the polyarea itself, especially if the polyareas is composed by a large number of points.

See also [`polyareas`](@ref), [`bboxes`](@ref), [`FastInGeometry`](@ref), [`geoborders`](@ref), [`GeoBorders`](@ref).
"""
in_exit_early(p, x) = in_exit_early(to_cartesian_point(p), polyareas(Cartesian, x), bboxes(Cartesian, x))
in_exit_early(p, dmn::VALID_DOMAINS) = any(el -> in_exit_early(p, el), dmn)

# Basic methods
Base.in(p, geom::FastInGeometry) = in_exit_early(p, geom)
Base.in(p, dmn::VALID_DOMAINS) = in_exit_early(p, dmn)

# Additional methods to resolve ambiguities from Meshes.jl
Base.in(p::Point, geom::FastInGeometry) = in_exit_early(p, geom)
Base.in(p::Point, dmn::VALID_DOMAINS) = in_exit_early(p, dmn)
