###########################
#
# Auxiliary functions for
# adegenet objects
#
# T. Jombart
###########################

##############################
# Method truenames for genind
##############################
setGeneric("truenames", function(x) standardGeneric("truenames"))

setMethod("truenames", signature(x="genind"), function(x){
    message("This accessor is now deprecated. Please use 'tab' instead.")
    return(x@tab)
})



##############################
# Method truenames for genpop
##############################
setMethod("truenames",signature(x="genpop"), function(x){
    message("This accessor is now deprecated. Please use 'tab' instead.")
    return(x@tab)
})




###########################
## Generic / methods 'tab'
###########################
#'
#' Access allele counts or frequencies
#'
#' This accessor is used to retrieve a matrix of allele data.
#' By default, a matrix of integers representing allele counts is returned.
#' If \code{freq} is TRUE, then data are standardised as frequencies, so that for any individual and any locus the data sum to 1.
#' The argument \code{NA.method} allows to replace missing data (NAs).
#' This accessor replaces the previous function \code{truenames} as well as the function \code{makefreq}.
#'
#' @export
#'
#' @aliases tab
#'
#' @rdname tab
#'
#' @docType methods
#'
#' @param x a \linkS4class{genind} or \linkS4class{genpop} object.
#' @param freq a logical indicating if data should be transformed into relative frequencies (TRUE); defaults to FALSE.
#' @param NA.method a method to replace NA; asis: leave NAs as is; mean: replace by the mean allele frequencies; zero: replace by zero
#' @param ... further arguments passed to other methods.
#' @return a matrix of integers or numeric
#'
#' @examples
#'
#' data(microbov)
#' head(tab(microbov))
#' head(tab(microbov,freq=TRUE))
#'
#'
setGeneric("tab", function(x, ...) standardGeneric("tab"))

.tabGetter <- function(x, freq=FALSE, NA.method=c("asis","mean","zero"), ...){
    ## handle arguments
    NA.method <- match.arg(NA.method)

    ## get matrix of data
    if(!freq){
        out <- x@tab
    } else {
        out <- x@tab/x@ploidy
    }

    ## replace NAs if needed
    if(NA.method=="mean"){
        f1 <- function(vec){
            m <- mean(vec,na.rm=TRUE)
            vec[is.na(vec)] <- m
            return(vec)
        }

        out <- apply(out, 2, f1)
    }
    if(NA.method=="zero"){
        out[is.na(out)] <- ifelse(freq, 0, 0L)
    }

    ## return output
    return(out)
}

#' @rdname tab
#' @aliases tab,genind-methods
#' @aliases tab.genind
setMethod("tab", signature(x = "genind"), 
          function (x, freq = FALSE, NA.method = c("asis","mean","zero"), ...){
            .tabGetter(x, freq = freq, NA.method = NA.method, ...)
          })



#' @rdname tab
#' @aliases tab,genpop-methods
#' @aliases tab.genpop

setMethod("tab", signature(x="genpop"), function(x, freq=FALSE, NA.method=c("asis","mean","zero"), ...){
 ## handle arguments
    NA.method <- match.arg(NA.method)

    ## get matrix of data
    if(!freq) {
        out <- x@tab
    } else {
        out <- x@tab
        f1 <- function(vec) return(vec/sum(vec,na.rm=TRUE))
        ## compute frequencies
        out <- apply(x@tab, 1, tapply, x@loc.fac,f1)
        ## reshape into matrix
        col.names <- do.call(c,lapply(out[[1]],names))
        row.names <- names(out)
        out <- matrix(unlist(out), byrow=TRUE, nrow=nrow(x@tab),
                      dimnames=list(row.names, col.names))
        ## reorder columns
        out <- out[,colnames(x@tab)]
    }

    ## replace NAs if needed
    if(NA.method=="mean"){
        f1 <- function(vec){
            m <- mean(vec,na.rm=TRUE)
            vec[is.na(vec)] <- m
            return(vec)
        }

        out <- apply(out, 2, f1)
    }
    if(NA.method=="zero"){
        out[is.na(out)] <- ifelse(freq, 0, 0L)
    }

    ## return output
    return(out)
})




