function distance_resample(r::RING_LATLON, target_dist)
    target_dist = enforce_unit(u"m", target_dist)
    PT = eltype(vertices(r))
    resampled = PT[] # This will hold the new points of the ring sampled to achieve approximately the desired distance
    for s in segments(r)
        normalized_step = target_dist / length(s)
        parametric_range = range(0, 1; step=normalized_step)
        for p in parametric_range
            push!(resampled, s(p))
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