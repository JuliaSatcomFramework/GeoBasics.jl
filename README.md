# GeoBasics

[![Docs Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliasatcomframework.github.io/GeoBasics.jl/stable)
[![Docs Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliasatcomframework.github.io/GeoBasics.jl/dev)
[![Build Status](https://github.com/JuliaSatcomFramework/GeoBasics.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaSatcomFramework/GeoBasics.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JuliaSatcomFramework/GeoBasics.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaSatcomFramework/GeoBasics.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

This package defines the basic building block for downstream packages in our framework using Geo functionality (mostly leveraging the ecosystem of [Meshes.jl](https://github.com/JuliaGeometry/Meshes.jl) and [CoordRefSystems.jl](https://github.com/JuliaEarth/CoordRefSystems.jl)).

It mainly addresses two desired functionalities in our packages:
- Simplifying a way to create custom types representing regions/geometries which have an optimized algorithm for check point inclusion (within the region)
  - This is achieved by subtyping the `FastInGeometry` abstract type and implementing its limited interface
- Avoiding issues with regions created from polygons that might cross the antimeridian (the line where longitude is ±180°). 
  - This is handled in the constructor of `GeoBorders`, the only concrete type implementing the `FastInGeometry` interface exposed by this package. The algorithm to fix antimeridian crossing is based on the algorithm implemented in the python package [antimeridian](https://github.com/gadomski/antimeridian) that also provides a simplified explanation of the algorithm in its [documentation](https://www.gadom.ski/antimeridian/latest/the-algorithm/).

Check the documentation for more details on the exposed API.