###########################
# Method seploc for genind
###########################
setGeneric("seploc", function(x, ...) standardGeneric("seploc"))

setMethod("seploc", signature(x="genind"), function(x,truenames=TRUE,res.type=c("genind","matrix")){
    truenames <- TRUE # this argument will be deprecated
    if(x@type=="PA"){
        msg <- paste("seploc is not implemented for presence/absence markers")
        cat("\n",msg,"\n")
        return(invisible())
    }

    if(!is.genind(x)) stop("x is not a valid genind object")
    res.type <- match.arg(res.type)

    ## make separate tables
    kX <- list()
    locfac.char <- as.character(x@loc.fac)
    for(i in locNames(x)){
        kX[[i]] <- x@tab[, i==locfac.char,drop=FALSE]
    }

    prevcall <- match.call()
    if(res.type=="genind"){
        ## ploidy bug fixed by Zhian N. Kamvar
        ##kX <- lapply(kX, genind, pop=x@pop, prevcall=prevcall)
        kX <- lapply(kX, genind, pop=x@pop, prevcall=prevcall, ploidy=x@ploidy, type=x@type)
        for(i in 1:length(kX)){
            kX[[i]]@other <- x@other
        }
    }

    return(kX)
})



###########################
# Method seploc for genpop
###########################
setMethod("seploc", signature(x="genpop"), function(x,truenames=TRUE,res.type=c("genpop","matrix")){
    truenames <- TRUE # this argument will be deprecated
    if(x@type=="PA"){
         msg <- paste("seploc is not implemented for presence/absence markers")
         cat("\n",msg,"\n")
         return(invisible())
    }


    if(!is.genpop(x)) stop("x is not a valid genpop object")
    res.type <- match.arg(res.type)
    if(res.type=="genpop") { truenames <- TRUE }

    temp <- x@loc.fac
    nloc <- length(levels(temp))
    levels(temp) <- 1:nloc

    ## make separate tables
    kX <- list()
    locfac.char <- as.character(x@loc.fac)
    for(i in locNames(x)){
        kX[[i]] <- x@tab[,i==locfac.char,drop=FALSE]
    }

    names(kX) <- x@loc.names

    prevcall <- match.call()
    if(res.type=="genpop"){
        kX <- lapply(kX, genpop, prevcall=prevcall, ploidy=x@ploidy, type=x@type)
        for(i in 1:length(kX)){
            kX[[i]]@other <- x@other
        }
    }

    return(kX)
})





###############
# '$' operator
###############
setMethod("$","genind",function(x,name) {
    return(slot(x,name))
})


setMethod("$<-","genind",function(x,name,value) {
   slot(x,name,check=TRUE) <- value
  return(x)
})







##################
# Function seppop
##################
setGeneric("seppop", function(x, ...) standardGeneric("seppop"))

## genind
setMethod("seppop", signature(x="genind"), function(x,pop=NULL,truenames=TRUE,res.type=c("genind","matrix"),
                              drop=FALSE, treatOther=TRUE, quiet=TRUE){
    ## checkType(x)
    truenames <- TRUE # this argument will be deprecated

    ## misc checks
    if(!is.genind(x)) stop("x is not a valid genind object")
    if(is.null(pop)) { # pop taken from @pop
        if(is.null(x@pop)) stop("pop not provided and x@pop is empty")
        pop <- pop(x)
    } else {
        pop <- factor(pop)
    }


    res.type <- match.arg(res.type)

    ## pop <- x@pop # comment to take pop arg into account

    ## make a list of genind objects
    kObj <- lapply(levels(pop), function(lev) x[pop==lev, , drop=drop, treatOther=treatOther, quiet=quiet])
    names(kObj) <- levels(pop)

    ## res is a list of genind
    if(res.type=="genind"){ return(kObj) }

    ## res is list of matrices
    res <- lapply(kObj, function(obj) tab(obj))

    return(res)
}) # end seppop







## #####################
## # Methods na.replace
## #####################
## setGeneric("na.replace", function(x, ...) standardGeneric("na.replace"))

