# load dtwclust
library(dtwclust)
# load parallel
library(parallel)
# create multi-process workers
workers <- makeCluster(detectCores())
# load dtwclust in each one, and make them use 1 thread per worker
invisible(clusterEvalQ(workers, {
    library(dtwclust)
    RcppParallel::setThreadOptions(1L)
}))
# register your workers, e.g. with doParallel
require(doParallel)
registerDoParallel(workers)

setwd("E:/tempFiles")

df <- read.csv("ndvi_ts_filtered_noheader.csv", header=FALSE)
df <- data.matrix(df)
head(df)

# register the parallel workers
registerDoParallel(workers)

# calculate distance matrix
pc <- tsclust(df,
              type = "partitional",
		  k = 40L,
		  distance = "dtw",
              centroid = "dba",
		  seed = 3247L,
              trace = TRUE)

clusters <- pc@cluster
write.csv(clusters, "dtwclusters_40cls.csv")
#pc

png('cluster21_40.png',width=3000, height=2000)
plot(pc, clus = 21:40)
dev.off()

cvi(pc,clus = 21:40)
cvi(pc, sample(df), type = c("ARI", "VI"))

