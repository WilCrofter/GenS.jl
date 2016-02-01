"""
createSMatrix(n, height, width, Sdata)
createSparseS(n, height, width, Sdata)
    
Given n, the number of transducer per probe, height and width of the grid, and nxn array of type Any produced by genS, the createSMatrix function returns a Float64 array which has n*n rows and height*width columns containing the segment length data.

Similarly, createSparseS creates a sparse matrix from  the same data using Julia's sparse function.

"""
function createSparseS(n::Int, height::Int, width::Int, Sdata::Array{Any,2})
# find the number of nonzero elements
    tot=0
    for (i in 1:n)
      for (j in 1:n) 
           tot = tot + length(Sdata[i,j][2])
      end #j
    end #i
# println(tot)
# create I, J and V vectors
    I=zeros(Int32,tot)
    J=zeros(Int32,tot)
    V=zeros(Float64,tot)
    ptr=1;
    row=1;
    for (j in 1:n)
       for (i in 1:n)
           len = length(Sdata[i,j][2])
	   I[ptr:(ptr+len-1)] = ones(Int32,len)*row
           J[ptr:(ptr+len-1)] = (Sdata[i,j][1][:,2]-1)*width + Sdata[i,j][1][:,1]
	   V[ptr:(ptr+len-1)] = Sdata[i,j][2][:]
	   row = row + 1
	   ptr = ptr + len
       end #i
    end #j
    out = sparse(I,J,V,n*n,height*width)
    return(out)
end #function 


function createSMatrix(n::Int, height::Int, width::Int, Sdata::Array{Any,2})
    out=Array{Float64}(height*width,n*n)
    row = 1
    for (j in 1:n)
       for (i in 1:n)
	      col = (Sdata[i,j][1][:,2]-1)*width + Sdata[i,j][1][:,1]
	      out[:,row] = sparsevec(col,Sdata[i,j][2][:],height*width)
	      println(row," ",col)
	      row = row + 1
        end #i loop
    end #j loop
    return(out')
end #function createMatrix