## ## genind method
## setMethod("na.replace", signature(x="genind"), function(x, method, quiet=FALSE){
##     ## checkType(x)

##     ## preliminary stuff
##     validObject(x)
##     if(!any(is.na(x@tab))) {
##         if(!quiet) cat("\n Replaced 0 missing values \n")
##         return(x)
##     }
##     method <- tolower(method)
##     method <- match.arg(method, c("0","mean"))

##     res <- x

##     if(method=="0"){
##         res@tab[is.na(x@tab)] <- 0
##     }

##     if(method=="mean"){
##         f1 <- function(vec){
##             m <- mean(vec,na.rm=TRUE)
##             vec[is.na(vec)] <- m
##             return(vec)
##         }

##         res@tab <- apply(x@tab, 2, f1)
##     }

##     if(!quiet){
##         Nna <- sum(is.na(x@tab))
##         cat("\n Replaced",Nna,"missing values \n")
##     }

##     return(res)

## })




## ## genpop method
## setMethod("na.replace", signature(x="genpop"), function(x,method, quiet=FALSE){
##     ## checkType(x)

##     ## preliminary stuff
##     validObject(x)
##     if(!any(is.na(x@tab))) {
##         if(!quiet) cat("\n Replaced 0 missing values \n")
##         return(x)
##     }

##     method <- tolower(method)
##     method <- match.arg(method, c("0","chi2"))

##     res <- x

##     if(method=="0"){
##         res@tab[is.na(x@tab)] <- 0
##     }

##     if(method=="chi2"){
##         ## compute theoretical counts
##         ## (same as in a Chi-squared)
##         X <- x@tab
##         sumPop <- apply(X,1,sum,na.rm=TRUE)
##         sumLoc <- apply(X,2,sum,na.rm=TRUE)
##         X.theo <- sumPop %o% sumLoc / sum(X,na.rm=TRUE)

##         X[is.na(X)] <- X.theo[is.na(X)]
##         res@tab <- X
##     }

##     if(!quiet){
##         Nna <- sum(is.na(x@tab))
##         cat("\n Replaced",Nna,"missing values \n")
##     }

##     return(res)
## })

# Function to bind strata from a list of genind objects and return a single
# genind object.
.rbind_strata <- function(myList, res){
    strata_list <- lapply(myList, slot, "strata")
    null_strata <- vapply(strata_list, is.null, TRUE)
    if (!all(null_strata)){
        # NULL strata must be converted to data frames.
        # Solution: take the first non-empty strata, and create a new one 
        # with one variable.
        if (any(null_strata)){

            # Extract the name of the first column of the first full strata
            fullname <- names(strata_list[[which(!null_strata)[1]]])[1]
            
            # loop over all the empty strata and replace them with a data
            # frame that has the same number of elements as the samples in that
            # genlight object.
            for (i in which(null_strata)){
                replace_strata        <- data.frame(rep(NA, nInd(myList[[i]])))
                names(replace_strata) <- fullname
                strata_list[[i]]      <- replace_strata
            }
        }
        strata(res) <- as.data.frame(suppressWarnings(dplyr::bind_rows(strata_list)))        
    } else {
        res@strata <- NULL
    }
    return(res)
}


