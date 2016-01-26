"""
module GenS

Utilities to generate the non-zero elements of a system matrix and to read and write such data to disk in cross-language binary form.

If n is the number of transducers per probe, non-zero elements of a system matrix are stored in an nxn Array of type `Any`, a structure roughly equivalent to a cell array in Matlab or Octave. Entry i,j of this array identifies the pixels crossed by the path from transmitter i to receiver j, and gives the lengths intersected with each. This entry is a 1x2 array of type `Any` whose first component is an array of pixel indices, and whose second is the corresponding lengths.
"""
module GenS

export wCrossings, gridCrossings, segmentLengths, probePos, genS, writeSData, readSData, readCell, writeCell


"""
wCrossings(u, v, w, k)
    
Given three vectors, u, v, w, and a series of scalars, k, find all lambda in the 
unit interval such that the inner product of w with u + lambda*(v-u) is one of the
scalars in k.
"""
function wCrossings(u::Array{Float64,1}, v::Array{Float64,1}, w::Array{Float64,1}, k::Array{Float64,1})
    lambda =  (k - dot(u,w))/dot(v-u,w);
    return lambda[0.0 .<= lambda .<= 1.0];
end

"""
gridCrossings(u, v, width, height, gridsize, [epsilon])

Find the points of a 2D grid crossed by a line segment whose two endpoints are u and v.
The grid is defined by an integral height and width and a gridsize. Its lower left
corner is assumed to be the origin. Pixels are assumed to be square and grid lines
are assumed parallel to the x and y axes. Width refers to the number of cells in the
x direction, height to those in the y direction. Returned crossings will be in order from u to v.
"""
function gridCrossings(u::Array{Float64,1}, v::Array{Float64,1}, width::Int, height::Int,
                       gridsize::Float64, epsilon = (eps(Float64)^.75))
    kx = collect(gridsize*(0:width)); # collect converts Range object to Array
    ky = collect(gridsize*(0:height));
    lambda = sort(unique(vcat(wCrossings(u,v,vcat(1.0,0.0), kx), wCrossings(u, v, vcat(0.0,1.0), ky))));
    # Since lambdas are sorted in ascending order, crossings will be
    # in order from u to v. Eliminate any which are too close together.
    n = length(lambda);
    if n > 1
        idx = vcat(true, abs(lambda[1:(n-1)]-lambda[2:n]) .> epsilon);
    elseif n == 1
        idx = vcat(true);
    else
        return Array(Float64,0,2)
    end
    crossings = hcat(u[1] + lambda[idx]*(v[1]-u[1]),
                     u[2] + lambda[idx]*(v[2]-u[2]));
    return crossings
end

"""
segmentLenghts(u, v, width, height, gridsize)
    
Given a line segment determined by 2 endpoints, u and v, and 2D grid determined
by a width, height, and gridsize, return the indices of the pixels crossed
and the lengths of their intersections with the segment. Return value is
a tuple: indices, lengths.
"""
function segmentLengths(u::Array{Float64,1}, v::Array{Float64,1}, width::Int, height::Int, gridsize::Float64)
    crossings = gridCrossings(u, v, width, height, gridsize);
    n = size(crossings,1);
    if n > 1
        return 1+floor(Int, (crossings[1:(n-1),:]+crossings[2:n,:])/(2*gridsize)), # indices
        sqrt((crossings[2:n,:]-crossings[1:(n-1),:]).^2 * vcat(1,1));   # lengths
    else
        return Array(int,0,2), Array(Float64,0,1);
    end
end


"""
transducerPos(n, u, v)
    
Given a number, n, of equally spaced transducers and two points, u and v, representing
the two endpoints of a probe, return transducer positions as an n by 2 matrix.
Transducers are placed in the centers of the n intervals of equal length which 
partition the line segment between u and v.
             u--1--|--2--|...|--n--v
"""
function transducerPos(n::Int, u::Array{Float64,2}, v::Array{Float64,2})
    # First transducer is half a space from u. Subsequent transducers
    # are full spaces from one another.
    tp = zeros(Float64, n, 2);
    for k in 1:n
        tp[k,:] = u + (k-0.5)*(v-u)/n;
    end
    return tp;
