########################################################################
# adegenet classes definitions. All classes are S4.
#
# Thibaut Jombart, November 2007
# t.jombart@imperial.ac.uk
########################################################################

###############################
# Two classes of R object are
# defined :
# gen - common part to genind and genpop
# genind - genotypes of individuals
# genpop - allelic frequencies of populations
###############################


###############################################################
###############################################################
# AUXILIARY FUNCTIONS
###############################################################
###############################################################




###############################################################
###############################################################
# CLASSES DEFINITION
###############################################################
###############################################################

##.initAdegenetClasses <- function(){


####################
# Unions of classes
####################
setClassUnion("listOrNULL", c("list","NULL"))
setClassUnion("factorOrNULL", c("factor","NULL"))
setClassUnion("charOrNULL", c("character","NULL"))
setClassUnion("callOrNULL", c("call","NULL"))
setClassUnion("intOrNum", c("integer","numeric","NULL"))
setClassUnion("intOrNULL", c("integer","NULL"))
setClassUnion("dfOrNULL", c("data.frame", "NULL"))
setClassUnion("formOrNULL", c("formula", "NULL"))


####################
# virtual class gen
####################
.gen.valid <- function(object){
  # this function tests only the consistency
  # of the length of each component
  p <- ncol(object@tab)
  k <- length(unique(object@loc.names))


  if(!is.null(object@loc.fac)){
      if(length(object@loc.fac) != p) {
          cat("\ninvalid length for loc.fac\n")
          return(FALSE)
      }

      if(length(levels(object@loc.fac)) != k) {
          cat("\ninvalid number of levels in loc.fac\n")
          return(FALSE)
      }
  }

  if(!is.null(object@loc.nall)){
      if(length(object@loc.nall) != k) {
          cat("\ninvalid length in loc.nall\n")
          return(FALSE)
      }
  }

  temp <- table(object@loc.names[object@loc.names!=""])
  if(any(temp>1)) {
      warning("\nduplicate names in loc.names:\n")
      print(temp[temp>1])
  }

  if(!is.null(object@all.names)){
      if(length(unlist(object@all.names)) != p) {
          cat("\ninvalid length in all.names\n")
          return(FALSE)
      }
  }

  return(TRUE)

}# end .gen.valid


setClass("gen", representation(tab = "matrix",
                               loc.names = "character",
                               loc.fac = "factorOrNULL",
                               loc.nall = "intOrNum",
                               all.names = "listOrNULL",
                               call = "callOrNULL",
                               "VIRTUAL"),
         prototype(tab=matrix(0L, ncol=0,nrow=0), loc.nall=integer(0), call=NULL))

setValidity("gen", .gen.valid)





########################
# virtual class indInfo
########################
setClass("indInfo", representation(ind.names = "character",
                                   pop = "factorOrNULL",
                                   pop.names = "charOrNULL",
                                   ploidy = "integer",
                                   type = "character",
                                   other = "listOrNULL", "VIRTUAL"),
         prototype(pop=NULL, pop.names = NULL, type = "codom", ploidy = as.integer(2), other = NULL))





###############
# Class genind
###############
.genind.valid <- function(object){

    validation <- TRUE
    if(!.gen.valid(object)) return(FALSE)

    if(length(object@ind.names) != nrow(object@tab)) {
        message("\ninvalid length in ind.names\n")
        validation <- FALSE
    }

    temp <- table(object@ind.names[object@ind.names!=""])
    if(any(temp>1)) {
        warning("\nduplicate names in ind.names:\n")
        print(temp[temp>1])
    }

    if(typeof(object@tab)!="integer"){
        warning("@tab does not contain integers; as of adegenet_2.0-0, numeric values are no longer used")
        ## message("\ntab does not contain integers; as of adegenet_1.5-0, numeric values are no longer used")
        ## validation <- FALSE
    }


    if(!is.null(object@pop)){ # check pop

        if(length(object@pop) != nrow(object@tab)) {
            message("\npop is given but has invalid length\n")
            validation <- FALSE
        }

        if(is.null(object@pop.names)) {
            message("\npop is provided without pop.names")
        }


        if(length(object@pop.names) != length(levels(object@pop))) {
            message("\npop.names has invalid length\n")
            validation <- FALSE
        }

        temp <- table(object@pop.names[object@pop.names!=""])
        if(any(temp>1)) {
            warning("\nduplicate names in pop.names:\n")
            print(temp[temp>1])
        }

    } # end check pop

    # Check population strata
    if (!is.null(object@strata)){
      if (nrow(object@strata) != nrow(object@tab)){
        message("\na strata is defined has invalid length\n")
        validation <- FALSE
      }

      dups <- duplicated(colnames(object@strata))
      if (any(dups)){
        message("\nduplicated names found in @strata slot:\n")
        dups <- colnames(object@strata)[dups]
        message(paste0(dups, collapse = ", "))
        validation <- FALSE
      }
    }

    # TODO: CHECK HIERARCHY FORMULA

    ## check ploidy
    if(any(object@ploidy < 1L)){
        message("\nploidy inferior to 1\n")
        validation <- FALSE
    }
    if(length(object@ploidy)!=nInd(object)){
        warning("as of adegenet_2.0-0, @ploidy should contain one value per individual")
    }

    ## check type of marker
    if(!object@type %in% c("codom","PA") ){
        message("\nunknown type of marker\n")
        validation <- FALSE
    }


    return(validation)
} #end .genind.valid

setClass("genind", contains=c("gen", "indInfo"), 
          representation = representation(strata = "dfOrNULL", hierarchy = "formOrNULL"))
setValidity("genind", .genind.valid)



########################
# virtual class popInfo
########################
setClass("popInfo", representation(pop.names = "character", ploidy = "integer",
                                   type = "character", other = "listOrNULL", "VIRTUAL"),
         prototype(type = "codom", ploidy = as.integer(2), other = NULL))



###############
# Class genpop
###############
.genpop.valid <- function(object){

    validation <- TRUE

    if(!.gen.valid(object)) return(FALSE)
    if(length(object@pop.names) != nrow(object@tab)) {
        message("\ninvalid length in pop.names\n")
        validation <- FALSE
    }

    temp <- table(object@pop.names[object@pop.names!=""])
    if(any(temp>1)) {
        warning("\nduplicate names in pop.names:\n")
        print(temp[temp>1])
    }

     ## check ploidy
    if(length(object@ploidy) > 1 && object@ploidy < 1L){
        message("\nploidy inferior to 1\n")
        validation <- FALSE
    }

    ## check type of marker
    if(!object@type %in% c("codom","PA") ){
        message("\nunknown type of marker\n")
        validation <- FALSE
    }

    return(validation)
} #end .genpop.valid

setClass("genpop", contains=c("gen", "popInfo"))
setValidity("genpop", .genpop.valid)







###############################################################
###############################################################
## MISCELLANEOUS METHODS
###############################################################
###############################################################



#################
# Function names
#################
setMethod("names", signature(x = "genind"), function(x){
    return(slotNames(x))
})

setMethod("names", signature(x = "genpop"), function(x){
    return(slotNames(x))
})