##################
# Function repool
##################
repool <- function(...){

    ## preliminary stuff
    x <- list(...)
    if(is.list(x[[1]])) x <- x[[1]] ## if ... is a list, keep this list for x
    if(!inherits(x,"list")) stop("x must be a list")
    if(!all(sapply(x,is.genind))) stop("x is does not contain only valid genind objects")
    temp <- sapply(x,function(e) e$loc.names)
    if(!all(table(temp)==length(x))) stop("markers are not the same for all objects")
    ## temp <- sapply(x,function(e) e$ploidy)
    ## if(length(unique(temp)) != as.integer(1)) stop("objects have different levels of ploidy")



    ## extract info
    listTab <- lapply(x,genind2df,usepop=FALSE,sep="/")
    newPloidy <- unlist(lapply(x,ploidy))

    getPop <- function(obj){
        if(is.null(obj$pop)) return(factor(rep(NA,nrow(obj$tab))))
        pop <- obj$pop
        levels(pop) <- obj$pop.names
        return(pop)
    }

    ## handle pop
    listPop <- lapply(x, getPop)
    pop <- unlist(listPop, use.names=FALSE)
    pop <- factor(pop)

    ## handle genotypes
    markNames <- colnames(listTab[[1]])
    listTab <- lapply(listTab, function(tab) tab[,markNames,drop=FALSE]) # resorting of the tabs

    ## bind all tabs by rows
    tab <- listTab[[1]]
    for(i in 2:length(x)){
        tab <- rbind(tab,listTab[[i]])
    }
    
    res <- df2genind(tab, pop=pop, ploidy=newPloidy, type=x[[1]]@type, sep="/")
    res <- .rbind_strata(x, res)
    res@hierarchy <- NULL
    res$call <- match.call()

    return(res)
} # end repool





#############
# selpopsize
#############
setGeneric("selPopSize", function(x, ...) standardGeneric("selPopSize"))

## genind method ##
setMethod("selPopSize", signature(x="genind"), function(x,pop=NULL,nMin=10){

    ## misc checks
    ## checkType(x)
    if(!is.genind(x)) stop("x is not a valid genind object")
    if(is.null(pop)) { # pop taken from @pop
        if(is.null(x@pop)) stop("pop not provided and x@pop is empty")
        pop <- pop(x)
    } else{
        pop <- factor(pop)
    }

    ## select retained individuals
    effPop <- table(pop)
    popOk <- names(effPop)[effPop >= nMin]
    toKeep <- pop %in% popOk

    ## build result
    res <- x[toKeep]
    pop(res) <- pop[toKeep]

    return(res)
}) # end selPopSize





#########
# isPoly
#########
setGeneric("isPoly", function(x, ...) standardGeneric("isPoly"))

## genind method ##
setMethod("isPoly", signature(x="genind"), function(x, by=c("locus","allele"), thres=1/100){

    ## misc checks
    ## checkType(x)
    if(!is.genind(x)) stop("x is not a valid genind object")
    by <- match.arg(by)


    ## main computations ##

    ## PA case ##
    if(x@type=="PA") {
        allNb <- apply(x@tab, 2, mean, na.rm=TRUE) # allele frequencies
        toKeep <- (allNb >= thres) & (allNb <= (1-thres))
        return(toKeep)
    }


    ## codom case ##
    allNb <- apply(x@tab, 2, sum, na.rm=TRUE) # allele absolute frequencies

    if(by=="locus"){
        f1 <- function(vec){
            if(sum(vec) < 1e-10) return(FALSE)
            vec <- vec/sum(vec, na.rm=TRUE)
            if(sum(vec >= thres) >= 2) return(TRUE)
            return(FALSE)
        }

        toKeep <- tapply(allNb, x@loc.fac, f1)
    } else { # i.e. if mode==allele
        toKeep <- (allNb >= thres)
    }

    return(toKeep)
}) # end isPoly





## ## genpop method ##
## setMethod("isPoly", signature(x="genpop"), function(x, by=c("locus","allele"), thres=1/100){

##     ## misc checks
##     checkType(x)
##     if(!is.genpop(x)) stop("x is not a valid genind object")
##     by <- match.arg(by)


##     ## main computations ##
##     ## ## PA case ##
## ##     if(x@type=="PA") {
## ##         allNb <- apply(x@tab, 2, mean, na.rm=TRUE) # allele frequencies
## ##         toKeep <- (allNb >= thres) & (allNb <= (1-thres))
## ##         return(toKeep)
## ##     }


##     ## codom case ##
##     allNb <- apply(x@tab, 2, sum, na.rm=TRUE) # alleles absolute frequencies

##     if(by=="locus"){
##         f1 <- function(vec){
##             if(sum(vec) < 1e-10) return(FALSE)
##             vec <- vec/sum(vec, na.rm=TRUE)
##             if(sum(vec >= thres) >= 2) return(TRUE)
##             return(FALSE)
##         }

