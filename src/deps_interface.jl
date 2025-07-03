GeoPlottingHelpers.geom_iterable(geom::FastInGeometry) = polyareas(Cartesian, geom)

### We explicitly avoid implementing the Meshes interface for FastInGeometry objects here to encourage users to explicitly decide whether to use the LatLon or Cartesian CRS both available in the underlying geometry.
