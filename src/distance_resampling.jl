# Haversine distance between `p1` and `p2` on a sphere with the WGS84 major axis as radius.
# This is the `measure(::Segment{🌐})` of Meshes up to v0.55. The code is local, so the result does not change with the Meshes version.
function haversine_distance(p1::POINT_LATLON, p2::POINT_LATLON)
    lon1, lat1 = to_raw_lonlat(p1)
    lon2, lat2 = to_raw_lonlat(p2)
    r = ustrip(u"m", CoordRefSystems.majoraxis(CoordRefSystems.ellipsoid(WGS84Latest))) |> typeof(lat1)
    a = sind((lat2 - lat1) / 2)^2 + cosd(lat1) * cosd(lat2) * sind((lon2 - lon1) / 2)^2
    return 2 * (r * asin(min(√a, one(a)))) * u"m"
end

function distance_resample(r::RING_LATLON, target_dist)
    target_dist = enforce_unit(u"m", target_dist)
    T = valuetype(r)
    PT = eltype(vertices(r))
    resampled = PT[] # This will hold the new points of the ring sampled to achieve approximately the desired distance
    for s in segments(r)
        a, b = extrema(s)
        normalized_step = target_dist / haversine_distance(a, b)
        if normalized_step < 1
            lon1, lat1 = to_raw_lonlat(a)
            lon2, lat2 = to_raw_lonlat(b)
            for t in range(0, 1; step=normalized_step)
                # Linear interpolation in (lat, lon), so the new points stay on the edges of the flat (lon, lat) polygon
                lat = lat1 * (1 - t) + lat2 * t
                lon = lon1 * (1 - t) + lon2 * t
                push!(resampled, LatLon{WGS84Latest}(T(lat), T(lon)) |> Point)
            end
        else
            push!(resampled, a)
        end
    end
    return Ring(resampled)
end

function distance_resample(poly::POLY_LATLON, target_dist)
    map(rings(poly)) do r
        distance_resample(r, target_dist)
    end |> PolyArea
end

"""
    distance_resample!(gb::GeoBorders, target_dist)

Take a `GeoBorders` instance and modifies it in place so that all the underlying polyareas have been resampled so that each of their rings do not have segments longer than `target_dist`.

The target maximum distance between points over the polygon borders can be provided either with or without unit (which must be a `Length` if provided). **Numbers without units are interpreted as meters**.

!!! note
    This function does not guarantee each of the segments to be exactly `target_dist` long, though most of the resulting segments will be very close to it. It will not distort the original shape so all of th original vertices will still be present in each ring of each resampled polygon.

## Returns 
Returns the modified `GeoBorders` instance.

See also [`distance_resample`](@ref).
"""
function distance_resample!(gb::GeoBorders, target_dist)
    # We will go through each of the polygons stored in `gb` and resample them to achieve the maximum distance between points over the segments being equivalent to the proided `target_dist` 
    latlon = polyareas(LatLon, gb)
    cart = polyareas(Cartesian, gb)
    for i in eachindex(latlon, cart)
        new_latlon = distance_resample(latlon[i], target_dist)
        new_cart = cartesian_geometry(new_latlon)
        latlon[i] = new_latlon
        cart[i] = new_cart
        # We don't modify the boundingboxes as they do not change when just resampling
    end
    return gb
end

"""
    distance_resample(gb::GeoBorders, target_dist)

Take a `GeoBorders` instance and returns a copy of it where all the underlying polyareas have been resampled so that each of their rings do not have segments longer than `target_dist`.

The target maximum distance between points over the polygon borders can be provided either with or without unit (which must be a `Length` if provided). **Numbers without units are interpreted as meters**.

!!! note
    This function does not guarantee each of the segments to be exactly `target_dist` long, though most of the resulting segments will be very close to it. It will not distort the original shape so all of th original vertices will still be present in each ring of each resampled polygon.


## Returns 
Returns a new `GeoBorders` instance of the same valuetype as the input one. For a function that modifies an existing `GeoBorders` instance, see [`distance_resample!`](@ref).
"""
function distance_resample(gb::GeoBorders, target_dist)
    return distance_resample!(deepcopy(gb), target_dist)
end