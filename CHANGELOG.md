# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

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