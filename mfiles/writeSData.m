%function writeSData(stream::IOStream,
%                    width::Int32,
%                    height::Int32,
%                    gridsize::Float64,                   
%                    xmitr::Array{Float64,2},
%                    rcvr::Array{Float64,2},
%                    data::Array{Any,2})
%    # Write width, which is the number of pixels
%    # in the horizontal direction, and height
%    # which is the number of pixels in the vertical.
%    write(stream, width, height);
%    # Write the gridsize
%    write(stream, gridsize);
%    # Write the number of transducers
%    write(stream, Int32(size(xmitr)[1]));
%    # Write the transducer positions
%    write(stream, xmitr[:,1], xmitr[:,2],
%          rcvr[:,1], rcvr[:,2]);
%    # Write the cell array of S-matrix entries
%    # The following will write in column-major order
%    for mycell in data
%        writeCell(stream, mycell);
%    end
%    true
%end

function writeSData(fid, width, height, gridsize, xmitr, rcvr, data)
  % Write width, which is the number of horizontal pixels
  % and height, which is the number of vertical
  fwrite(fid, int32(width), "Int32");
  fwrite(fid, int32(height), "int32");
  % Write the gridsize
  fwrite(fid, gridsize, "Float64");
  % Write the transducer count
  ntrans = int32(size(xmitr))(1);
  fwrite(fid, ntrans, "Int32");
  % Write the transducer positions
  fwrite(fid, xmitr, "Float64");
  fwrite(fid, rcvr, "Float64");
  for j=1:ntrans
    for i=1:ntrans
      writeSCell(fid, data{i, j});
      endfor
    endfor
  endfunction
