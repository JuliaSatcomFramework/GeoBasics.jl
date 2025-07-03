@testsnippet setup_basic begin
    using GeoBasics
    using GeoBasics: POINT_LATLON, POLY_LATLON, POLY_CART, BOX_LATLON, BOX_CART, POINT_CART
    using GeoBasics: cartesian_geometry, latlon_geometry, to_latlon_point, to_cart_point
    using GeoBasics.GeoPlottingHelpers
    using GeoBasics.BasicTypes: BasicTypes, valuetype
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

    @test rand(LatLon) |> to_latlon_point isa POINT_LATLON{Float64}
end

@testitem "to_xxx_point" setup=[setup_basic] begin
    # Basic checks
    @test to_latlon_point(Float64, (20,10)) isa POINT_LATLON{Float64}
    @test to_cart_point(Float32, (20,10)) isa POINT_CART{Float32}

    # Check base fix
    @test (20,10) |> to_latlon_point(Float32) === Point(LatLon(10f0, 20f0))
    @test (20,10) |> to_cart_point(Float32) === Point(Cartesian2D{WGS84Latest}(20f0, 10f0))

    # Check that implementing `to_raw_lonlat` is enough to make a point compatible with `to_latlon_point`
    struct LL
        lat::Float64
        lon::Float64
    end
    GeoPlottingHelpers.to_raw_lonlat(ll::LL) = (ll.lon, ll.lat)
    BasicTypes.valuetype(::LL) = Float64

    @test LL(20, 10) |> to_latlon_point(Float32) === Point(LatLon(20f0, 10f0))
    @test LL(20, 10) |> to_cart_point(Float32) === Point(Cartesian2D{WGS84Latest}(10f0, 20f0))
end

@testitem "to_multi" setup=[setup_basic] begin
    multi = rand(PolyArea, 10; crs = LatLon) |> Multi

    gb = GeoBorders(multi)

    gb |> to_multi(LatLon) == multi

    @test @nallocs(to_multi($LatLon, gb)) == 0
    @test @nallocs(to_multi($Cartesian, gb)) == 0
end