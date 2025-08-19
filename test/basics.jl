@testsnippet setup_basic begin
    using GeoBasics
    using GeoBasics: POINT_LATLON, POLY_LATLON, POLY_CART, BOX_LATLON, BOX_CART, POINT_CART, POLYAREAS_NOWARN
    using GeoBasics: cartesian_geometry, latlon_geometry, to_latlon_point, to_cartesian_point
    using GeoBasics.GeoPlottingHelpers
    using GeoBasics.BasicTypes: BasicTypes, valuetype, with
    using GeoBasics.CoordRefSystems
    using GeoBasics.Meshes: 𝔼, Point, Box, PolyArea, Multi
    using GeoBasics.CoordRefSystems: LatLon, Cartesian, WGS84Latest
    using GeoBasics.Unitful: Unitful, °, @u_str
    using TestAllocations
end

@testitem "Cartesian LatLon conversion" setup=[setup_basic] begin

    pa_latlon = PolyArea([Point(LatLon{WGS84Latest}(10°, -5°)), Point(LatLon{WGS84Latest}(10°, 15°)), Point(LatLon{WGS84Latest}(27°, 15°)), Point(LatLon{WGS84Latest}(27°, -5°))])
    pa_cartesian = PolyArea([Point{𝔼{2}}(Cartesian{WGS84Latest}(-5, 10)), Point{𝔼{2}}(Cartesian{WGS84Latest}(15, 10)), Point{𝔼{2}}(Cartesian{WGS84Latest}(15, 27)), Point{𝔼{2}}(Cartesian{WGS84Latest}(-5, 27))])

    multi_cartesian = Multi([pa_cartesian])
    multi_latlon = Multi([pa_latlon])

    # Test the Box conversion
    box_latlon = Box(
        Point(LatLon(-10°, -10°)),
        Point(LatLon(10°, 10°))
    )

    @test box_latlon |> cartesian_geometry isa BOX_CART{Float64}
    @test box_latlon |> cartesian_geometry(Float32) |> latlon_geometry isa BOX_LATLON{Float32}

    @test pa_latlon |> latlon_geometry(Float32) isa POLY_LATLON{Float32}
    @test pa_latlon |> cartesian_geometry(Float32) isa POLY_CART{Float32}

    @test pa_latlon |> cartesian_geometry isa POLY_CART{Float64}
    @test pa_cartesian |> latlon_geometry isa POLY_LATLON{Float64}

    @test pa_latlon |> cartesian_geometry |> latlon_geometry == pa_latlon
    @test pa_latlon |> latlon_geometry == pa_latlon
    @test pa_cartesian |> latlon_geometry |> cartesian_geometry == pa_cartesian
    @test pa_cartesian |> latlon_geometry == pa_latlon
    @test pa_cartesian |> cartesian_geometry == pa_cartesian
    @test pa_latlon |> cartesian_geometry == pa_cartesian

    @test multi_cartesian |> latlon_geometry == multi_latlon
    @test multi_latlon |> cartesian_geometry == multi_cartesian

    ll = rand(LatLon)
    p = to_point(LatLon, ll)
    @test p isa POINT_LATLON{Float64}
    @test get_lon(p) == get_raw_lon(ll) * °
    @test get_lat(p) == get_raw_lat(ll) * °
end

