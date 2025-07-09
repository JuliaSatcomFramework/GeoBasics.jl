# This is used to control the warning in `polyareas` when the input is not a `FastInGeometry` but a plain `Geometry` from Meshes.jl
const POLYAREAS_NOWARN = ScopedRefValue(false)