
function issue3()
    r2 = Float64[-.1 8.1;   -.1 -0.1;     8.1 -0.1;    8.1 8.1]
    grid = 0.5
    width = height = 8;
    xmitr,rcvr = probePos(8,r2)
    data = genS(width,height,grid,xmitr,rcvr)
    for (j in 1:height)
      for (i in 1:width)
          Base.Test.@test all(1 .<= data[i,j][1] .<= 8)
      end #i
    end #j
    Any["All crossings inside grid" true];
end #function
