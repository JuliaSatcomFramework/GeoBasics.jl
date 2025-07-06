GeoPlottingHelpers.geom_iterable(geom::FastInGeometry) = polyareas(LatLon, geom)

### We explicitly avoid implementing the Meshes interface for FastInGeometry objects here to encourage users to explicitly decide whether to use the LatLon or Cartesian CRS both available in the underlying geometry.


### Base methods ###
function Base.keepat!(gb::GeoBorders, inds)
    props = (gb.latlon_polyareas, gb.cart_polyareas, gb.latlon_bboxes, gb.cart_bboxes)
    for prop in props
        keepat!(prop, inds)
    end
    return gb
end
function Base.deleteat!(gb::GeoBorders, inds)
    props = (gb.latlon_polyareas, gb.cart_polyareas, gb.latlon_bboxes, gb.cart_bboxes)
    for prop in props
        deleteat!(prop, inds)
    end
    return gb
end