### WARNING: Run PsychometricFunction1.R first and do not close the R window. 

# sets working directories:
setwd("C:/Users/EJ/Dropbox/EJ/temp/BayesBook/test/CaseStudies/PsychophysicalFunctions")
library(R2jags)

################################################
# Part for model with contamination parameter
################################################

# Note: When monitoring multi-dimensional variables (such as z here),
# JAGS requires that they are completely specified. We use a trick here
# and specify z to be slightly larger than the maximum, and then
# adjust the model file to add "999" to the superfluous numbers.
# This is anything but pretty, so please let me know if you find a more
# elegant solution. 
parameters <- c("alpha","beta","z[1:8,1:30]")

# The following command calls JAGS with specific options.
# For a detailed description see the R2jags documentation.
samples <- jags(data, inits=myinits, parameters,
	 			model.file ="Psychophysical_2_jags.txt",
	 			n.chains=3, n.iter=10000, n.burnin=5000, n.thin=1)

# Extracting the necessary parameters
zmean <- list()
for (i in 1:8)
{
	ztemp <- matrix(NA,nstim[i],1)
	for (j in 1:nstim[i])
  {
		ztemp[j,] <- samples$BUGSoutput$summary[paste("z[",as.character(i),",",as.character(j),"]",sep=""),"mean"]
	}
	zmean[[i]] <- ztemp
}
alpha2	   <- samples$BUGSoutput$sims.list$alpha
beta2  	   <- samples$BUGSoutput$sims.list$beta
alphaMAP2  <- c(rep(0,nsubjs))
betaMAP2   <- c(rep(0,nsubjs))
alpha_sel2 <- matrix(NA,20,8) 
beta_sel2  <- matrix(NA,20,8) 

# Constructing MAP-estimates and alpha/beta range
for (i in 1:nsubjs)
{
	alphaMAP2[i]   <- density(alpha2[,i])$x[which(density(alpha2[,i])$y==max(density(alpha2[,i])$y))]
	betaMAP2[i]    <- density(beta2[,i])$x[which(density(beta2[,i])$y==max(density(beta2[,i])$y))]
	alpha_sel2[,i] <- sample(alpha2[,i],20)
	beta_sel2[,i]  <- sample(beta2[,i],20)
}
	
############################## PSYCHOMETRIC FUNCTIONS ##############################

F4 <- function(X,s) # only the MAP estimate; use this to plot psychometric functions
{
  exp(alphaMAP2[s] + betaMAP2[s]*(X - xmean[s]))/(1+exp(alphaMAP2[s] + betaMAP2[s]*(X - xmean[s])))
}

F4inv <- function(Y,s)
{
  (log(-Y/(Y-1))-alphaMAP2[s])/betaMAP2[s]
}

F5 <- function(X,s) # function for all the posterior alpha/beta values; use this to calculate JND posterior
{
  exp(alpha2[,s] + beta2[,s]*(X - xmean[s]))/(1+exp(alpha2[,s] + beta2[,s]*(X - xmean[s])))
}

F5inv <- function(Y,s)
{
  (log(-Y/(Y-1))-alpha2[,s])/beta2[,s]
}

F6 <- function(X,s,g) # function for 20 grabbed posterior alpha/beta values; use this to plot overlapping sigmoids to visualize variance
{
  exp(alpha_sel2[g,s] + beta_sel2[g,s]*(X - xmean[s]))/(1+exp(alpha_sel2[g,s] + beta_sel2[g,s]*(X - xmean[s])))
}

##################################### JND/PSE calculation ########################################

	JND2 	  <- F5inv(0.84,c(1:nsubjs))-F5inv(0.5,c(1:nsubjs))
	JNDmap2 <- F4inv(0.84,c(1:nsubjs))-F4inv(0.5,c(1:nsubjs))								  				             
	PSE2 	  <- F5inv(0.5,c(1:nsubjs))+xmean
	PSEmap2 <- F4inv(0.5,c(1:nsubjs))+xmean
		
################## PLOTS ####################

### Figure 12.6 
dev.new(width=10,height=5)
layout(matrix(1:nsubjs,2,4,byrow=T))
par(mar=c(1,2,2,0),oma=c(5,5,1,1))
for (i in 1:nsubjs)
{
	scale <- seq(x[i,1],x[i,nstim[i]], by=.1)
	plot(x[i,],rprop[i,],main=paste("Subject",as.character(i)),xlab="",ylab="",pch=22, col="black", bg=c(grey(1-zmean[[i]])), ylim=c(0,1), yaxt="n",xaxt="n")
	lines(scale,F1(scale,i),type="l", col="light grey",lwd=3)
	lines(scale,F4(scale,i),type="l")
	segments(x0=x[i,1],x1=PSEmap2[i]+JNDmap2[i],y0=0.84,lty=2)
	segments(x0=x[i,1],x1=PSEmap2[i],y0=0.5,lty=2)
	segments(y0=0,y1=0.84,x0=PSEmap2[i]+JNDmap2[i],lty=2)
	segments(y0=0,y1=0.5,x0=PSEmap2[i],lty=2)
	if (i==1 | i==5) 
  {
		axis(2,las=1,yaxp=c(0,1,2))
		axis(2,at=0.84,las=1)
	}
	if (i>4) 
    axis(1)
}
mtext("Proportion 'Long' Response",side=2,line=2,outer=T,cex=1.4)
mtext("Test Interval (ms)",side=1,outer=T,line=3,cex=1.4)

### Figure 12.7
	
dev.new(width=10,height=5)
layout(matrix(1:nsubjs,2,4,byrow=T))
par(mar=c(1,2,2,0),oma=c(5,5,1,1))
for (i in 1:nsubjs)
{
	plot(density(JND[,i]), col="dark grey", type="h", main=paste("Subject",as.character(i)), ylab="", xlab="", xlim=c(10,100), ylim=c(0,0.12), las=1,yaxt="n",xaxt="n")
	par(new=T)
	plot(density(JND2[,i]), col="light grey",type="h", main="",ylab="",xlab="",xlim=c(10,100),ylim=c(0,0.12),yaxt="n",xaxt="n",bty="n")
	par(new=F)
	if (i==1 | i==5) axis(2,las=1, yaxp=c(0,0.12,3))
	if (i>4) axis(1)
	if (i==4) legend("topright",c("non-contaminant model","contaminant model"),col=c("dark grey","light grey"),bty="n",pch=c(15,15))
}
mtext("Posterior Density",side=2,line=2,outer=T,cex=1.4)
mtext("JND (ms)",side=1,line=3,outer=T,cex=1.4)