##         toKeep <- tapply(allNb, x@loc.fac, f1)
##     } else { # i.e. if mode==allele
##         toKeep <- allNb >= thres
##     }

##     return(toKeep)
## }) # end isPoly





######################
## miscellanous utils
######################

#######
# nLoc
#######
setGeneric("nLoc", function(x,...){
    standardGeneric("nLoc")
})



setMethod("nLoc","genind", function(x,...){
    return(length(x@loc.names))
})



setMethod("nLoc","genpop", function(x,...){
    return(length(x@loc.names))
})


#######
# nPop
#######
setGeneric("nPop", function(x,...){
    standardGeneric("nPop")
})



setMethod("nPop","genind", function(x,...){
    return(length(x@pop.names))
})



setMethod("nPop","genpop", function(x,...){
    return(length(x@pop.names))
})


#######
# nInd
#######
setGeneric("nInd", function(x,...){
    standardGeneric("nInd")
})



setMethod("nInd","genind", function(x,...){
    return(nrow(x@tab))
})





######
# pop
######
setGeneric("pop", function(x) {
  standardGeneric("pop")
})



setGeneric("pop<-",
           function(x, value) {
               standardGeneric("pop<-")
           })



setMethod("pop","genind", function(x){
    if(is.null(x@pop)) return(NULL)
    res <- x@pop
    levels(res) <- x@pop.names
    return(res)
})



setReplaceMethod("pop", "genind", function(x, value) {
    if(is.null(value)){
        x@pop <- NULL
        x@pop.names <- NULL
        return(x)
    }

    if(length(value) != nrow(x$tab)) stop("wrong length for population factor")

    ## coerce to factor (put levels in their order of appearance)
    newPop <- as.character(value)
    newPop <- factor(newPop, levels=unique(newPop))

    ## generic labels
    newPop.lab <- .genlab("P",length(levels(newPop)) )

    ## construct output
    x$pop.names <- levels(newPop)
    levels(newPop) <- newPop.lab
    x$pop <- newPop

    return(x)
})





###########
# locNames
###########
setGeneric("locNames", function(x,...){
    standardGeneric("locNames")
})

setGeneric("locNames<-", function(x, value) {
    standardGeneric("locNames<-")
})


setMethod("locNames","genind", function(x, withAlleles=FALSE, ...){
    ## return simply locus names
    if(x@type=="PA" | !withAlleles) return(x@loc.names)

    ## return locus.allele
    res <- rep(x@loc.names, x@loc.nall)
    res <- paste(res,unlist(x@all.names),sep=".")
    return(res)
})


setReplaceMethod("locNames","genind",function(x,value) {
    value <- as.character(value)
    if(length(value) != nLoc(x)) stop("Vector length does no match number of loci")
    names(value) <- names(locNames(x))
    slot(x,"loc.names",check=TRUE) <- value
    return(x)
})


setMethod("locNames","genpop", function(x, withAlleles=FALSE, ...){
    ## return simply locus names
    if(x@type=="PA" | !withAlleles) return(x@loc.names)

    ## return locus.allele
    res <- rep(x@loc.names, x@loc.nall)
    res <- paste(res,unlist(x@all.names),sep=".")
    return(res)
})


setReplaceMethod("locNames","genpop",function(x,value) {
    value <- as.character(value)
    if(length(value) != nLoc(x)) stop("Vector length does no match number of loci")
    names(value) <- names(locNames(x))
    slot(x,"loc.names",check=TRUE) <- value
    return(x)
})


###########
# indNames
###########
setGeneric("indNames", function(x,...){
    standardGeneric("indNames")
})

setGeneric("indNames<-", function(x, value){
    standardGeneric("indNames<-")
})

setMethod("indNames","genind", function(x, ...){
    return(rownames(x@tab))
})


setReplaceMethod("indNames","genind",function(x,value) {
    value <- as.character(value)
    if(length(value) != nInd(x)) stop("Vector length does not match number of individuals")
    slot(x,"ind.names",check=TRUE) <- value
    rownames(x@tab) <- value
    return(x)
})

