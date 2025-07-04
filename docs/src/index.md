# GeoBasics

This package provides fundamental building blocks for geographic operations, specifically designed for downstream packages in the JuliaSatcomFramework ecosystem. It builds open the JuliaEarth ecosystem and specifically heavily relies on [Meshes.jl](https://github.com/JuliaGeometry/Meshes.jl) and [CoordRefSystems.jl](https://github.com/JuliaEarth/CoordRefSystems.jl).

It mainly addresses two desired functionalities in our downstream packages:
- Simplifying a way to create custom types representing regions/geometries which have an optimized algorithm for check point inclusion (within the region)
  - This is achieved by subtyping the [`FastInGeometry`](@ref) abstract type and implementing its limited interface
- Avoiding issues with regions created from polygons that might cross the antimeridian (the line where longitude is ±180°). 
  - This is handled in the constructor of [`GeoBorders`](@ref), the only concrete type implementing the `FastInGeometry` interface exposed by this package. 
  - The algorithm to fix antimeridian crossing is based on the algorithm implemented in the python package [antimeridian](https://github.com/gadomski/antimeridian) that also provides a simplified explanation of the algorithm in its [documentation](https://www.gadom.ski/antimeridian/latest/the-algorithm/).