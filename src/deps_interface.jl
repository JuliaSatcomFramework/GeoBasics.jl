GeoPlottingHelpers.geom_iterable(geom::FastInGeometry) = polyareas(LatLon, geom)

### We explicitly avoid implementing the Meshes interface for FastInGeometry objects here to encourage users to explicitly decide whether to use the LatLon or Cartesian CRS both available in the underlying geometry.

Meshes.paramdim(geom::FastInGeometry) = return 2


### Base methods ###
"""
    Base.keepat!(gb::GeoBorders, inds)

Keep the polyareas and bboxes (for both CRSs) associated to the provided indices `inds` from the `GeoBorders` object.

!!! note
    This is simply calling `Base.keepat!` with provided indices to all the arrays of polyareas/bboxes contained in `GeoBorders`. It is just intended as an easier and more consistent way to remove specific elements from `GeoBorders` instances, as removal have to be done from all the underlying arrays at the same time.
"""
function Base.keepat!(gb::GeoBorders, inds)
    props = (gb.latlon_polyareas, gb.cart_polyareas, gb.latlon_bboxes, gb.cart_bboxes)
    for prop in props
        keepat!(prop, inds)
    end
    return gb
end
"""
    Base.deleteat!(gb::GeoBorders, inds)

Remove the polyareas and bboxes (for both CRSs) associated to the provided indices `inds` from the `GeoBorders` object.

!!! note
    This is simply calling `Base.deleteat!` with provided indices to all the arrays of polyareas/bboxes contained in `GeoBorders`. It is just intended as an easier and more consistent way to remove specific elements from `GeoBorders` instances, as removal have to be done from all the underlying arrays at the same time.
"""
function Base.deleteat!(gb::GeoBorders, inds)
    props = (gb.latlon_polyareas, gb.cart_polyareas, gb.latlon_bboxes, gb.cart_bboxes)
    for prop in props
        deleteat!(prop, inds)
    end
    return gb
end

function Base.:(==)(g1::FastInGeometry, g2::FastInGeometry)
    return all(zip(polyareas(LatLon, g1), polyareas(LatLon, g2))) do (p1, p2)
        p1 == p2
    end
end