end

"""
probePos(n, r)
    
Given the corner coordinates of a plane rectangle in counter-clockwise order,
and assuming that n probes should be aligned on the two edges determined by
the first and last two coordinates, respectively, return the positions
of n equally spaced transducers which span the respective edges.
"""
function probePos(n::Int, r::Array{Float64,2})
    probe1 = transducerPos(n, r[1,:], r[2,:]);
    probe2 = transducerPos(n, r[3,:], r[4,:]);
    return probe1, probe2;
end

"""
genS(width, height, gridsize, xmitr, rcvr)
    
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
members, a 2D `Int32` array containing indices of pixels crossed by path i->j
and a 1D `Float64` array containing corresponding lengths. The S matrix can
be easily construced with this information.

The choice of `Int32`, as opposed to `Int` or `Int64` is for safety. R, for
instance, does not yet support 64 bit integers. Moreover, there are still
32-bit machines around.
"""
function genS(width::Int, height::Int, gridsize::Float64,
              xmitr::Array{Float64,2}, rcvr::Array{Float64,2})
    ntrans = size(xmitr)[1];
    data = Array(Any, ntrans, ntrans);
    xm = xmitr'; # for correct types to segmentLengths
    rc = rcvr';
    for j in 1:ntrans
        v = rc[:,j];
        for i in 1:ntrans
            idx, len = segmentLengths(xm[:,i], v, width, height, gridsize);
            data[i,j] = Any[idx, len];
        end
    end
    return data
end

"""
writeCell(stream, acell)

Write a cell, a 1D array of type `Any` whose entries
are an nx2 `Int32` array of pixel indices and an nx1
`Float64` array of lengths.
"""
function writeCell(stream::IOStream, acell::Array{Any,1})
    n = Int32(size(acell[1],1));
    write(stream, n);
    # Forcibly convert acell[1] to Int32
    write(stream, collect(Int32, acell[1]));
    write(stream, acell[2]);
end

"""
readCell(stream)
    
Read a cell from the given IOStream
"""
function readCell(stream::IOStream)
    n = read(stream, Int32);
    pix = read(stream, Int32, n, 2);
    len = read(stream, Float64, n);
    Any[pix, len];
end

"""
writeSData(stream, width, height, gridsize, xmitr, rcvr, data)

Write data sufficient to construct a system matrix and to identify the grid and probe positions to which it pertains. Matlab/Octave functions to read this data are provided in m files with appropriate names. 
"""
function writeSData(stream::IOStream,
                    width::Int32,
                    height::Int32,
                    gridsize::Float64,                   
                    xmitr::Array{Float64,2},
                    rcvr::Array{Float64,2},
                    data::Array{Any,2})
    # Write width, which is the number of pixels
    # in the horizontal direction, and height
    # which is the number of pixels in the vertical.
    write(stream, width, height);
    # Write the gridsize
    write(stream, gridsize);
    # Write the number of transducers
    write(stream, Int32(size(xmitr)[1]));
    # Write the transducer positions
    write(stream, xmitr[:,1], xmitr[:,2],
          rcvr[:,1], rcvr[:,2]);
    # Write the cell array of S-matrix entries
    # The following will write in column-major order
    for mycell in data
        writeCell(stream, mycell);
    end
    true
end

"""
readSData(stream)

Read binary data written by writeSData or the Matlab/Octave function of
the same name. This function is mainly used to check data transfer
integrity between Julia and Matlab/Octave.
"""
function readSData(stream::IOStream)
    # Read width and height
    (width, height) = read(stream, Int32, 2);
    # Read gridsize
    gridsize = read(stream, Float64);
    # Read transducer count
    ntrans = read(stream, Int32);
    # Read transducer positions
    xmitr = read(stream, Float64, ntrans, 2);
    rcvr = read(stream, Float64, ntrans, 2);
    # Create a cell array
    data = Array(Any, ntrans, ntrans);
    # Fill by column
    for j = 1:ntrans
        for i = 1:ntrans
            data[i,j] = readCell(stream)
        end
    end
    return width, height, gridsize, xmitr, rcvr, data;
end


end
