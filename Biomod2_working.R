library(biomod2)

setwd("E:\\biomod")

# species occurrences
DataSpecies <- read.csv("E:\\biomod\\DataSpecies.csv")
head(DataSpecies)

# the name of studied species
myRespName <- 'Rice'

# the presence/absences data for our species 
myResp <- as.numeric(DataSpecies[,myRespName])

# the XY coordinates of species data
myRespXY <- DataSpecies[,c("X_WGS84","Y_WGS84")]

climDir_baseline <- list.files("E:\\biomod\\Current", pattern=".asc$",full.names = TRUE)
climDir_future <- list.files("E:\\biomod\\Future", pattern=".asc$",full.names = TRUE)


# Environmental variables from BIOCLIM
myExpl_b = stack(climDir_baseline)
myExpl_f = stack(climDir_future)

# 1. Formatting Data
myBiomodData <- BIOMOD_FormatingData(resp.var = myResp,
                                     expl.var = myExpl_b,
                                     resp.xy = myRespXY,
                                     resp.name = myRespName,
                                     PA.nb.rep = 2,
                                     PA.nb.absences = 4000,
                                     PA.strategy = 'sre',
                                     PA.dist.min = 0,
                                     PA.dist.max = NULL,
                                     PA.sre.quant = 0.025
                                     )

# 2. Defining Models Options using default options.
myBiomodOption <- BIOMOD_ModelingOptions()


# 3. Doing Modelisation
myBiomodModelOut <- BIOMOD_Modeling( myBiomodData, 
                                     models = c('GLM','ANN','RF'), 
                                     models.options = models.options = BIOMOD_ModelingOptions(RF = list(do.classif = FALSE, ntree = 500, importance = TRUE, norm.votes = TRUE)), 
                                     NbRunEval=2, 
                                     DataSplit=80,
                                     Prevalence = 0.5,
                                     VarImport=3, 
                                     models.eval.meth = c('TSS','ROC'),
                                     SaveObj = TRUE,
                                     rescal.all.models = TRUE,
                                     do.full.models=FALSE,
                                     modeling.id=paste(myRespName, "Prediction", sep=""))

## print a summary of modeling stuff
myBiomodModelOut

myBiomodModelEval <- get_evaluations(myBiomodModelOut)

sink("E:/biomod/biomod_eval.txt")
myBiomodModelEval
sink()

sink("E:/biomod/biomod_varimp.txt")
get_variables_importance(myBiomodModelOut)
sink()

# let's print the TSS scores of Random Forest
myBiomodModelEval["TSS","Testing.data","RF",,]

# let's print the ROC scores of all selected models
myBiomodModelEval["ROC","Testing.data",,,]

# print variable importances
get_variables_importance(myBiomodModelOut)

#time for ensemble
myBiomodEM <- BIOMOD_EnsembleModeling(
  modeling.output = myBiomodModelOut,
  chosen.models = 'all',
  em.by='all',
  eval.metric = c('ROC'),
  eval.metric.quality.threshold = c(0.7),
  prob.mean = T,
  prob.cv = T,
  prob.ci = T,
  prob.ci.alpha = 0.05,
  prob.median = T,
  committee.averaging = T,
  prob.mean.weight = T,
  prob.mean.weight.decay = 'proportional')

# print summary
myBiomodEM

myBiomodEMEval <- get_evaluations(myBiomodEM)

sink("E:/biomod/biomod_EM_eval.txt")
myBiomodEMEval
sink()

myBiomodProj <- BIOMOD_Projection(
  modeling.output = myBiomodModelOut,
  new.env = myExpl_b,
  proj.name = 'current',
  selected.models = 'all',
  binary.meth = 'TSS',
  compress = 'xz',
  clamping.mask = F,
  output.format = '.img')

# summary of crated oject
myBiomodProj

# files created on hard drive
list.files("Rice/proj_current/")

# if you want to make custom plots, you can also get the projected map
myCurrentProj <- get_predictions(myBiomodProj)
myCurrentProj

myBiomodProjFuture <- BIOMOD_Projection(
  modeling.output = myBiomodModelOut,
  new.env = myExpl_f,
  proj.name = 'future',
  selected.models = 'all',
  binary.meth = 'TSS',
  compress = 'xz',
  clamping.mask = T,
  output.format = '.img')

# make some plots, sub-selected by str.grep argument
plot(myBiomodProjFuture, str.grep = 'GLM')

myBiomodEF_current <- BIOMOD_EnsembleForecasting(
  EM.output = myBiomodEM,
  projection.output = myBiomodProj)

myBiomodEF_current
# reduce layer names for plotting convegences
plot(myBiomodEF_current)

myBiomodEF_future <- BIOMOD_EnsembleForecasting(
  EM.output = myBiomodEM,
  projection.output = myBiomodProjFuture)

myBiomodEF_future
# reduce layer names for plotting convegences
plot(myBiomodEF_future)

#myBiomodModelOut <- BIOMOD_Modeling(
#  myBiomodData,
#  models = c('GLM','ANN','RF'),
#  models.options = BIOMOD_ModelingOptions(),
#  NbRunEval=10,
#  DataSplit=80,
#  Prevalence=0.5,
#  VarImport=3,
#  models.eval.meth = c('TSS','ROC'),
#  SaveObj = TRUE,
#  rescal.all.models = TRUE,
#  do.full.models = FALSE,
#  modeling.id = paste(myRespName,"FirstModeling",sep=""))