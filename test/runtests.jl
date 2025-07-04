using TestItemRunner

@testitem "Aqua" begin
    using Aqua
    using GeoBasics
    Aqua.test_all(GeoBasics; ambiguities = false)
    Aqua.test_ambiguities(GeoBasics)
end
@testitem "DocTests" begin
    using Documenter
    using GeoBasics
    Documenter.doctest(GeoBasics; manual = false)
end

@run_package_tests verbose = true