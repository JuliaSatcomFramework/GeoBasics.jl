@testsnippet setup_basic begin
    using GeoBasics
    using GeoBasics: POINT_LATLON, POLY_LATLON, POLY_CART, BOX_LATLON, BOX_CART
    using GeoBasics: cartesian_geometry, latlon_geometry, to_latlon_point
    using GeoBasics.CoordRefSystems: WGS84Latest
    using GeoBasics.Meshes: 𝔼, Point, Box, PolyArea, Multi
    using GeoBasics.CoordRefSystems: LatLon, Cartesian, WGS84Latest
    using GeoBasics.Unitful: Unitful, °, @u_str
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