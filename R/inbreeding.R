
###############
## inbreeding
###############
inbreeding <- function(x, pop=NULL, truenames=TRUE, res.type=c("sample","function","estimate"), N=200, M=N*10){
    ## CHECKS ##
    if(!is.genind(x)) stop("x is not a valid genind object")
    checkType(x)
    res.type <- match.arg(res.type)[1]

    ## if(x$ploidy != 2) stop("this inbreeding coefficient is designed for diploid genotypes only")
    PLO <- ploidy(x)

    if(!is.null(pop)) pop(x) <- pop
    if(is.null(x@pop) && is.null(pop)) {
        pop(x) <- factor(rep(1, nrow(x@tab)))
    }

      ## COMPUTATIONS ##

    ## get allele frequencies and \sum p_i^2 by pop and loc ##
    ## (generalized to any ploidy) ##
    ## tabfreq2 <- (makefreq(x = genind2genpop(x, quiet = TRUE), quiet=TRUE, truenames=truenames)$tab) ^2
    tabfreq2 <- makefreq(x = genind2genpop(x, quiet = TRUE), quiet=TRUE) ^ PLO
    sumpi2 <- t(apply(tabfreq2, 1, tapply, x$loc.fac, sum))

    ## function to check a 1-locus genotype for homozigosity
    ## returns 1 if homoz, 0 otherwise
    ## !!! NOTE : reverse the values returned by f1 to obtain a strange thing !!!
    f1 <- function(gen){
        if(any(is.na(gen))) return(NA)
        if(any(round(gen, 10)==1)) return(1)
        return(0)
    }

    ## get the table of binary hetero/homo data
    if(truenames) {
        X <- truenames(x)$tab
    } else
    X <- x$tab

    homotab <- t(apply(X, 1, tapply, x@loc.fac, f1))


    ## get pi2 for the appropriate pop
    if(truenames){
    popx <- pop(x)
    } else {
        popx <- x$pop
    }

    popx <- as.character(popx)
    tabpi2 <- sumpi2[popx, , drop=FALSE]



    ## function returning a likelihood function - multi-locus ##
    ## x is a vector of 1/0 for each locus, with 1=homoz
    LIK <- function(x, sumpi2){
        ## return( sum(log(   x*(F+(1-F)*sumpi2) + (1-x)*(1-(F+(1-F)*sumpi2)) ) ,na.rm=TRUE) ) # returns the log-likelihood
        myEnv <- new.env()
        assign("x", x, envir=myEnv)
        assign("sumpi2", sumpi2, envir=myEnv)
        res <- function(F) {
            ## cat("\nx used:\n") # debugging
            ## print(x)
            ## cat("\nsumpi2 used:\n") # debugging
            ## print(sumpi2)

            return(exp(sum(log(   x*(F+(1-F)*sumpi2) + (1-x)*(1-(F+(1-F)*sumpi2)) ) ,na.rm=TRUE)))
        }
        environment(res) <- myEnv

        return(res)
    }


    ## get likelihood functions for all individuals
    res <- lapply(1:nrow(homotab), function(i) LIK(homotab[i,], tabpi2[i,]) )
    res <- lapply(res, Vectorize)

    ## name output
    if(truenames) {
        names(res) <- x$ind.names
    } else {
        names(res) <- names(x$tab)
    }


    ## IF WE RETURN FUNCTIONS ##
    if(res.type=="function"){
          return(res)
    }

    if (res.type == "estimate"){
      opfun <- function(x, ...) optimize(x, ...)[[1]]
      funval <- numeric(1)
      res <- vapply(res, FUN = opfun , FUN.VALUE = funval, interval = c(0, 1),
                    maximum = TRUE, tol = .Machine$double.eps^0.75)
      return(res)
    }


    ## IF WE RETURN SAMPLES ##
    ## function to get one sample
    getSample <- function(f){ # f is a vectorized density function
        x <- runif(M, 0, 1)
        fx <- f(x)
        fx <- fx - min(fx)
        if(sum(fx)<1e-14) {
            warning("Likelihood uniformly zero likely reflecting precision issue\nreturning uniformly distributed sample")
            return(runif(N))
        }
        fx <- fx/sum(fx)
        return(sample(x, size=N, prob=fx))
    }

    res <- lapply(res, getSample)
    return(res)
} # end inbreeding
