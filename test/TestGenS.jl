"""
module TestGenS

Tests for module GenS
"""
module TestGenS

export test_all

using GenS, Base.Test

# Rectangle outlining a section of thigh phantom.
r = Float64[8.243810336540204  91.17893727910730;
            16.075381869743303  31.69224559667868;
            190.887988558032134  54.70676187695501;
            183.056417024829045 114.19345355938363];


"""
test_wCrossings
    
Test crossings of equally spaced gridlines by comparison with R
in two simple cases.
"""
function test_wCrossings()
    # precision for comparison of R and Julia results
    epsilon = 1e-6;
    #= xlambda data was generated in R with the following code:
    source("R/utilities.R")
    u <- c(0.0, 30.0); v <- c(10.0, 30.0); w <- c(1.0, 0.0);
    gridsize <- 0.5
    k <- seq(0, 10.0, by=gridsize)
    lambda <- wCrossings(c(u,0), c(v,0), c(w,0), k)
    =#
    xlambda = vcat(0.00,0.05,0.10,0.15,0.20,0.25,0.30,0.35,
                   0.40,0.45,0.50,0.55,0.60,0.65,0.70,0.75,
                   0.80,0.85,0.90,0.95,1.00)
    # test vertical gridline crossings
    u = vcat(0.0,30.0); v = vcat(10.0,30.0); w = vcat(1.0,0.0);
    k = vcat(0.0:0.5:10.0)
    # xcrossings is true if R/Julia difference is small
    xcrossings = maximum(abs(xlambda- wCrossings(u, v, w, k))) < epsilon;
    #= ylambda data was generated with the following R code:
    u <- c(0.0, 0.25); v <- c(10.0, 8.1); w <- c(0.0, 1.0);
    gridsize <- 0.5
    k <- seq(0, 10.0, by=gridsize)
    ylambda <- wCrossings(c(u,0), c(v,0), c(w,0), k)
    =#
    ylambda = vcat(0.03184713,0.09554140,0.15923567,0.22292994,
                   0.28662420,0.35031847,0.41401274,0.47770701,
                   0.54140127,0.60509554,0.66878981,0.73248408,
                   0.79617834,0.85987261,0.92356688,0.98726115);
    # test horizontal gridline crossings
    u = vcat(0.0,0.25); v = vcat(10.0,8.1); w = vcat(0.0,1.0);
    k = vcat(0.0:0.5:10.0);
    # ycrossings is true if R/Julia difference is small
    ycrossings = maximum(abs(ylambda- wCrossings(u, v, w, k))) < epsilon;
    # test a case which once exposed a bug
    lambda = wCrossings(vcat(0.0,3.6), vcat(0.0,3.5), vcat(0.0, 1.0), collect(.5*(0:20)));
    scrossings = length(lambda) == 1 && lambda[1] == 1.0;
    @test xcrossings;
    @test ycrossings;
    @test scrossings;
    vcat(Any["wCrossings (vert) OK", xcrossings]',
         Any["wCrossings (hor) OK", ycrossings]',
         Any["wCrossings (slant) OK", scrossings]');
end

"""
test_gridCrossings()

Test gridCrossings by comparision with output from R function of the same name, and record time required to compute a realistic case. 
    
"""
function test_gridCrossings()
    epsilon = 1e-6;
    # rcrossings data was generated in R with the following code
    # source("R/utilities.R")
    # source("R/pixelated_thigh_utils.R")
    # rcrossings <- gridCrossings(c(0.0, 1.1), c(10.0, 8.3), .5, matrix(0,20,20))
    rcrossings = hcat(vcat(0.0000000,0.5000000,0.5555556,1.0000000,
                           1.2500000,1.5000000,1.9444444,2.0000000,
                           2.5000000,2.6388889,3.0000000,3.3333333,
                           3.5000000,4.0000000,4.0277778,4.5000000, 
                           4.7222222,5.0000000,5.4166667,5.5000000,
                           6.0000000,6.1111111,6.5000000,6.8055556,
                           7.0000000,7.5000000,8.0000000,8.1944444,
                           8.5000000,8.8888889,9.0000000,9.5000000,
                           9.5833333,10.0000000),
                      vcat(1.10,1.46,1.50,1.82,2.00,2.18,
                           2.50,2.54,2.90,3.00,3.26,3.50,
                           3.62,3.98,4.00,4.34,4.50,4.70,
                           5.00,5.06,5.42,5.50,5.78,6.00,
                           6.14,6.50,6.86,7.00,7.22,7.50,
                           7.58,7.94,8.00,8.30));
    u = vcat(0.0, 1.1); v=vcat(10.0, 8.3);
    crossings = gridCrossings(u, v, 20, 20, .5);
    # gridcrossings is true if R/Julia difference is small
    gridcrossings = maximum(abs(crossings-rcrossings)) < epsilon;
    @test gridcrossings;
    # add timing on a 400x120 grid
    vcat(Any["gridCrossings OK", gridcrossings]',
         Any["gridCrossings time", @elapsed gridCrossings(vcat(0.0,10.0), vcat(200.0, 57.3), 120, 400, .5)]');
end

"""
test_segmentLenths

Test derivation of segment lengths in a case which once caused a problem and
derive computation time for a realistic case. 
"""
function test_segmentLengths()
    # Test case  which once caused a problem. Line segment should
    # cross twenty pixels in order from 1,8 to 20,8 in sub-segments
    # of equal length.
    (indices, lengths) = segmentLengths(vcat(0.0, 3.6), vcat(10.0, 3.5), 20, 10, .5);
    bug1fixed = indices[:,1] == collect(1:20) && all(indices[:,2] .== 8) && all(lengths .== lengths[1]);
    # Time segment lengths
    tau = @elapsed for k in 1:1000
        u = Float64[0.0,   rand()*200];
        v = Float64[200.0, rand()*200];
        segmentLengths(u, v, 400, 400, .5)
    end
    @test bug1fixed;
    Any["segmentLengths OK" bug1fixed;
        "segmentLenths time" tau/1000];
end

"""
test_probePos
    
Test function `probePos` against arguments and results
from the R function of the same name.
"""
function test_probePos()
    
    # First probe as calculated in R
    probe1R = Float64[8.733283557365397 87.46101904895551;
                      9.712229999015785 80.02518258865193;
                      10.691176440666172 72.58934612834835;
                      11.670122882316559 65.15350966804478;
                      12.649069323966948 57.71767320774120;
                      13.628015765617334 50.28183674743762;
                      14.606962207267722 42.84600028713405;
                      15.585908648918110 35.41016382683047];
    # Second
    probe2R = Float64[190.3985153372069  58.42468010710679;
                      189.4195688955566  65.86051656741037;
                      188.4406224539062  73.29635302771395;
                      187.4616760122558  80.73218948801753;
                      186.4827295706054  88.16802594832112;
                      185.5037831289550  95.60386240862468;
                      184.5248366873046 103.03969886892827;
                      183.5458902456542 110.47553532923183];
    # Reverse probe2R order for consistency with previous work.
    probe2R = probe2R[8:-1:1,:]
    # Calculate probes in Julia
    probe1, probe2 = probePos(8, r);
    probe1_OK =  all(abs(probe1-probe1R) .< 1e-9);
    probe2_OK =  all(abs(probe2-probe2R) .< 1e-9);
    Any["probePos probe 1 OK" probe1_OK;
        "probePos probe 2 OK" probe2_OK];
end

"""
test_genS

Time generation of non-zero S matrix entries on a large grid and
the given number of transducers per probe. Also, read and write
results from a small case to ensure type compatability with IO
functions.
"""
function test_genS(ntrans::Int)
    # Grid is taken from highest-resolution pixelated thigh phantom.
    gridsize = 0.47;
    height = 424;
    width = 403;
    # r, a rectangle, is defined above
    xmitr, rcvr = probePos(ntrans, r);
    # timing for generation of S matrix data
    tau = @elapsed data = genS(width, height, gridsize, xmitr, rcvr);
    #write and read a smaller case to check type consistency with I/O
    xmitr, rcvr = probePos(16, r);
    data = genS(width, height, gridsize, xmitr, rcvr);
    tmp = tempname();
    stream = open(tmp, "w");
    writeSData(stream, Int32(width), Int32(height), gridsize, xmitr, rcvr, data);
    close(stream);
    stream = open(tmp, "r");
    (w, h, g, xm, rc, dat) = readSData(stream);
    close(stream);
    ioOK = dat == data;
    return Any["genS I/O consistency OK" ioOK;
               "genS time (128 transducers)" tau];
end

"""
randomCell
    
Create a small random cell
"""
function randomCell(n)
    # random Int32 coordinates between 1 & n
    pixcoords = rand(collect(Int32,1:n), n, 2);
    # random Float64 lengths between 0 and 1
    lens = rand(n);
    # return random cell
    return Any[pixcoords, lens];
end

"""
test_rwCell(filepath=tempname())
    
Test writeCell and readCell using a random cell with correct data types.
Ensure that data written and re-read is identical to original.
"""
function test_rwCell(filepath::AbstractString = tempname())
    mycell = randomCell(10);
    # open the given file for writing
    stream = open(filepath, "w");
    # write the cell
    writeCell(stream, mycell);
    # close the file
    close(stream);
    # open it for reading
    stream = open(filepath, "r");
    # read the cell
    rdcell = readCell(stream);
    close(stream);
    cellio_OK = rdcell == mycell;
    Any["cell io OK", cellio_OK]';
end

"""
test_rwSData(filepath=tempname())
    
Test writeSData and readSData using a random data with correct types.
Ensure that data written and re-read is identical to original.
"""
function test_rwSData(filepath::AbstractString = tempname())
    # Create S matrix data of the correct types
    # but otherwise random.
    ntrans = 16; # 16 transducers
    xmitr = reshape(rand(32), 16, 2); # 16 random points
    rcvr = reshape(rand(32), 16, 2) ; # same
    gridsize = 0.5;
    height = Int32(16); # 16 pixels vertical
    width = Int32(64); # 64 pixels horizontal
    data = Array(Any, 16, 16); # 256 tranmit/receive pairs
    for j in 1:16
        for i in 1:16
            data[i,j] = randomCell(rand(64:80));
        end
    end
    stream = open(filepath, "w");
    writeSData(stream, width, height, gridsize,
               xmitr, rcvr, data);
    close(stream);
    stream = open(filepath, "r");
    (w, h, g, x, r, dat) = readSData(stream);
    close(stream);
    @test w == width;
    @test h == height;
    @test g == gridsize;
    @test x == xmitr;
    @test r == rcvr;
    @test dat == data;
    hcat(Any["IO: width OK", w == width],
         Any["IO: height OK", h == height],
         Any["IO: gridsize OK", g == gridsize],
         Any["IO: transmitters OK", x == xmitr],
         Any["IO: receivers OK", r == rcvr],
         Any["IO: data OK", dat == data]
         )' 
end

function testCellIO(filepath::AbstractString)
    # cell I0 test is included
    test_rwSData(filepath);
end

include("issue3.jl")

function test_all()
    vcat(test_wCrossings(), test_gridCrossings(), test_segmentLengths(),
         test_probePos(), test_rwSData(), test_genS(128), issue3());
end

end

