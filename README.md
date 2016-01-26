# GenS
## A Julia package in support of co-robotic ultrasound tomography

<!--- Comment out build status for the time being. Not using travis or appveyor
[![Build Status](https://travis-ci.org/wilcrofter/GenS.jl.svg?branch=master)](https://travis-ci.org/wilcrofter/GenS.jl) -->

Ultrasound time-of-flight tomography involves construction of a *system matrix*. Although sparse, a system matrix contains a large number of non-zero elements whose computation can be time consuming when implemented in interpreted scientific programming languages such as Matlab or R. The utilities in this package are implemented in [Julia](http://julialang.org/) whose speed rivals that of a compiled language, and whose cross-platform compatibility and ease of coding rivals that of Matlab or R.

The package contains Julia utilities to generate the non-zero elements of a system matrix and to read and write such data to disk in cross-language binary form. In addition, the package contains m-files to read and write the data in Matlab or Octave. To date the m-files have only been tested in Octave.

The Julia utilities of primary interest are `genS` and `writeSData`.

### `genS(width, height, gridsize, xmitr, rcvr)`
    
Given a grid determined by width, height, and gridsize, and given transmitter
and receiver locations relative to that grid, return a square array whose
i,j^th^ entry indicates the pixels crossed on the path from transmitter i
to receiver j, and their respective lengths.

The grid is assumed to extend from the origin gridsize\*width units in the
horizontal (first coordinate) direction and gridsize\*height coordinates
in the vertical (second coordinate) direction. Transmitter and receiver
coordinates should be relative to the same origin. Otherwise, the number
and arrangement of transducers is independent of grid specifications.

Transducer positions should be given as nx2 arrays, where n is the number
of transducers per probe. The return values of function `probePos` exemplify
the format.

The returned value is an nxn array of type `Any`, where n is the number of
transducers. Each entry i,j, is, itself, an array of type `Any` containing two
members, a 2D `Int32` array containing indices of pixels crossed by path i to j
and a 1D `Float64` array containing corresponding lengths. The S matrix can
be easily construced with this information.

The choice of `Int32`, as opposed to `Int` or `Int64` is for safety. R, for
instance, does not yet support 64 bit integers. Moreover, there are still
32-bit machines around.

### `writeSData(stream, width, height, gridsize, xmitr, rcvr, data)`

Write data sufficient to construct a system matrix and to identify the grid and probe positions to which it pertains. Matlab/Octave functions to read this data are provided in m files with appropriate names.

### The Matlab/Octave function of primary interest is `readSData`. It is not yet documented but its function signature is:

`function [width, height, gridsize, xmitr, rcvr, data] = readSData (fid)`

where `data` is a cell array whose contents correspond to the `Any` array of the same name in Julia. An `Any` array in Julia is essentially the same data structure as a cell array in Matlab. Thus in Matlab, `data{i, j}` is itself a cell array containing the non-zero pixel crossings on the path from transmitter `i` to receiver `j`. Its first element, `data{i,j}{1}` is a matrix of 2 columns giving the horizontal and vertical indices of a pixel. Its second element `data{i,j}{2}` is a matrix of 1 column giving the corresponding lengths.   