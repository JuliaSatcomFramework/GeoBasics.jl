@testsnippet setup_distance begin
    using GeoBasics.Meshes
    using GeoBasics.Unitful
    using GeoBasics: latlon_geometry
    # These are useful for interactive testing in the REPL
    using GeoBasics
    using Test

    # This is a helper function to simplify creating a polygon
    function poly_borders(points::AbstractVector; fix_antimeridian_crossing = true)
        T = Float32
        poly = map(to_point(Cartesian, T), points) |> PolyArea
        return GeoBorders{T}(poly; fix_antimeridian_crossing)
    end

    onlypoly(x, T::Type = LatLon) = only(polyareas(T, x))
    onlyring(x, T::Type = LatLon) = only(rings(onlypoly(x, T)))

    # The Meshes length of a segment on 🌐 depends on the Meshes version, so we use the Haversine distance of GeoBasics
    seglengths(x) = map(s -> GeoBasics.haversine_distance(extrema(s)...), segments(onlyring(x, LatLon)))
end

@testitem "distance_resampling" setup=[setup_distance] begin
    poly_gb = poly_borders([(0, 0), (1, 0), (1, 1), (0, 1)])

    resampled = distance_resample(poly_gb, 2u"km")

    # We test that the total length has not changed (if not by minor rounding errors)
    @test sum(seglengths(poly_gb)) ≈ sum(seglengths(resampled)) atol = 1u"m"
    # We also test that all original points are still present in the resampled polygon
    @test all(eachvertex(onlyring(poly_gb))) do v
        v in eachvertex(onlyring(resampled))
    end

    # we first test that the starting points are more than 2km apart
    @test all(>(2u"km"), seglengths(poly_gb))
    # We test that the resampling ensures all points are less than 2km apart
    @test all(<(2.0001u"km"), seglengths(resampled))

    # Finally we test that also the cartesian polygon was updated. We do so by converting the cartesian to latlon and then measure again the segment lengths (because length of the segments in cartesian loses the length on the actual earth's surface)
    cartesian_candidate = onlypoly(resampled, Cartesian)
    @test all(<(2.0001u"km"), seglengths(latlon_geometry(cartesian_candidate)))

    # Now we test that if the distance is greater than the actual length of each segment the polygon is not changed
    target_dist = 2 * maximum(seglengths(poly_gb))
    not_resampled = distance_resample(poly_gb, target_dist)

    @test onlyring(poly_gb) == onlyring(not_resampled)

    # The new points are on the flat (lon, lat) edges, so a large lat/lon box does not bulge poleward
    box_gb = poly_borders([(0, 50), (90, 50), (90, 60), (0, 60)])
    @test all(v -> 50 ≤ get_raw_lat(v) ≤ 60, eachvertex(onlyring(distance_resample(box_gb, 500u"km"))))
end