setGeneric("popNames", function(x,...){
  standardGeneric("popNames")
})

setGeneric("popNames<-", function(x, value){
  standardGeneric("popNames<-")
})

setMethod("popNames","genind", function(x, ...){
  return(levels(pop(x)))
})


setReplaceMethod("popNames","genind",function(x, value) {
  value <- as.character(value)
  if(length(value) != length(levels(pop(x)))){
    stop("Vector length does not match number of populations")
  }
  slot(x, "pop.names", check=TRUE) <- value
  levels(pop(x)) <- value
  return(x)
})

setMethod("popNames","genpop", function(x, ...){
  return(x@pop.names)
})


setReplaceMethod("popNames","genpop",function(x, value) {
  value <- as.character(value)
  if (length(value) != nrow(x@tab)){
    stop("Vector length does not match number of populations")
  }
  slot(x, "pop.names", check=TRUE) <- value
  rownames(x@tab) <- value
  return(x)
})


##########
# alleles
##########
setGeneric("alleles", function(x,...){
    standardGeneric("alleles")
})

setGeneric("alleles<-", function(x, value){
    standardGeneric("alleles<-")
})

setMethod("alleles","genind", function(x, ...){
    return(x@all.names)
})

setReplaceMethod("alleles","genind", function(x, value){
    if(!is.list(value)) stop("replacement value must be a list")
    if(length(value)!=nLoc(x)) stop("replacement list must be of length nLoc(x)")
    if(any(sapply(value, length) != x$loc.nall)) stop("number of replacement alleles do not match that of the object")
    x@all.names <- value
    return(x)
})


setMethod("alleles","genpop", function(x, ...){
    return(x@all.names)
})

setReplaceMethod("alleles","genpop", function(x, value){
    if(!is.list(value)) stop("replacement value must be a list")
    if(length(value)!=nLoc(x)) stop("replacement list must be of length nLoc(x)")
    if(any(sapply(value, length) != x$loc.nall)) stop("number of replacement alleles do not match that of the object")
    x@all.names <- value
    return(x)
})



##########
## ploidy
##########
setGeneric("ploidy", function(x,...){
    standardGeneric("ploidy")
})

setGeneric("ploidy<-", function(x, value){
    standardGeneric("ploidy<-")
})

setMethod("ploidy","genind", function(x,...){
    return(x@ploidy)
})


setReplaceMethod("ploidy","genind",function(x,value) {
    value <- as.integer(value)
    if(any(value)<1) stop("Negative or null values provided")
    if(any(is.na(value))) stop("NA values provided")
    if(length(value)!=nInd(x)) value <- rep(value, length=nInd(x))
    slot(x,"ploidy",check=TRUE) <- value
    return(x)
})


setMethod("ploidy","genpop", function(x,...){
    return(x@ploidy)
})


setReplaceMethod("ploidy","genpop",function(x,value) {
    value <- as.integer(value)
    if(any(value)<1) stop("Negative or null values provided")
    if(any(is.na(value))) stop("NA values provided")
    if(length(value)>1) warning("Several ploidy numbers provided; using only the first integer")
    slot(x,"ploidy",check=TRUE) <- value[1]
    return(x)
})






##########
## other
#########
setGeneric("other", function(x,...){
    standardGeneric("other")
})

setGeneric("other<-", function(x, value){
    standardGeneric("other<-")
})

setMethod("other","genind", function(x,...){
    if(length(x@other)==0) return(NULL)
    return(x@other)
})


setReplaceMethod("other","genind",function(x,value) {
    if( !is.null(value) && (!is.list(value) | is.data.frame(value)) ) {
        value <- list(value)
    }
    slot(x,"other",check=TRUE) <- value
    return(x)
})


setMethod("other","genpop", function(x,...){
    if(length(x@other)==0) return(NULL)
    return(x@other)
})


setReplaceMethod("other","genpop",function(x,value) {
    if( !is.null(value) && (!is.list(value) | is.data.frame(value)) ) {
        value <- list(value)
    }
    slot(x,"other",check=TRUE) <- value
    return(x)
})


