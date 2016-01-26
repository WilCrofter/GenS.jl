
function [width, height, gridsize, xmitr, rcvr, data] = readSData (fid)
  % Read width and height
  width = fread(fid, 1, "Int32");
  height = fread(fid, 1, "Int32");
  % Read gridsize
  gridsize = fread(fid, 1, "Float64");
  % Read transducer count
  ntrans = fread(fid, 1, "Int32");
  % Read transucer positions
  xmitr = reshape(fread(fid, 2*ntrans, "Float64"), ntrans, 2);
  rcvr = reshape(fread(fid, 2*ntrans, "Float64"), ntrans, 2);
  % Create a cell array
  data = cell(ntrans, ntrans);
  for j=1:ntrans
      for i=1:ntrans
        data{i, j} = readSCell(fid);
      endfor
    endfor
  endfunction