@testitem "to_xxx_point" setup=[setup_basic] begin
    # Basic checks
    @test to_point(LatLon, Float64, (20,10)) isa POINT_LATLON{Float64}
    @test to_point(Cartesian, Float32, (20,10)) isa POINT_CART{Float32}

    # Check base fix
    @test (20,10) |> to_latlon_point(Float32) === Point(LatLon(10f0, 20f0))
    @test (20,10) |> to_cartesian_point(Float32) === Point(Cartesian2D{WGS84Latest}(20f0, 10f0))

    # Check that implementing `to_raw_lonlat` is enough to make a point compatible with `to_latlon_point`
    struct LL
        lat::Float64
        lon::Float64
    end
    GeoPlottingHelpers.to_raw_lonlat(ll::LL) = (ll.lon, ll.lat)

    @test LL(20, 10) |> to_latlon_point(Float32) === Point(LatLon(20f0, 10f0))
    @test LL(20, 10) |> to_cartesian_point(Float32) === Point(Cartesian2D{WGS84Latest}(10f0, 20f0))

    # We check that we also support NamedTuples as inputs and valuetype is extracted correctly
    pf32 = to_point(LatLon, (lat = 20, lon = 10))
    @test pf32 === Point(LatLon(20f0, 10f0)) && pf32 isa POINT_LATLON{Float32}

    pf64 = to_point(LatLon, (lat = 20.0, lon = 10u"°"))
    @test pf64 === Point(LatLon(20.0, 10.0)) && pf64 isa POINT_LATLON{Float64}
end

@testitem "to_multi" setup=[setup_basic] begin
    multi = rand(PolyArea, 10; crs = LatLon) |> Multi

    gb = GeoBorders(multi)

    gb |> to_multi(LatLon) == multi

    @test @nallocs(to_multi($LatLon, gb)) == 0
    @test @nallocs(to_multi($Cartesian, gb)) == 0
end

@testitem "warnings" setup=[setup_basic] begin
    p = rand(PolyArea; crs = LatLon)
    @test_logs (:warn, r"internal") polyareas(LatLon, p)
    # We test that it doesn't warn with the nowarn keyword
    @test_logs polyareas(LatLon, p; nowarn = true)

    # We test that providing `fix_antimeridian_crossing` gives a warning with input FastInGeometry

    b = GeoBorders(p)
    @test_logs (:warn, r"ignored") GeoBorders(b; fix_antimeridian_crossing = true)

    # We test that the POLYAREAS_NOWARN can be used to suppress warnings as well
    BasicTypes.with(POLYAREAS_NOWARN => true) do
        @test_logs polyareas(LatLon, p)
    end
end

@testitem "show" setup=[setup_basic] begin

    gb = GeoBorders{Float64}(rand(PolyArea, 10; crs = LatLon))

    @test startswith(repr(gb), "GeoBorders{Float64}(")
    @test startswith(repr(MIME"text/plain"(), gb), "GeoBorders{Float64}\n")
end


@testitem "deps_interface" setup=[setup_basic] begin
    # We test that the `deps` interface is working correctly

    gb = GeoBorders{Float64}(rand(PolyArea, 10; crs = LatLon))

    @test Meshes.paramdim(gb) == 2

    @test GeoPlottingHelpers.geom_iterable(gb) == polyareas(LatLon, gb)

    ## Base methods

    polys = rand(PolyArea, 10; crs = LatLon)
    ref_gb = GeoBorders{Float64}(polys)

    npolys = length(polyareas(Cartesian, ref_gb))

    to_keep = 1:4
    to_delete = 5:npolys

    getters = map(Iterators.product((polyareas, bboxes), (LatLon, Cartesian))) do (f, crs)
        Base.Fix1(f, crs)
    end

    kept_gb = keepat!(GeoBorders{Float64}(polys), to_keep)
    deleted_gb = deleteat!(GeoBorders{Float64}(polys), to_delete)

    @test all(getters) do f
        f(kept_gb) == f(deleted_gb) == f(ref_gb)[to_keep]
    end

    # We now test with bitvector inputs
    to_keep = falses(npolys)
    to_keep[1:4] .= true
    to_delete = trues(npolys)
    to_delete[1:4] .= false

    kept_gb = keepat!(GeoBorders{Float64}(polys), to_keep)
    deleted_gb = deleteat!(GeoBorders{Float64}(polys), to_delete)

    @test all(getters) do f
        f(kept_gb) == f(deleted_gb) == f(ref_gb)[to_keep]
    end
end