# Tutorial

## Point inclusion algorithm

This package was born from the need of ensuring a simple way of optimizing the performance of checking whether a point on the Earth's surface is located within a given region (e.g. a country, a satellite beam, or any other area that can be represented by a polygon in latitude/longitude coordinates).

We need to define multiple types of such regions in our downstream packages (e.g. [CountriesBorders.jl](https://github.com/JuliaSatcomFramework/CountriesBorders.jl)) and we want to minimize code duplication as much as possible.

The traditional `p in region` is well defined in `Meshes.jl` but is suboptimal when one wants to check a lot of points (e.g. thousands) over a domain spanning multiple polygons (e.g. the domain of all polygons associated to all countries).
The complexity of checking for point inclusion in a polygon increases with the number of points in the polygon, and when you have lots of points and lots of polygons, most of your `point/polygon` pair will return false.

The approach to speed up computations taken in this package is to create custom geometries that store not only the polyareas but also the bounding boxes (i.e. a `Box` from `Meshes.jl`) associated to each polyarea. 
The modified inclusion algorithm then simply prefilters `point/polygon` pairs by checking first inclusion in the bounding box (which is extremely fast) and falling back to checkin inclusion in the polygon only if `p in bbox` is `true`.
This has shown to provide speed ups of 20x-40x in tests when implemented for the [CountriesBorders.jl](https://github.com/JuliaSatcomFramework/CountriesBorders.jl) downstream package (see [this PR](https://github.com/JuliaSatcomFramework/CountriesBorders.jl/pull/47))

## FastInGeometry Interface

To simplify exploiting this fast algorithm for custom geometries defined in downstream packages, this package defines an **interface** that is adhered to when a type satisfies the three conditions below:
- It subtypes the `FastInGeometry` abstract type defined and exported by this package
- It has a valid method for the interface function [`polyareas`](@ref) returning an iterable of `PolyArea`s.
- It has a valid method for the interface function [`bboxes`](@ref) returning an iterable of `Box`s

In reality, the 2nd and 3rd conditions can also be met by simply containing a field which subtypes [`GeoBorders`](@ref) (more details in the next section) or defining a custom method for the interface function [`geoborders`](@ref) that returns an instance of type [`GeoBorders`](@ref).

As an example, see the following code snippet defining a simple geometry that satisfies the `FastInGeometry` interface by resorting to the simplest approach of having a field subtyping [`GeoBorders`](@ref)

```julia
using GeoBasics

# Define a custom type which subtypes 
struct SimpleGeometry{Float64} <: FastInGeometry{Float64}
    name::String
    borders::GeoBorders{Float64}
end
```

## GeoBorders

This package defines a single concrete subtype satisfying the [`FastInGeometry`](@ref) interface with the [`GeoBorders`](@ref) type.
This is intended to represent the borders of arbitrary regions, and provides an easy way for custom regions to adhere to the [`FastInGeometry`](@ref) interface (as explained above).

Additionally, when provided with geometries that are plain `Multi`, `PolyArea` or `Box` from Meshes (and not other geometries satysfiying the `FastInGeometry` interface), the constructor for [`GeoBorders`](@ref) automatically tries fixing issues with polygons crossing the antimeridian line. It does so by implementing the algorithm of the [antimeridian](https://github.com/gadomski/antimeridian) python library that also provides a simplified explanation of the algorithm in its [documentation](https://www.gadom.ski/antimeridian/latest/the-algorithm/).

To show the problem of with polygons crossing the antimeridian, consider the following complex polygon that contains holes and crosses the antimeridian multiple times

```@example antimeridian
using GeoBasics
using GeoBasics.Meshes
using GeoBasics.GeoPlottingHelpers
using PlotlyBase
using PlotlyDocumenter

complex_s_poly = let
    f = Base.Fix1(to_cart_point, Float64)
    outer = map(f, [ # Exterior part of the polygon, crossing the antimeridian multiple times
        (160,30),
        (-160,30),
        (-160,0),
        (170, 0),
        (170, -10),
        (-160, -10),
        (-160, -20),
        (160, -20),
        (160, 10),
        (-170, 10),
        (-170, 20),
        (160, 20),
    ]) |> Ring
    inner_west = map(f, [ # Hole in the western hemisphere, in the lower right of the polygon
        (-162, -12),
        (-162, -18),
        (-168, -18), 
        (-168, -12)
    ]) |> Ring
    inner_east = map(f, [ # Hole in the eastern hemisphere, in the upper left of the polygon
        (162, 22),
        (162, 28),
        (168, 28), 
        (168, 22)
    ]) |> Ring
    inner_both = map(f, [ # Hole crossing the antimeridian, in the middle of the polygon
        (170, 2),
        (170, 8),
        (-170, 8), 
        (-170, 2)
    ]) |> Ring
    PolyArea([outer, inner_west, inner_east, inner_both])
end

plt = with_settings(:OVERSAMPLE_LINES => :SHORT) do # This makes sure that the plot uses the shortest line between points
    geo_plotly_trace(complex_s_poly; mode = "lines") |> Plot
end
to_documenter(plt) # hide
```