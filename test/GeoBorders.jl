@testsnippet setup_geoborders begin
    using GeoBasics
    using GeoBasics: POLY_LATLON, POLY_CART, BOX_LATLON, BOX_CART
    using GeoBasics.Meshes
    using GeoBasics.CoordRefSystems
    using GeoBasics.BasicTypes: BasicTypes, valuetype
    using GeoBasics.GeoPlottingHelpers: to_raw_lonlat
    using GeoBasics: to_cart_point, split_antimeridian
    using TestAllocations
end

@testitem "GeoBorders antimeridian/orientation" setup=[setup_geoborders] begin
    # We create a complex polygon that has a reversed S shape crossing the antimeridian in multiple places
    complex_s_poly = let
        f = Base.Fix1(to_cart_point, Float64)
        outer = map(f, [
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
        inner_west = map(f, [
            (-162, -12),
            (-162, -18),
            (-168, -18), 
            (-168, -12)
        ]) |> Ring
        inner_east = map(f, [
            (162, 22),
            (162, 28),
            (168, 28), 
            (168, 22)
        ]) |> Ring
        inner_both = map(f, [
            (170, 2),
            (170, 8),
            (-170, 8), 
            (-170, 2)
        ]) |> Ring
        PolyArea([outer, inner_west, inner_east, inner_both])
    end
    
    # By default, when using normal geometries (that don't subtype `FastInGeometry`), the antimeridian split is performed
    with_split = GeoBorders(complex_s_poly)
    @test length(polyareas(LatLon, with_split)) == 4
    # If we force to disregard the antimeridian split, we get a single polygon that is degenerate
    without_split = GeoBorders(complex_s_poly, fix_antimeridian_crossing = false)
    @test length(polyareas(LatLon, without_split)) == 1

    # We test that the point in LatLon(0,0) is correctly excluded by the polygon with fix, while it is included in the one without fix as it's a degenerate polygon spanning most of the longitudes around 0 latitude
    @test in(LatLon(0,0), without_split)
    @test !in(LatLon(0,0), with_split)

    # We check that a point in the upper left part of the polygon, next to the east hole is included only with the fix
    @test !in(LatLon(25.0, 170.0), without_split)
    @test in(LatLon(25.0, 170.0), with_split)

    # Now we reverse the polygon and check that we still get a correct split with 4 polyareas
    reverse_poly = let
        poly = complex_s_poly
        T = valuetype(poly)
        rrings = map(rings(complex_s_poly)) do r
            vs = map(vertices(r)) do p
                lon, lat = to_raw_lonlat(p)
                to_cart_point(T, (-lon, lat))
            end |> Ring
        end |> PolyArea
    end
    reverse_split = GeoBorders{Float32}(reverse_poly)
    @test length(polyareas(LatLon, reverse_split)) == 4

    function has_correct_orientation(poly::PolyArea)
        outer, inners = Iterators.peel(rings(poly))
        orientation(outer) == CCW && all(r -> orientation(r) == CW, inners)
    end
    has_correct_orientation(geom) = all(has_correct_orientation, polyareas(Cartesian, geom)) && all(has_correct_orientation, polyareas(LatLon, geom))

    # We check that the orientation of the polygon is enforced. The original poly is not correctly oriented
    @test !has_correct_orientation(complex_s_poly)
    # The processed polygons, both with and without antimeridian fix must be
    @test has_correct_orientation(with_split)
    @test has_correct_orientation(without_split)
end

@testitem "FastInGeometry interface" setup=[setup_geoborders] begin
    # We try implementing a type supporting the `FastInGeometry` interface in the simplest way possible, by having a field of type `GeoBorders`

    struct SimpleGeometry{Float64} <: FastInGeometry{Float64}
        name::String
        borders::GeoBorders{Float64}
    end

    function SimpleGeometry(geoms; name = "SimpleGeometry")
        borders = GeoBorders{Float64}(geoms)
        return SimpleGeometry{Float64}(name, borders)
    end

    ps = rand(PolyArea, 10; crs = LatLon)
    sg = SimpleGeometry(ps)

    @test geoborders(sg) isa GeoBorders{Float64}
    @test polyareas(LatLon, sg) isa Vector{<:POLY_LATLON}
    @test polyareas(Cartesian, sg) isa Vector{<:POLY_CART}
    @test bboxes(LatLon, sg) isa Vector{<:BOX_LATLON}
    @test bboxes(Cartesian, sg) isa Vector{<:BOX_CART}

    @testset "Allocations" begin
        sg = SimpleGeometry(ps)
        @test @nallocs(geoborders(sg)) == 0
        @test @nallocs(polyareas(LatLon, sg)) == 0
        @test @nallocs(polyareas(Cartesian, sg)) == 0
        @test @nallocs(bboxes(LatLon, sg)) == 0
        @test @nallocs(bboxes(Cartesian, sg)) == 0
    end
end