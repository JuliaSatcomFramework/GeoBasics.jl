# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## [1.3.0] - 2026-06-22
### Fixed
Two antimeridian/pole regressions introduced in v1.2.2, see [#6](https://github.com/JuliaSatcomFramework/GeoBasics.jl/pull/6) for details:
- Building `GeoBorders` no longer errors on a pole-containing ring whose antimeridian crossing cannot be split (e.g. some polygon-offset artifacts).
- The contained pole is now identified on the canonically-oriented ring, so rings not following the GeoJSON winding convention (e.g. NaturalEarth) are no longer closed around the wrong pole and inverted (as happened for Antarctica).

## [1.2.2] - 2026-06-17
### Fixed
- Point-in-polygon checks now return correct results for polygons that contain a pole (e.g. polar caps crossing the antimeridian). Such polygons are degenerate in the flat `(lon, lat)` projection used internally, so points near the pole inside the cap were previously reported as outside.

### Changed
- Updated the compat to include the latest versions of `Meshes.jl` (0.56/0.57).

## [1.2.1] - 2025-11-11
### Removed
- Dropped support for `BasicTypes.jl` v1; the package now requires `BasicTypes.jl` v2.

## [1.2.0] - 2025-11-06

### Changed
- Updated compat to include `BasicTypes.jl@v2`
- GeoBasics now uses the built-in scoped values introduced in Julia 1.11.
- ⚠️ If you are using `BasicTypes.with`, this needs to be changed to `with` from `Base.ScopedValues`

## [1.1.1] - 2025-10-06
### Changed
- Updated the compat to include the latest version of `CoordRefSystems.jl` (0.19.0)
- Updated the compat to include the latest version of `Meshes.jl` (0.55.0)

## [1.1.0] - 2025-08-19
### Added
- Added the `distance_resample` function (and its mutating version `distance_resample!`) for resampling the polygons in a `GeoBorders` instance so that the segments of each ring of the GeoBorder's `polyareas` are not longer than a given distance `target_dist`.
  - Useful for _oversampling_ a GeoBorders to increase the point density along its borders.

## [1.0.2] - 2025-07-11

### Fixed
- Reworked `to_xxx_point` functions to really only rely on `to_raw_lonlat` instead of also on `valuetype` in some cases.

## [1.0.1] - 2025-07-12
### Added
Added a method for `Meshes.paramdim` for `FastInGeometry` objects. This is mostly for supporting calls to `GeoTable` with a domain made of `FastInGeometry`s

## [1.0.0] - 2025-07-11
Initial Version