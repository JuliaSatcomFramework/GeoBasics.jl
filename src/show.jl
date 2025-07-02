function Base.summary(io::IO, gb::GeoBorders{T}) where T
    print(io, "GeoBorders{$T}")
end

function Base.show(io::IO, gb::GeoBorders)  
  summary(io, gb)
  print(io, "(")
  geoms = Meshes.prettyname.(gb.latlon_polyareas)
  counts = ("$(count(==(g), geoms))×$g" for g in unique(geoms)) |> collect
  join(io, counts, ", ")
  print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", gb::GeoBorders)
  summary(io, gb)
  println(io)
  Meshes.printelms(io, gb.latlon_polyareas)
end