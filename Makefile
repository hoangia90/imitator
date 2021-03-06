
###############################################################
# !!!!! WARNING !!!!!
# THIS FILE IS DEPRECATED
# USE OASIS INSTEAD!
###############################################################


###############################################################
#
#                    IMITATOR II
#
#  Laboratoire Specification et Verification (ENS Cachan & CNRS, France)
#
#  Author:        Ulrich Kuehne, Etienne Andre
#  Created:       2009/09/07
#  Last modified: 2013/09/26
#  Ocaml version: 3.12.1
###############################################################

# Flags for ocaml compiler (-g for exception stack trace)
OCAMLC_FLAGS = -g
# OCAMLC_FLAGS = 

# ocaml compiler
OCAMLC = ocamlc $(OCAMLC_FLAGS)
OCAMLOPT = ocamlopt.opt $(OCAMLC_FLAGS)

# path variables
ifndef EXTLIB_PATH
  EXTLIB_PATH = /usr/lib/ocaml/extlib
endif
ifndef OCAML_PPL_PATH
	OCAML_PPL_PATH = /usr/lib/ppl
endif 
ifndef OCAML_GMP_PATH
	OCAML_GMP_PATH = /usr/lib/ocaml/gmp
endif
ifndef CLIB_PATH
  CLIB_PATH = /usr/lib -I /usr/local/lib
endif 

INCLUDE = -I $(SRC) -I $(EXTLIB_PATH) -I $(OCAML_PPL_PATH) -I $(OCAML_GMP_PATH)

# -I /usr/lib/i386-linux-gnu/

# native c libraries (old version)
# CLIBS = -cclib -lpwl -cclib -lm -cclib -lgmpxx -cclib -lgmp -cclib -lppl

# native c libraries (updated 2012/06/07)
# NOTE: non-static compiling does not work anymore since June 2013: go for static instead
CLIBS = -cclib -lppl 
# -lstdc++
# -L/usr/lib64 -lstdc++ ?

# For 32 bits compiling
STATIC32CLIBS = -cclib '-static -lppl -lcamlrun -ltinfo -lppl_ocaml -lstdc++ -lgmp -lgmpxx'
# CLIBS = -cclib '-static -lppl -lpwl -lcamlrun -ltinfo -lppl_ocaml -lstdc++ -lmlgmp -lmpfr -lgmp -lgmpxx'

# For 64 bits compiling
STATIC64CLIBS = -cclib '-static -lppl -lcamlrun -ltinfo -lppl_ocaml -lstdc++ -lgmpxx'
# -ldl : inutile
# CLIBS = -cclib '-static -lppl -lpwl -lppl_ocaml -lstdc++ -lmlgmp -lmpfr -lgmp -lgmpxx'


# ocaml lib files
OLIBS = str.cma unix.cma extLib.cma bigarray.cma gmp.cma ppl_ocaml.cma 

# native ocaml lib files
OOLIBS = str.cmxa unix.cmxa extLib.cmxa bigarray.cmxa gmp.cmxa ppl_ocaml.cmxa


# external libs for compiling with PPL support
export LIBS = $(CLIBS) $(OLIBS)
# export OPTLIBS = $(CLIBS) $(OOLIBS) 
export STATIC32LIBS = $(STATIC32CLIBS) $(OLIBS)
export STATIC64LIBS = $(STATIC64CLIBS) $(OLIBS)


SRC = src

# Example files for execution directly from the makefile
EXAMPLE_PATH = examples

# main object
MAIN = $(SRC)/IMITATOR.cmo
# MAIN_OPT = $(MAIN:.cmo=.cmx)

# modules to compile
MODULES = BuildInfo Global NumConst ReachabilityTree Options LinearConstraint Automaton Cache Input Pi0Lexer Pi0Parser V0Lexer V0Parser ModelLexer ModelParser GrMLLexer GrMLParser StateSpace ModelPrinter ObserverPatterns PTA2CLP PTA2GrML ModelConverter Graphics PTA2JPG Reachability Cartography

### P Constraint P XConstraint P XDConstraint 

# interfaces
HEADERS = BuildInfo Global NumConst ReachabilityTree Options LinearConstraint Automaton Cache ParsingStructure AbstractModel Input StateSpace ModelPrinter ObserverPatterns PTA2CLP PTA2GrML  ModelConverter Graphics PTA2JPG Reachability Cartography

CMIS = $(addprefix $(SRC)/, $(addsuffix .cmi, $(HEADERS)))
OBJS = $(addprefix $(SRC)/, $(addsuffix .cmo, $(MODULES)))
# OBJS_OPT = $(addprefix $(SRC)/, $(addsuffix .cmx, $(MODULES)))

# parsers and lexers 
LEXERS = Pi0Lexer V0Lexer ModelLexer GrMLLexer
PARSERS = Pi0Parser V0Parser ModelParser GrMLParser

LEX_ML = $(addprefix $(SRC)/, $(addsuffix .ml, $(LEXERS)))
LEX_CMI = $(addprefix $(SRC)/, $(addsuffix .cmi, $(LEXERS)))
PAR_ML = $(addprefix $(SRC)/, $(addsuffix .ml, $(PARSERS)))
PAR_CMI = $(addprefix $(SRC)/, $(addsuffix .cmi, $(PARSERS)))

# target library
IMILIB = lib/imitator.cma
# IMILIB_OPT = $(IMILIB:.cma=.cmxa)

# target executable
TARGET_PATH = bin/
TARGET_NAME = imitator
VERSION = 2.6.1.1
TARGET = $(TARGET_PATH)$(TARGET_NAME)
TARGETV = $(TARGET)$(VERSION)
# TARGET_OPT = bin/IMITATOR.opt
TARGET_STATIC32 = bin/IMITATOR32
TARGET_STATIC64 = bin/IMITATOR64


BUILDINFO = python gen_build_info.py

default all:
	$(BUILDINFO)
	make $(TARGET)
# opt: $(TARGET_OPT)

static32:
	$(BUILDINFO)
	make $(TARGET_STATIC32)

static64:
	$(BUILDINFO)
	make $(TARGET_STATIC64)


header: $(CMIS)
parser: $(PAR_ML) $(LEX_ML) header $(PAR_CMI)


$(BUILDINFO): python gen_build_info.py
	@ echo [MKLIB] $@


$(IMILIB): header parser $(OBJS)
	@ echo [MKLIB] $@
	@ $(OCAMLC) -a -o $@ $(OBJS)  

# $(IMILIB_OPT): header parser $(OBJS_OPT)  
# 	@ echo [MKLIB] $@
# 	@ $(OCAMLOPT) -a -o $@ $(OBJS_OPT)


# $(TARGET): $(MAIN)
# 	@ echo [LINK] $(TARGET)
# 	@ $(OCAMLC) -custom -o $(TARGET) $(INCLUDE) $(LIBS) $(MAIN)
	
$(TARGET): $(IMILIB) $(MAIN)
	@ echo [LINK] $(TARGET)
	@ $(OCAMLC) $(INCLUDE) $(LIBS) $(IMILIB) $(MAIN) -o $(TARGET)
	@ python incrementer.py
	@ echo [LN] $(TARGETV)
	@ cd $(TARGET_PATH) ; rm $(TARGET_NAME)$(VERSION) ; ln $(TARGET_NAME) $(TARGET_NAME)$(VERSION) -s
	
$(TARGET_STATIC32): $(IMILIB) $(MAIN)
	@ echo [LINK] $(TARGET_STATIC32)
	@ $(OCAMLC) -custom $(INCLUDE) -I $(CLIB_PATH) $(STATIC32LIBS) $(IMILIB) $(MAIN) -o $(TARGET_STATIC32) 
	@ python incrementer.py
	@ echo [LN] $(TARGETV)
	@ cd $(TARGET_PATH) ; rm $(TARGET_NAME)$(VERSION) ; ln $(TARGET_STATIC32) $(TARGET_NAME)$(VERSION) -s
	
$(TARGET_STATIC64): $(IMILIB) $(MAIN)
	@ python gen_build_info.py
	@ echo [LINK] $(TARGET_STATIC64)
	@ $(OCAMLC) -custom $(INCLUDE) -I $(CLIB_PATH) $(STATIC64LIBS) $(IMILIB) $(MAIN) -o $(TARGET_STATIC64)
	@ python incrementer.py
	@ echo [LN] $(TARGETV)
	@ cd $(TARGET_PATH) ; rm $(TARGET_NAME)$(VERSION) ; ln $(TARGET_NAME)64 $(TARGET_NAME)$(VERSION) -s

	
	# $(TARGET_OPT): $(IMILIB_OPT) $(MAIN_OPT)
# 	@ echo [LINK] $(TARGET_OPT)
# 	$(OCAMLOPT) -o $(TARGET_OPT) $(INCLUDE) $(OPTLIBS) $(IMILIB_OPT) $(MAIN_OPT)

$(SRC)/%.cmo: $(SRC)/%.ml $(SRC)/%.mli
	@ echo [OCAMLC] $<
	@ $(OCAMLC) -c $(INCLUDE) $<	

$(SRC)/%.cmo: $(SRC)/%.ml
	@ echo [OCAMLC] $<
	@ $(OCAMLC) -c $(INCLUDE) $<	

$(SRC)/%.cmx: $(SRC)/%.ml $(SRC)/%.mli
	@ echo [OCAMLOPT] $<
	@ $(OCAMLOPT) -c $(INCLUDE) $<	

$(SRC)/%.cmx: $(SRC)/%.ml
	@ echo [OCAMLOPT] $<
	@ $(OCAMLOPT) -c $(INCLUDE) $<	

$(SRC)/%.cmi: $(SRC)/%.mli
	@ echo [OCAMLC] $<
	@ $(OCAMLC) -c $(INCLUDE) $<

$(SRC)/%.cmi: $(SRC)/%.mly
	@ echo [YACC] $<
	@ ocamlyacc $<
	@ echo [OCAMLC] $(SRC)/$*.mli
	@ $(OCAMLC) -c $(INCLUDE) $(SRC)/$*.mli

$(SRC)/%.ml: $(SRC)/%.mly 
	@ echo [YACC] $<
	@ ocamlyacc $<

$(SRC)/%.ml: $(SRC)/%.mll 
	@ echo [LEX] $<
	@ ocamllex $< 

# dependencies
# .depend:
# 	@ echo [OCAMLDEP]
# 	@ ocamldep -I $(SRC) $(SRC)/*.ml $(SRC)/*.mli > .depend 


test:	all
	make exe

testUlrich: $(IMILIB) 
	cd test; make unit

tests:
	python testing/test.py

exe:


##### TESTS FOR MPI / PATATOR #####
# 	mpiexec -n 4 $(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi $(EXAMPLE_PATH)/Flipflop/flipflop.v0 -mode cover -distributed sequential -cart -precomputepi0 -verbose standard
# 	mpiexec -n 4 $(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi $(EXAMPLE_PATH)/Flipflop/flipflop.v0 -mode cover -distributed random5 -cart -verbose standard
# 	mpiexec -n 4 $(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi $(EXAMPLE_PATH)/Flipflop/flipflop.v0 -mode cover -distributed unsupervised -cart -verbose standard
# 	mpiexec -n 4 $(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi $(EXAMPLE_PATH)/Flipflop/flipflop.v0 -mode cover -distributed shuffle -cart -verbose standard
	
# 	mpiexec -n 4 $(TARGET) $(EXAMPLE_PATH)/Scheduling/test3-bigV0-3D.imi $(EXAMPLE_PATH)/Scheduling/test3-bigV0-3D.v0 -merge -mode cover -distributed shuffle -cart -verbose standard

# 	mpiexec -n 4 $(TARGET) $(EXAMPLE_PATH)/Scheduling/test3.imi $(EXAMPLE_PATH)/Scheduling/test3.v0 -mode cover -merge -distributed sequential -cart -verbose standard
# 	mpiexec -n 4 $(TARGET) $(EXAMPLE_PATH)/Scheduling/test3.imi $(EXAMPLE_PATH)/Scheduling/test3.v0 -mode cover -merge -distributed unsupervised -cart -verbose standard
# 	mpiexec -n 4 $(TARGET) $(EXAMPLE_PATH)/Scheduling/test3.imi $(EXAMPLE_PATH)/Scheduling/test3.v0 -mode cover -merge -distributed shuffle -cart -verbose standard

# 	mpiexec -n 4 $(TARGET) $(EXAMPLE_PATH)/RCP/RCP.imi $(EXAMPLE_PATH)/RCP/RCP.v0 -mode cover -cart -distributed sequential
	 
# 	mpiexec -n 4 $(TARGET) $(EXAMPLE_PATH)/RCP/RCP.imi $(EXAMPLE_PATH)/RCP/RCP.v0 -mode cover -cart -distributed random10
	 
# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall_obs.imi $(EXAMPLE_PATH)/Valmem/spsmall_obs.v0 -mode cover -cart -log-prefix $(EXAMPLE_PATH)/Valmem/spsmall_obs-BC
# 
# 	mpiexec -n 4 $(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall_obs.imi $(EXAMPLE_PATH)/Valmem/spsmall_obs.v0 -mode cover -cart -log-prefix $(EXAMPLE_PATH)/Valmem/spsmall_obs-BC-patator-seq -distributed sequential
# 	 
# 	mpiexec -n 4 $(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall_obs.imi $(EXAMPLE_PATH)/Valmem/spsmall_obs.v0 -mode cover -cart -log-prefix $(EXAMPLE_PATH)/Valmem/spsmall_obs-BC-patator-r20 -distributed random20
# 	 
# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall_obs.imi $(EXAMPLE_PATH)/Valmem/spsmall_obs.v0 -mode cover -cart -log-prefix $(EXAMPLE_PATH)/Valmem/spsmall_obs-BCm -merge

# 	mpiexec -n 4 $(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall_obs.imi $(EXAMPLE_PATH)/Valmem/spsmall_obs.v0 -mode cover -cart -log-prefix $(EXAMPLE_PATH)/Valmem/spsmall_obs-BC-patator-seqm -distributed sequential -merge
	 
# 	mpiexec -n 4 $(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall_obs.imi $(EXAMPLE_PATH)/Valmem/spsmall_obs.v0 -mode cover -cart -log-prefix $(EXAMPLE_PATH)/Valmem/spsmall_obs-BC-patator-r10m -distributed random10 -merge
	 
# 	mpiexec -n 4 $(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall_obs.imi $(EXAMPLE_PATH)/Valmem/spsmall_obs.v0 -mode cover -cart -log-prefix $(EXAMPLE_PATH)/Valmem/spsmall_obs-BC-patator-r100m -distributed random100 -merge
	 
	 
	 
	 
	 
##### TESTS FOR SYNTAX AND FEATURES #####

# 	$(TARGET) temp/test2.imi temp/test.v0 -mode border -incl -merge -cart -with-graphics-source


# 	$(TARGET) $(EXAMPLE_PATH)/Tests/test.gml -mode statespace -verbose high -fromGrML

# 	$(TARGET) $(EXAMPLE_PATH)/Tests/test.imi -PTA2GrML

# 	$(TARGET) $(EXAMPLE_PATH)/Tests/testPost.imi -mode statespace
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/testPostSW.imi -mode statespace
# 	bin/IMITATOR2.4 $(EXAMPLE_PATH)/Tests/testPostSW.imi -mode statespace
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/testPostUpdates.imi -mode statespace -no-merging
# 	bin/IMITATOR2.4 $(EXAMPLE_PATH)/Tests/testPostUpdates.imi -mode statespace
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/testPostUpdates1PTA.imi -mode statespace
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/testPostSW.imi -mode statespace -verbose total -depth-limit 2
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/testPostSansDiscrete.imi -mode statespace -statistics -verbose total

# 	$(TARGET) $(EXAMPLE_PATH)/Tests/exPourGML.imi -PTA2GrML

# 	$(TARGET) $(EXAMPLE_PATH)/Tests/exPourGML.imi -mode statespace
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/SynthesizedGML.gml -fromGrML -mode statespace

# 	$(TARGET) $(EXAMPLE_PATH)/Tests/model2.gml -fromGrML -forcePi0
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/model2.imi -forcePi0

# 	$(TARGET) $(EXAMPLE_PATH)/Tests/model2.imi $(EXAMPLE_PATH)/Tests/model2.pi0 -verbose total
# # 	bin/IMITATOR32romain $(EXAMPLE_PATH)/Tests/model2.imi $(EXAMPLE_PATH)/Tests/model2.pi0 -verbose total
	
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/model2.imi $(EXAMPLE_PATH)/Tests/model2.pi0 -verbose total

# 	$(TARGET) $(EXAMPLE_PATH)/Tests/testCosts.imi $(EXAMPLE_PATH)/Tests/testCosts.pi0 -verbose total -bab -time-limit 1

# 	$(TARGET) $(EXAMPLE_PATH)/Tests/TestPattern1.imi $(EXAMPLE_PATH)/Tests/TestPattern1.v0 -mode cover -cart
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/TestPattern2.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/TestPattern2.imi $(EXAMPLE_PATH)/Tests/TestPattern2.v0 -mode cover -cart -with-dot -fancy
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/TestPattern3.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/TestPattern3.imi $(EXAMPLE_PATH)/Tests/TestPattern3.v0 -mode cover -cart
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/TestPattern4.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/TestPattern4.imi $(EXAMPLE_PATH)/Tests/TestPattern4.v0 -mode cover -cart -with-dot -fancy
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/TestPattern5.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/TestPattern5.imi $(EXAMPLE_PATH)/Tests/TestPattern5.v0 -mode cover -cart -with-dot -fancy
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/TestPattern6.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/TestPattern6.imi $(EXAMPLE_PATH)/Tests/TestPattern6.v0 -mode cover -cart -with-dot -fancy
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/TestPattern7.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/TestPattern7.imi $(EXAMPLE_PATH)/Tests/TestPattern7.v0 -mode cover -cart -with-dot -fancy



##### TESTS FOR PROPERTIES #####

# 	$(TARGET) $(EXAMPLE_PATH)/Proprietes/exCTL.imi -mode statespace -with-dot -with-log
# 	$(TARGET) $(EXAMPLE_PATH)/Proprietes/exCTL.imi $(EXAMPLE_PATH)/Proprietes/exCTL.pi0
# 	$(TARGET) $(EXAMPLE_PATH)/Proprietes/exCTL.imi $(EXAMPLE_PATH)/Proprietes/exCTL.pi0 -PTA2CLP

# 	$(TARGET) $(EXAMPLE_PATH)/Merging/StrangeMergingBehavior.imi $(EXAMPLE_PATH)/Merging/StrangeMergingBehavior.pi0
# 	$(TARGET) $(EXAMPLE_PATH)/Merging/exMerging.imi $(EXAMPLE_PATH)/Merging/exMerging.pi0 -with-dot
# 	$(TARGET) $(EXAMPLE_PATH)/Merging/exMerging.imi $(EXAMPLE_PATH)/Merging/exMerging.pi0 -with-dot -merge

# 	$(TARGET) $(EXAMPLE_PATH)/Merging/exActionsNonPreserved.imi $(EXAMPLE_PATH)/Merging/exActionsNonPreserved.pi0
# 	$(TARGET) $(EXAMPLE_PATH)/Merging/exActionsNonPreserved.imi $(EXAMPLE_PATH)/Merging/exActionsNonPreserved.pi0 -merge -with-dot
# 	$(TARGET) $(EXAMPLE_PATH)/Merging/exActionsNonPreserved.imi $(EXAMPLE_PATH)/Merging/exActionsNonPreserved.pi0 -merge-before -with-dot

	# 	$(TARGET) $(EXAMPLE_PATH)/Merging/exMergingSimple.imi -mode statespace -with-dot
# 	$(TARGET) $(EXAMPLE_PATH)/Merging/exMergingSimple.imi $(EXAMPLE_PATH)/Merging/exMergingSimple.pi0 -with-dot -merge

# 	$(TARGETV) $(EXAMPLE_PATH)/Proprietes/contrexTermination.imi -mode statespace -with-dot
# 	$(TARGETV) $(EXAMPLE_PATH)/Proprietes/contrexTermination.imi $(EXAMPLE_PATH)/Proprietes/contrexTermination.pi0 -with-dot -depth-limit 7

# 	$(TARGETV) $(EXAMPLE_PATH)/Proprietes/contrexTerminationGlobalClockIMincl.imi -mode statespace -no-merging -incl
# 	$(TARGETV) $(EXAMPLE_PATH)/Proprietes/contrexTerminationGlobalClockIMincl.imi $(EXAMPLE_PATH)/Proprietes/contrexTerminationGlobalClockIMincl.pi0 -depth-limit 30 -with-dot -with-log -with-parametric-log

# 	$(TARGET) $(EXAMPLE_PATH)/Examples/JLR-TACAS13.imi $(EXAMPLE_PATH)/Examples/JLR-TACAS13.pi0 -with-dot -depth-limit 100 -with-log -with-parametric-log -incl -merge
# 	$(TARGET) $(EXAMPLE_PATH)/Examples/JLR-TACAS13.imi $(EXAMPLE_PATH)/Examples/JLR-TACAS13.v0 -efim -mode cover -cart -depth-limit 50


# 	$(TARGET) $(EXAMPLE_PATH)/Examples/JLR-TACAS13.imi $(EXAMPLE_PATH)/Examples/JLR-TACAS13.v0 -efim -mode cover -cart -depth-limit 10
	
# 	$(TARGET) $(EXAMPLE_PATH)/Examples/JLR-TACAS13.imi -mode EF -cart -depth-limit 10
	

# 	$(TARGET) $(EXAMPLE_PATH)/Proprietes/exNonTerminationDFS.imi $(EXAMPLE_PATH)/Proprietes/exNonTerminationDFS.pi0 -bab -no-merging -incl -with-log -states-limit 30 -with-parametric-log # PROBLEM BAB
# 	$(TARGET) $(EXAMPLE_PATH)/Proprietes/exNonTerminationDFS.imi $(EXAMPLE_PATH)/Proprietes/exNonTerminationDFS.pi0 -no-merging -incl -with-parametric-log -with-log -states-limit 30 -with-dot

# 	$(TARGETV) $(EXAMPLE_PATH)/Examples/loopingDynamic.imi $(EXAMPLE_PATH)/Examples/loopingDynamic.pi0 -depth-limit 20
# 	$(TARGETV) $(EXAMPLE_PATH)/Examples/loopingDynamic.imi $(EXAMPLE_PATH)/Examples/loopingDynamic.pi0 -dynamic-elimination -with-log -with-dot -log-prefix $(EXAMPLE_PATH)/Examples/loopingDynamic-dynamic

# 	$(TARGETV) $(EXAMPLE_PATH)/Examples/JLR13.imi -mode statespace -with-log

# 	$(TARGETV) $(EXAMPLE_PATH)/Examples/exClockElimination.imi -verbose medium -mode statespace -depth-limit 2 -dynamic-elimination
# 	$(TARGETV) $(EXAMPLE_PATH)/Examples/exClockElimination.imi $(EXAMPLE_PATH)/Examples/exClockElimination.pi0
# 	$(TARGETV) $(EXAMPLE_PATH)/Examples/exClockElimination.imi $(EXAMPLE_PATH)/Examples/exClockElimination.pi0 -dynamic-elimination -with-log -with-dot -log-prefix $(EXAMPLE_PATH)/Examples/exClockElimination-dynamic

# 	$(TARGET) $(EXAMPLE_PATH)/Examples/testBoucleAvecDiscrete.imi -mode statespace -statistics -depth-limit 200 -no-dot -no-log
# 	$(TARGET) $(EXAMPLE_PATH)/Examples/testBoucleAvecDiscrete.imi -mode statespace -statistics -depth-limit 200 -no-dot -no-log -dynamic
# 	$(TARGET) $(EXAMPLE_PATH)/Examples/testBoucleAvecDiscrete.imi -mode statespace -depth-limit 200 -no-dot -no-log
# 	bin/IMITATOR2.41 $(EXAMPLE_PATH)/Examples/testBoucleAvecDiscrete.imi -mode statespace -depth-limit 200 -no-dot -no-log
# 	bin/IMITATOR2.4 $(EXAMPLE_PATH)/Examples/testBoucleAvecDiscrete.imi -mode statespace -depth-limit 200 -no-dot -no-log -jobshop
# 	bin/IMITATOR2.375 $(EXAMPLE_PATH)/Examples/testBoucleAvecDiscrete.imi -mode statespace -depth-limit 200 -no-dot -no-log -jobshop
# 	bin/IMITATOR2.374 $(EXAMPLE_PATH)/Examples/testBoucleAvecDiscrete.imi -mode statespace -depth-limit 200 -no-dot -no-log -jobshop
# 	bin/IMITATOR2.370 $(EXAMPLE_PATH)/Examples/testBoucleAvecDiscrete.imi -mode statespace -statistics -depth-limit 200 -no-dot -no-log
# 	bin/IMITATOR2.36 $(EXAMPLE_PATH)/Examples/testBoucleAvecDiscrete.imi -mode statespace -statistics -depth-limit 200 -no-dot -no-log
# 	bin/IMITATOR2.35 $(EXAMPLE_PATH)/Examples/testBoucleAvecDiscrete.imi -mode statespace -statistics -depth-limit 200 -no-dot -no-log
# 	bin/IMITATOR2.34.111115 $(EXAMPLE_PATH)/Examples/testBoucleAvecDiscrete.imi -mode statespace -depth-limit 200 -no-dot -no-log

##### CASE STUDIES : EXAMPLES #####
# 	$(TARGET) $(EXAMPLE_PATH)/Examples/exSITH.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/Examples/exSITH.imi -mode EF -with-dot
# 	$(TARGET) $(EXAMPLE_PATH)/Examples/exSITH.imi $(EXAMPLE_PATH)/Examples/exSITH.pi0 -with-dot

# 	$(TARGET) $(EXAMPLE_PATH)/Examples/exCentraleNucleaire.imi -mode statespace -with-dot -fancy

# 	$(TARGET) $(EXAMPLE_PATH)/Examples/contrexPPTA.imi $(EXAMPLE_PATH)/Examples/contrexPPTA.pi0
# 	$(TARGET) $(EXAMPLE_PATH)/Examples/contrexPPTA.imi $(EXAMPLE_PATH)/Examples/contrexPPTA.pi0 -bab

# 	$(TARGET) $(EXAMPLE_PATH)/Examples/contrexPPTA2.imi -mode statespace
# 	$(TARGET) $(EXAMPLE_PATH)/Examples/contrexPPTA2.imi $(EXAMPLE_PATH)/Examples/contrexPPTA2.pi0
# 	$(TARGET) $(EXAMPLE_PATH)/Examples/contrexPPTA2.imi $(EXAMPLE_PATH)/Examples/contrexPPTA2.pi0 -bab
 	
#  	$(TARGET) $(EXAMPLE_PATH)/Examples/exERAKK.imi -mode statespace -with-log -with-dot

# 	$(TARGET) $(EXAMPLE_PATH)/Examples/contrexPPTA3.imi $(EXAMPLE_PATH)/Examples/contrexPPTA.pi0
# 	$(TARGET) $(EXAMPLE_PATH)/Examples/contrexPPTA3.imi $(EXAMPLE_PATH)/Examples/contrexPPTA.pi0 -bab

##### CASE STUDIES : HARDWARE #####

# 	$(TARGET) $(EXAMPLE_PATH)/GML/testtemp.grml -fromGrML -mode statespace
# 	$(TARGET) $(EXAMPLE_PATH)/GML/pta1.grml -fromGrML -mode statespace
# 	$(TARGET) $(EXAMPLE_PATH)/AndOr/AndOr.imi -PTA2GrML
# 	$(TARGET) $(EXAMPLE_PATH)/AndOr/AndOr.imi.grml -fromGrML -mode statespace

# 	$(TARGET) $(EXAMPLE_PATH)/AndOr/AndOr.imi -mode statespace -merge
# 	$(TARGET) $(EXAMPLE_PATH)/AndOr/AndOr.imi -mode statespace -dynamic-elimination -verbose total
# 	$(TARGET) $(EXAMPLE_PATH)/AndOr/AndOr2.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/AndOr/AndOr.imi -mode statespace -states-limit 10
# 	$(TARGET) $(EXAMPLE_PATH)/AndOr/AndOr.imi -mode statespace -time-limit 10

# 	$(TARGET) $(EXAMPLE_PATH)/AndOr/AndOr_obs.imi -mode statespace -merge -with-dot

# 	$(TARGET) $(EXAMPLE_PATH)/Tests/AndOrTest.imi $(EXAMPLE_PATH)/Tests/AndOrTest.pi0 -verbose high
# 	$(TARGET) $(EXAMPLE_PATH)/Tests/AndOrTest.imi -PTA2JPG

#	$(TARGETV) $(EXAMPLE_PATH)/AndOr/AndOr.imi $(EXAMPLE_PATH)/AndOr/AndOr.pi0 -with-dot -with-log
# 	$(TARGETV) $(EXAMPLE_PATH)/AndOr/AndOr.imi $(EXAMPLE_PATH)/AndOr/AndOr.pi0 -dynamic-elimination -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/AndOr/AndOr-dynamic
# 	$(TARGET) $(EXAMPLE_PATH)/AndOr/AndOr.imi $(EXAMPLE_PATH)/AndOr/AndOr.pi0 -with-dot -with-dot-source -fancy
# 	$(TARGET) $(EXAMPLE_PATH)/AndOr/AndOr.imi $(EXAMPLE_PATH)/AndOr/AndOr.pi0 -no-dot -no-log -statistics 
# 	$(TARGET) $(EXAMPLE_PATH)/AndOr/AndOr.imi $(EXAMPLE_PATH)/AndOr/AndOr.pi0 -no-dot -no-log -statistics -dynamic
# 	$(TARGET) $(EXAMPLE_PATH)/AndOr/AndOr.imi $(EXAMPLE_PATH)/AndOr/AndOr.pi0 -no-dot -no-log -jobshop
# 	bin/IMITATOR2.4 $(EXAMPLE_PATH)/AndOr/AndOr.imi $(EXAMPLE_PATH)/AndOr/AndOr.pi0 -no-dot -no-log -jobshop
# 	bin/IMITATOR2.375 $(EXAMPLE_PATH)/AndOr/AndOr.imi $(EXAMPLE_PATH)/AndOr/AndOr.pi0 -no-dot -no-log -jobshop
# 	bin/IMITATOR2.370 $(EXAMPLE_PATH)/AndOr/AndOr.imi $(EXAMPLE_PATH)/AndOr/AndOr.pi0 -no-dot -no-log -statistics

	# 	$(TARGET) $(EXAMPLE_PATH)/AndOr/AndOr.imi $(EXAMPLE_PATH)/AndOr/AndOr.v0 -mode cover

# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi -mode statespace 
# 	bin/IMITATOR2.4 $(EXAMPLE_PATH)/Flipflop/flipflop.imi -mode statespace -no-dot -no-log -jobshop
# 	bin/IMITATOR2.375 $(EXAMPLE_PATH)/Flipflop/flipflop.imi -mode statespace -no-dot -no-log -jobshop
# 	bin/IMITATOR2.374 $(EXAMPLE_PATH)/Flipflop/flipflop.imi -mode statespace -no-dot -no-log -jobshop
# 	bin/IMITATOR2.371 $(EXAMPLE_PATH)/Flipflop/flipflop.imi -mode statespace -no-dot -no-log -statistics
# 	bin/IMITATOR2.370 $(EXAMPLE_PATH)/Flipflop/flipflop.imi -mode statespace
# 	bin/IMITATOR2.35.111115 $(EXAMPLE_PATH)/Flipflop/flipflop.imi -mode statespace
# 	bin/IMITATOR2.35 $(EXAMPLE_PATH)/Flipflop/flipflop.imi -mode statespace -no-dot -no-log -statistics
# 	bin/IMITATOR2.34.111115 $(EXAMPLE_PATH)/Flipflop/flipflop.imi -mode statespace -no-dot -no-log 

# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi -mode statespace -tree -verbose low
# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi -mode statespace -acyclic -verbose low
# 		$(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi $(EXAMPLE_PATH)/Flipflop/flipflop.pi0 -no-dot -no-log -jobshop -no-random
# 		bin/IMITATOR2.4 $(EXAMPLE_PATH)/Flipflop/flipflop.imi $(EXAMPLE_PATH)/Flipflop/flipflop.pi0 -no-dot -no-log -jobshop -no-random

# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi $(EXAMPLE_PATH)/Flipflop/flipflop.pi0 -with-dot
	
# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi $(EXAMPLE_PATH)/Flipflop/flipflop-bad.pi0 -efim  -with-dot
# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi -mode statespace -with-dot
# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi $(EXAMPLE_PATH)/Flipflop/flipflop.pi0 -completeIM
# 	$(TARGETV) $(EXAMPLE_PATH)/Flipflop/flipflop.imi $(EXAMPLE_PATH)/Flipflop/flipflop.pi0 -dynamic-elimination -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/Flipflop/flipflop-dynamic
# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi $(EXAMPLE_PATH)/Flipflop/flipflop.pi0 -bab

# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi $(EXAMPLE_PATH)/Flipflop/flipflop.v0 -mode cover -cart -verbose total
# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi -mode statespace -with-dot
# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi $(EXAMPLE_PATH)/Flipflop/flipflop-bug.pi0 -with-dot -efim -with-log -with-parametric-log -verbose low -fancy
# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi $(EXAMPLE_PATH)/Flipflop/flipflop.v0 -efim -mode cover -cart
# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi -mode EF -cart
# 	bin/IMITATOR32 $(EXAMPLE_PATH)/Flipflop/flipflop.imi $(EXAMPLE_PATH)/Flipflop/flipflop.v0 -mode border -cart -with-graphics-source
# 	$(TARGETV) $(EXAMPLE_PATH)/Flipflop/flipflop.imi $(EXAMPLE_PATH)/Flipflop/flipflop.v0 -mode border -cart -with-graphics-source
# 	./IMITATOR Examples/Flipflop/flipflop.imi Examples/Flipflop/flipflop.v0 -mode random1000  -log-prefix Examples/Flipflop/test2/test
	$(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop.imi $(EXAMPLE_PATH)/Flipflop/flipflop.v0 -mode cover -output-cart
# 	# 	./IMITATOR Examples/Flipflop/flipflop.imi Examples/Flipflop/flipflop.v0 -mode cover -no-log -time-limit 1 -depth-limit 25
# 	./IMITATOR Examples/Flipflop/flipflop.imi Examples/Flipflop/flipflop.v0 -mode cover -no-log -no-dot

# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop-observer.imi $(EXAMPLE_PATH)/Flipflop/flipflop.v0 -mode cover -cart
# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop/flipflop-observer.imi $(EXAMPLE_PATH)/Flipflop/flipflop.v0 -mode border -cart

# 	./IMITATOR Examples/Flipflop/flipflop_CC.imi -mode statespace -with-parametric-log
# 	./IMITATOR Examples/Flipflop/flipflop_CC.imi Examples/Flipflop/flipflop_CC.pi0
# 	./IMITATOR Examples/Flipflop/flipflop_CC.imi Examples/Flipflop/flipflop_CC.v0 -mode cover -log-prefix Examples/Flipflop/carto1/carto

# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop-inverse/flipflop-inverse.imi
# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop-inverse/flipflop-inverse.imi $(EXAMPLE_PATH)/Flipflop-inverse/flipflop-inverse.imi
# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop-inverse/flipflop-inverse.imi $(EXAMPLE_PATH)/Flipflop-inverse/flipflop-inverse.v0 -mode cover -cart
# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop-inverse/flipflop-inverse.imi $(EXAMPLE_PATH)/Flipflop-inverse/flipflop-inverse.v0 -mode cover -cart -efim
# 	$(TARGET) $(EXAMPLE_PATH)/Flipflop-inverse/flipflop-inverse.imi -mode EF -cart
	
# 	$(TARGETV) $(EXAMPLE_PATH)/Latch/latchValmem.imi $(EXAMPLE_PATH)/Latch/latchValmem.pi0 -with-dot -with-log
# 	$(TARGETV) $(EXAMPLE_PATH)/Latch/latchValmem.imi $(EXAMPLE_PATH)/Latch/latchValmem.pi0 -dynamic-elimination -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/Latch/latchValmem-dynamic
	
	# 	$(TARGET) $(EXAMPLE_PATH)/Latch/latchValmem.imi $(EXAMPLE_PATH)/Latch/latchValmem.pi0 -bab

# 	$(TARGET) $(EXAMPLE_PATH)/SRlatch/SRlatch.imi -mode statespace
# 	$(TARGET) $(EXAMPLE_PATH)/SRlatch/SRlatch.imi $(EXAMPLE_PATH)/SRlatch/SRlatch.pi0
# 	$(TARGETV) $(EXAMPLE_PATH)/SRlatch/SRlatch.imi $(EXAMPLE_PATH)/SRlatch/SRlatch.pi0 -dynamic-elimination
# 	$(TARGET) $(EXAMPLE_PATH)/SRlatch/SRlatch.imi $(EXAMPLE_PATH)/SRlatch/SRlatch.pi0 -bab
# 	$(TARGET) $(EXAMPLE_PATH)/SRlatch/SRlatch.imi $(EXAMPLE_PATH)/SRlatch/SRlatch.v0 -mode cover -output-cart

# 	$(TARGET) $(EXAMPLE_PATH)/SRlatch/SRlatch.imi -mode EF -cart

# 	./IMITATOR Examples/SRlatch/SRlatch_delais_fixes.imi -mode statespace
# 	./IMITATOR Examples/SRlatch/SRlatch_delais_fixes.imi Examples/SRlatch/SRlatch_delais_fixes.pi0
# 	./IMITATOR Examples/SRlatch/SRlatch_delais_fixes.imi Examples/SRlatch/SRlatch_delais_fixes.v0 -mode cover -no-dot

# 	./IMITATOR Examples/SRlatch/sr_latch.hy -mode statespace
# 	./IMITATOR Examples/SRlatch/sr_latch_nand.hy -mode statespace


##### CASE STUDIES : TRAINS #####

# 	$(TARGETV) $(EXAMPLE_PATH)/Train/Train1PTA.imi -PTA2JPG

# 	$(TARGETV) $(EXAMPLE_PATH)/Train/Train1PTA.imi -mode statespace -with-dot -with-log -with-parametric-log
# 	$(TARGETV) $(EXAMPLE_PATH)/Train/Train1PTA.imi -mode EF -with-dot -with-log -with-parametric-log -cart

# 	$(TARGET) $(EXAMPLE_PATH)/Train/Train1PTA.imi $(EXAMPLE_PATH)/Train/Train1PTA.pi0
# 	$(TARGET) $(EXAMPLE_PATH)/Train/Train1PTA.imi $(EXAMPLE_PATH)/Train/Train1PTA-good.pi0
# 	$(TARGET) $(EXAMPLE_PATddH)/Train/Train1PTA.imi $(EXAMPLE_PATH)/Train/Train1PTA-bad.pi0  -with-dot
# 	$(TARGET) $(EXAMPLE_PATH)/Train/Train1PTA.imi $(EXAMPLE_PATH)/Train/Train1PTA.v0 -mode border -cart
# 	$(TARGET) $(EXAMPLE_PATH)/Train/Train1PTA.imi $(EXAMPLE_PATH)/Train/Train1PTA.v0 -mode cover -cart
# 	$(TARGET) $(EXAMPLE_PATH)/Train/Train1PTA.imi -PTA2GrML
# 	$(TARGET) $(EXAMPLE_PATH)/Train/Train1PTA.grml -fromGrML -mode statespace
# 	$(TARGET) $(EXAMPLE_PATH)/Train/Train1PTA.grml $(EXAMPLE_PATH)/Train/Train1PTA.pi0 -fromGrML

# 	$(TARGET) $(EXAMPLE_PATH)/Train/TrainAHV93.imi -PTA2JPG
# 	bin/IMITATOR2.34.111115 $(EXAMPLE_PATH)/Train/TrainAHV93.imi -mode statespace
# 	$(TARGETV) $(EXAMPLE_PATH)/Train/TrainAHV93.imi $(EXAMPLE_PATH)/Train/TrainAHV93.pi0 -with-dot -with-log
# 	$(TARGETV) $(EXAMPLE_PATH)/Train/TrainAHV93.imi $(EXAMPLE_PATH)/Train/TrainAHV93.pi0 -with-dot -with-log -dynamic-elimination -log-prefix $(EXAMPLE_PATH)/Train/TrainAHV93-dynamic
# 	$(TARGET) $(EXAMPLE_PATH)/Train/TrainAHV93.imi $(EXAMPLE_PATH)/Train/TrainAHV93.pi0 -bab


##### CASE STUDIES : PROTOCOLS #####

# 	$(TARGET) $(EXAMPLE_PATH)/Fischer/fischer_2.imi -PTA2JPG
# 	$(TARGETV) $(EXAMPLE_PATH)/Fischer/fischer_2.imi $(EXAMPLE_PATH)/Fischer/fischer_2.pi0

# 	$(TARGETV) $(EXAMPLE_PATH)/Fischer/fischerHRSV02.imi $(EXAMPLE_PATH)/Fischer/fischerHRSV02.pi0
# 	$(TARGET) $(EXAMPLE_PATH)/Fischer/fischerHRSV02_obs.imi $(EXAMPLE_PATH)/Fischer/fischerHRSV02.pi0 -merge -incl -with-dot -depth-limit 80 -fancy
# 	$(TARGET) $(EXAMPLE_PATH)/Fischer/fischerHRSV02_obs.imi -mode EF -merge -incl -depth-limit 80 -cart
# 	$(TARGET) $(EXAMPLE_PATH)/Fischer/fischerHRSV02_obs.imi $(EXAMPLE_PATH)/Fischer/fischerHRSV02.v0 -mode cover -merge -incl -depth-limit 80 -cart -verbose low
# 	$(TARGET) $(EXAMPLE_PATH)/Fischer/fischerHRSV02_obs.imi $(EXAMPLE_PATH)/Fischer/fischerHRSV02.v0 -mode cover -merge -incl -efim -depth-limit 80 -cart -verbose low
# 	$(TARGET) $(EXAMPLE_PATH)/Fischer/fischerHRSV02_obs.imi -PTA2JPG
	
# 	$(TARGET) $(EXAMPLE_PATH)/Fischer/fischerPAT.imi -mode statespace -verbose total
# 	$(TARGET) $(EXAMPLE_PATH)/Fischer/fischerPAT.imi -mode statespace -with-log -with-dot -incl -fancy
# 	$(TARGET) $(EXAMPLE_PATH)/Fischer/fischerPAT.imi -mode statespace -depth-limit 80 -with-log
# 	$(TARGET) $(EXAMPLE_PATH)/Fischer/fischerPAT.imi $(EXAMPLE_PATH)/Fischer/fischerPAT.pi0 -depth-limit 12 -with-log -with-dot
# 	$(TARGET) $(EXAMPLE_PATH)/Fischer/fischerPAT.imi -PTA2JPG
# 	$(TARGETV) $(EXAMPLE_PATH)/Fischer/fischerPAT.imi $(EXAMPLE_PATH)/Fischer/fischerPAT.pi0 -depth-limit 20
# 	$(TARGETV) $(EXAMPLE_PATH)/Fischer/fischerPAT.imi $(EXAMPLE_PATH)/Fischer/fischerPAT.pi0 -dynamic-elimination -verbose low -depth-limit 60 -with-log 

# 	$(TARGET) $(EXAMPLE_PATH)/Fischer/fischerPAT_obs.imi -mode EF -merge -cart
# 	$(TARGET) $(EXAMPLE_PATH)/Fischer/fischerPAT_obs.imi $(EXAMPLE_PATH)/Fischer/fischerPAT.pi0 -merge -with-dot -fancy
# 	$(TARGET) $(EXAMPLE_PATH)/Fischer/fischerPAT_obs.imi $(EXAMPLE_PATH)/Fischer/fischerPAT.v0 -mode cover -merge -cart
# 	$(TARGET) $(EXAMPLE_PATH)/Fischer/fischerPAT_obs.imi $(EXAMPLE_PATH)/Fischer/fischerPAT.v0 -mode cover -efim -merge -cart

# 	$(TARGET) $(EXAMPLE_PATH)/BangOlufsen/BangOlufsen.imi -mode statespace 
# 	$(TARGET) $(EXAMPLE_PATH)/BangOlufsen/BangOlufsen.imi $(EXAMPLE_PATH)/BangOlufsen/BangOlufsen.pi0 -depth-limit 12 -incl -statistics
# 	$(TARGET) $(EXAMPLE_PATH)/BangOlufsen/BangOlufsen.imi $(EXAMPLE_PATH)/BangOlufsen/BangOlufsen.pi0 -depth-limit 12 -incl -no-dot -no-log -statistics -dynamic
# 	$(TARGET) $(EXAMPLE_PATH)/BangOlufsen/BangOlufsen.imi $(EXAMPLE_PATH)/BangOlufsen/BangOlufsen.pi0 -depth-limit 12 -incl -no-dot -no-log -statistics -jobshop

# 	./IMITATOR Examples/BangOlufsen/BangOlufsen2.imi -mode statespace -no-dot
# 	./IMITATOR Examples/BangOlufsen/BangOlufsen2.imi -mode statespace -no-dot -depth-limit 30 -verbose low

	
# 	$(TARGET) $(EXAMPLE_PATH)/BRP/brp.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/BRP/brp.imi -mode statespace 
# 	$(TARGET) $(EXAMPLE_PATH)/BRP/brp.imi $(EXAMPLE_PATH)/BRP/brp.pi0 -merge
# 	$(TARGET) $(EXAMPLE_PATH)/BRP/brp.imi $(EXAMPLE_PATH)/BRP/brp.v0 -mode cover -cart -merge -check-point
# 	$(TARGET) $(EXAMPLE_PATH)/BRP/brp.imi $(EXAMPLE_PATH)/BRP/brp.v0 -mode cover -efim -cart -merge -step 10
# 	$(TARGET) $(EXAMPLE_PATH)/BRP/brp.imi -mode EF -merge -cart
# 	$(TARGETV) $(EXAMPLE_PATH)/BRP/brp.imi $(EXAMPLE_PATH)/BRP/brp.pi0 -with-dot -with-log
# 	$(TARGETV) $(EXAMPLE_PATH)/BRP/brp.imi $(EXAMPLE_PATH)/BRP/brp.pi0 -dynamic-elimination -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/BRP/brp-dynamic
# 	bin/IMITATOR2.6.1 $(EXAMPLE_PATH)/BRP/brp.imi $(EXAMPLE_PATH)/BRP/brp.pi0
# 	$(TARGETV) $(EXAMPLE_PATH)/BRP/brp.imi $(EXAMPLE_PATH)/BRP/brp.pi0
# 	$(TARGET) $(EXAMPLE_PATH)/BRP/brp.imi $(EXAMPLE_PATH)/BRP/brp.pi0 -merge
# 	$(TARGET) $(EXAMPLE_PATH)/BRP/brp.imi $(EXAMPLE_PATH)/BRP/brp.pi0 -merge-before

# 	$(TARGET) $(EXAMPLE_PATH)/RCP/RCP.imi -PTA2JPG

# 	$(TARGET) $(EXAMPLE_PATH)/RCP/RCP-counting.imi $(EXAMPLE_PATH)/RCP/RCP.pi0 -merge
# 	$(TARGET) $(EXAMPLE_PATH)/RCP/RCP-counting.imi $(EXAMPLE_PATH)/RCP/RCP.v0 -mode cover -cart -log-prefix $(EXAMPLE_PATH)/RCP/RCP-counting-BC

# 	$(TARGET) $(EXAMPLE_PATH)/RCP/RCP.imi $(EXAMPLE_PATH)/RCP/RCP.v0 -mode cover -cart -log-prefix $(EXAMPLE_PATH)/RCP/RCP-BC

# 	$(TARGET) $(EXAMPLE_PATH)/RCP/RCP.imi $(EXAMPLE_PATH)/RCP/RCP.v0 -mode cover -cart -merge -log-prefix $(EXAMPLE_PATH)/RCP/RCP-BC-merge
	
# 	$(TARGET) $(EXAMPLE_PATH)/RCP/RCP.imi $(EXAMPLE_PATH)/RCP/RCP.v0 -mode cover -efim -cart -log-prefix $(EXAMPLE_PATH)/RCP/RCP-EFIM
	
# 	$(TARGET) $(EXAMPLE_PATH)/RCP/RCP.imi $(EXAMPLE_PATH)/RCP/RCP.v0 -mode cover -merge -efim -cart -log-prefix $(EXAMPLE_PATH)/RCP/RCP-EFIM-merge
	
# 	$(TARGET) $(EXAMPLE_PATH)/RCP/RCP.imi -mode EF -cart -log-prefix $(EXAMPLE_PATH)/RCP/RCP-EF
	
# 	$(TARGET) $(EXAMPLE_PATH)/RCP/RCP.imi -mode EF -merge -cart -log-prefix $(EXAMPLE_PATH)/RCP/RCP-EF-merge
	
# 	$(TARGET) $(EXAMPLE_PATH)/RCP/RCP.imi $(EXAMPLE_PATH)/RCP/RCP.pi0 -merge
# 	$(TARGETV) $(EXAMPLE_PATH)/RCP/RCP.imi $(EXAMPLE_PATH)/RCP/RCP.pi0 -merge
# 	$(TARGETV) $(EXAMPLE_PATH)/RCP/RCP.imi $(EXAMPLE_PATH)/RCP/RCP.pi0 -with-dot -with-log
# 	$(TARGETV) $(EXAMPLE_PATH)/RCP/RCP.imi $(EXAMPLE_PATH)/RCP/RCP.pi0 -dynamic-elimination -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/RCP/RCP-dynamic
# 	$(TARGET) $(EXAMPLE_PATH)/RCP/RCP.imi $(EXAMPLE_PATH)/RCP/RCP.pi0 -merge-before -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/RCP/RCPmergebefore
# 	$(TARGET) $(EXAMPLE_PATH)/RCP/RCP.imi $(EXAMPLE_PATH)/RCP/RCP.pi0 -dynamic-elimination
# 	$(TARGET) $(EXAMPLE_PATH)/RCP/RCP.imi $(EXAMPLE_PATH)/RCP/RCP.pi0 -bab # PROBLEM BAB
# 	$(TARGET) $(EXAMPLE_PATH)/RCP/RCP.imi $(EXAMPLE_PATH)/RCP/RCP.pi0 -bab -no-merging
# 	$(TARGET) $(EXAMPLE_PATH)/RCP/RCP.imi $(EXAMPLE_PATH)/RCP/RCP.pi0 -no-dot -no-log -statistics -dynamic

# 	./IMITATOR Examples/RCP/RCP_bounded.imi Examples/RCP/RCP_bounded.pi0 -no-dot -no-log

# 	WARNING: the prism model seems odd!!
	
# 	$(TARGET) $(EXAMPLE_PATH)/CSMACD/csmacdPrism.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/CSMACD/csmacdPrism.imi -mode statespace 

# 	bin/IMITATOR2.6.1 $(EXAMPLE_PATH)/CSMACD/csmacdPrism.imi $(EXAMPLE_PATH)/CSMACD/csmacdPrism.pi0
# 	$(TARGETV) $(EXAMPLE_PATH)/CSMACD/csmacdPrism.imi $(EXAMPLE_PATH)/CSMACD/csmacdPrism.pi0
# 	$(TARGETV) $(EXAMPLE_PATH)/CSMACD/csmacdPrism.imi $(EXAMPLE_PATH)/CSMACD/csmacdPrism.pi0 -dynamic-elimination -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/CSMACD/csmacdPrism-dynamic
# 	$(TARGET) $(EXAMPLE_PATH)/CSMACD/csmacdPrism.imi $(EXAMPLE_PATH)/CSMACD/csmacdPrism.pi0 -dynamic-elimination
# 	$(TARGET) $(EXAMPLE_PATH)/CSMACD/csmacdPrism.imi $(EXAMPLE_PATH)/CSMACD/csmacdPrism.pi0 -bab
# 	$(TARGETV) $(EXAMPLE_PATH)/CSMACD/csmacdPrism.imi $(EXAMPLE_PATH)/CSMACD/csmacdPrism.pi0 -statistics

#	### WARNING: the prism model seems odd!!
# 	$(TARGET) $(EXAMPLE_PATH)/CSMACD/csmacdPrism_with_renamed_actions.imi -mode statespace -no-merging
# 	$(TARGET) $(EXAMPLE_PATH)/CSMACD/csmacdPrism_with_renamed_actions.imi $(EXAMPLE_PATH)/CSMACD/csmacdPrism.pi0 -no-merging

# 	$(TARGET) $(EXAMPLE_PATH)/CSMACD/csmacdPrism_with_renamed_actionsBC5.imi $(EXAMPLE_PATH)/CSMACD/csmacdPrism.pi0 -no-merging
	
# 	$(TARGETV) $(EXAMPLE_PATH)/CSMACD/csmacdPrism_with_renamed_actionsBC6.imi $(EXAMPLE_PATH)/CSMACD/csmacdPrism.pi0 -with-log
# 	$(TARGETV) $(EXAMPLE_PATH)/CSMACD/csmacdPrism_with_renamed_actionsBC6.imi $(EXAMPLE_PATH)/CSMACD/csmacdPrism.pi0 -dynamic-elimination -with-log -log-prefix $(EXAMPLE_PATH)/CSMACD/csmacdPrism_with_renamed_actionsBC6-dynamic

# 	$(TARGET) $(EXAMPLE_PATH)/CSMACD/csmacdPrism_with_renamed_actionsBC9.imi $(EXAMPLE_PATH)/CSMACD/csmacdPrism.pi0 -merge
# 	$(TARGET) $(EXAMPLE_PATH)/CSMACD/csmacdPrism_with_renamed_actionsBC10.imi $(EXAMPLE_PATH)/CSMACD/csmacdPrism.pi0 -no-merging

	# 	./IMITATOR Examples/CSMACD/csmacdPrism_2p.imi -mode statespace
# 	./IMITATOR Examples/CSMACD/csmacdPrism_2p.imi Examples/CSMACD/csmacdPrism_2p.pi0 
# 	./IMITATOR Examples/CSMACD/csmacdPrism_2p.imi Examples/CSMACD/csmacdPrism_2p.v0 -mode cover -log-prefix Examples/CSMACD/carto_2p/csmacdPrism_2p

# 	$(TARGET) $(EXAMPLE_PATH)/Wlan/wlan.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/Wlan/wlan.imi -mode statespace
# 	$(TARGETV) $(EXAMPLE_PATH)/Wlan/wlan.imi $(EXAMPLE_PATH)/Wlan/wlan.pi0
# 	$(TARGETV) $(EXAMPLE_PATH)/Wlan/wlan.imi $(EXAMPLE_PATH)/Wlan/wlan.pi0 -with-dot -with-log
# 	$(TARGETV) $(EXAMPLE_PATH)/Wlan/wlan.imi $(EXAMPLE_PATH)/Wlan/wlan.pi0 -dynamic-elimination -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/Wlan/wlan-dynamic
# 	$(TARGET) $(EXAMPLE_PATH)/Wlan/wlan.imi $(EXAMPLE_PATH)/Wlan/wlan.pi0 -merge-before
# 	$(TARGET) $(EXAMPLE_PATH)/Wlan/wlan.imi $(EXAMPLE_PATH)/Wlan/wlan.pi0 -bab

# 	$(TARGET) $(EXAMPLE_PATH)/Wlan/wlan2_without_asap.imi $(EXAMPLE_PATH)/Wlan/wlan2_without_asap.pi0
# 	$(TARGET) $(EXAMPLE_PATH)/Wlan/wlan2_without_asap_without_minmax.imi $(EXAMPLE_PATH)/Wlan/wlan2_without_asap_without_minmax.pi0 -no-dot -no-log

# 	./IMITATOR Examples/Wlan/wlan_boff2.imi Examples/Wlan/wlan_boff2.pi0 -timed

# 	./IMITATOR Examples/Wlan/wlan2_for_im2.imi -mode statespace -verbose low
# 	./IMITATOR Examples/Wlan/wlan2_for_im2.imi Examples/Wlan/wlan2_for_im2.pi0 -timed

##### CASE STUDIES : VALMEM #####

# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall.imi -PTA2JPG 
# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall.imi -mode statespace -verbose total
# 	$(TARGETV) $(EXAMPLE_PATH)/Valmem/spsmall.imi $(EXAMPLE_PATH)/Valmem/spsmall.pi0 -with-dot -with-log
# 	$(TARGETV) $(EXAMPLE_PATH)/Valmem/spsmall.imi $(EXAMPLE_PATH)/Valmem/spsmall.pi0 -dynamic-elimination -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/Valmem/spsmall-dynamic
# 	$(TARGETV) $(EXAMPLE_PATH)/Valmem/spsmall.imi $(EXAMPLE_PATH)/Valmem/spsmall.pi0
# 	bin/IMITATOR2.6.1 $(EXAMPLE_PATH)/Valmem/spsmall.imi $(EXAMPLE_PATH)/Valmem/spsmall.pi0
# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall.imi $(EXAMPLE_PATH)/Valmem/spsmall.pi0 -no-random -bab
# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall.imi $(EXAMPLE_PATH)/Valmem/spsmall.pi0 -with-dot -with-dot-source -fancy
# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall.imi $(EXAMPLE_PATH)/Valmem/spsmall.pi0 -no-dot -no-log -PTA2GrML
# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall.imi $(EXAMPLE_PATH)/Valmem/spsmall.pi0 -no-dot -no-log -statistics
# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall.imi $(EXAMPLE_PATH)/Valmem/spsmall.pi0 -no-dot -no-log -statistics -acyclic
# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall.imi $(EXAMPLE_PATH)/Valmem/spsmall.pi0 -no-dot -no-log -statistics -tree -acyclic
# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall.imi $(EXAMPLE_PATH)/Valmem/spsmall.pi0 -no-dot -no-log -statistics -dynamic

# 	./IMITATOR Examples/Valmem/spsmall_obs.imi -mode statespace -with-parametric-log
# 	./IMITATOR Examples/Valmem/spsmall_obs.imi Examples/Valmem/spsmall.pi0
# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall_obs.imi $(EXAMPLE_PATH)/Valmem/spsmall_obs.v0 -mode cover -cart -log-prefix $(EXAMPLE_PATH)/Valmem/spsmall_obs-BC

# 	bin/IMITATOR261 $(EXAMPLE_PATH)/Valmem/spsmall_nop.imi -mode reachability
	
# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall_obs.imi $(EXAMPLE_PATH)/Valmem/spsmall_obs.v0 -mode cover -merge -cart -log-prefix $(EXAMPLE_PATH)/Valmem/spsmall_obs-BC-merge

# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall_obs.imi $(EXAMPLE_PATH)/Valmem/spsmall_obs.v0 -mode cover -efim -cart -log-prefix $(EXAMPLE_PATH)/Valmem/spsmall_obs-EFIM

# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall_obs.imi $(EXAMPLE_PATH)/Valmem/spsmall_obs.v0 -mode cover -efim -merge -cart -log-prefix $(EXAMPLE_PATH)/Valmem/spsmall_obs-EFIM-merge

# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall_obs.imi -mode EF -cart -log-prefix $(EXAMPLE_PATH)/Valmem/spsmall_obs-EF

# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/spsmall_obs.imi -mode EF -merge -cart -log-prefix $(EXAMPLE_PATH)/Valmem/spsmall_obs-EF-merge

# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/LSV.imi $(EXAMPLE_PATH)/Valmem/delais1_hy.pi0 -merge -incl -with-log -log-prefix $(EXAMPLE_PATH)/Valmem/LSV-merge
# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/LSV.imi $(EXAMPLE_PATH)/Valmem/delais1_hy.pi0 -no-dot -no-log -depth-limit 31 -jobshop -verbose medium
# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/LSV.imi $(EXAMPLE_PATH)/Valmem/delais1_hy.pi0 -no-dot -no-log -statistics -acyclic -dynamic
# 	$(TARGET) $(EXAMPLE_PATH)/Valmem/sp_1x2_md_no.imi Examples/Valmem/sp_1x2_md_no.pi0 

##### CASE STUDIES : SIMOP #####
# 	$(TARGET) $(EXAMPLE_PATH)/SIMOP/simop.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/SIMOP/simop.imi -mode statespace 

# 	$(TARGET) $(EXAMPLE_PATH)/SIMOP/simop.imi $(EXAMPLE_PATH)/SIMOP/simop.pi0 -merge
# 	$(TARGET) $(EXAMPLE_PATH)/SIMOP/simop.imi $(EXAMPLE_PATH)/SIMOP/simop.v0 -merge -mode cover -cart

	# 	$(TARGETV) $(EXAMPLE_PATH)/SIMOP/simop.imi $(EXAMPLE_PATH)/SIMOP/simop.pi0 -merge
# 	$(TARGETV) $(EXAMPLE_PATH)/SIMOP/simop.imi $(EXAMPLE_PATH)/SIMOP/simop.pi0 -dynamic-elimination -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/SIMOP/simop-dynamic
# 	$(TARGET) $(EXAMPLE_PATH)/SIMOP/simop.imi $(EXAMPLE_PATH)/SIMOP/simop.pi0 -merge-before
# 	$(TARGET) $(EXAMPLE_PATH)/SIMOP/simop.imi $(EXAMPLE_PATH)/SIMOP/simop.pi0 -merge -dynamic-elimination
# 	$(TARGET) $(EXAMPLE_PATH)/SIMOP/simop.imi $(EXAMPLE_PATH)/SIMOP/simop.pi0 -no-merging -incl -statistics
# 	$(TARGET) $(EXAMPLE_PATH)/SIMOP/simopTest.imi $(EXAMPLE_PATH)/SIMOP/simopTest.pi0 -bab -no-merging -incl -no-random -with-log -states-limit 30 -with-parametric-log # PROBLEM BAB

# 	$(TARGET) $(EXAMPLE_PATH)/SIMOP/simopTest.imi $(EXAMPLE_PATH)/SIMOP/simopTest.pi0 -no-merging -incl -no-random -with-parametric-log -with-log -states-limit 30 -with-dot

	
# 	$(TARGET) $(EXAMPLE_PATH)/SIMOP/simop.imi $(EXAMPLE_PATH)/SIMOP/simop.pi0 -with-log -with-dot -fancy
# 	$(TARGET) $(EXAMPLE_PATH)/SIMOP/simop.imi $(EXAMPLE_PATH)/SIMOP/simop.pi0 -incl -no-dot -no-log -statistics -dynamic


##### SCHEDULING #####
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/am02.imi -PTA2JPG
# 	$(TARGETV) $(EXAMPLE_PATH)/Scheduling/am02.imi -mode statespace 
# 	$(TARGETV) $(EXAMPLE_PATH)/Scheduling/am02.imi -mode EF -cart -fancy -with-dot
# 	$(TARGETV) $(EXAMPLE_PATH)/Scheduling/am02.imi $(EXAMPLE_PATH)/Scheduling/am02.pi0 -with-dot -fancy
# 	$(TARGETV) $(EXAMPLE_PATH)/Scheduling/am02.imi $(EXAMPLE_PATH)/Scheduling/am02.pi0 -dynamic-elimination -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/Scheduling/am02-dynamic
# 	bin/IMITATOR2.6.1 $(EXAMPLE_PATH)/Scheduling/am02.imi $(EXAMPLE_PATH)/Scheduling/am02.pi0 -merge
# 	$(TARGETV) $(EXAMPLE_PATH)/Scheduling/am02.imi $(EXAMPLE_PATH)/Scheduling/am02.pi0 -merge
## 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/am02.imi $(EXAMPLE_PATH)/Scheduling/am02.pi0 -merge-before -with-dot -with-log
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/am02.imi $(EXAMPLE_PATH)/Scheduling/am02.pi0 -bab # PROBLEM BAB
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/am02.imi $(EXAMPLE_PATH)/Scheduling/am02.pi0 -bab -no-merging

# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/astrium_basic_thermal_fp.imi -PTA2JPG
	# WARNING: PROBLEME ICI AVEC -dynamic
# 	$(TARGETV) $(EXAMPLE_PATH)/Scheduling/astrium_basic_thermal_fp.imi $(EXAMPLE_PATH)/Scheduling/astrium_basic_thermal_fp.pi0 -with-dot -with-log
# 	$(TARGETV) $(EXAMPLE_PATH)/Scheduling/astrium_basic_thermal_fp.imi $(EXAMPLE_PATH)/Scheduling/astrium_basic_thermal_fp.pi0 -dynamic-elimination -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/Scheduling/astrium_basic_thermal_fp-dynamic

# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/bb.imi -PTA2JPG
# 	$(TARGETV) $(EXAMPLE_PATH)/Scheduling/bb.imi $(EXAMPLE_PATH)/Scheduling/bb.pi0 -with-dot -with-log
# 	$(TARGETV) $(EXAMPLE_PATH)/Scheduling/bb.imi $(EXAMPLE_PATH)/Scheduling/bb.pi0 -dynamic-elimination -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/Scheduling/bb-dynamic
	
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/concurent_tasks_chain.imi -PTA2JPG
# 	bin/IMITATOR2.6.1 $(EXAMPLE_PATH)/Scheduling/concurent_tasks_chain.imi $(EXAMPLE_PATH)/Scheduling/concurent_tasks_chain.pi0
# 	$(TARGETV) $(EXAMPLE_PATH)/Scheduling/concurent_tasks_chain.imi $(EXAMPLE_PATH)/Scheduling/concurent_tasks_chain.pi0
# 	$(TARGETV) $(EXAMPLE_PATH)/Scheduling/concurent_tasks_chain.imi $(EXAMPLE_PATH)/Scheduling/concurent_tasks_chain.pi0 -with-dot -with-log
# 	$(TARGETV) $(EXAMPLE_PATH)/Scheduling/concurent_tasks_chain.imi $(EXAMPLE_PATH)/Scheduling/concurent_tasks_chain.pi0 -dynamic-elimination -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/Scheduling/concurent_tasks_chain-dynamic
# 	$(TARGETV) $(EXAMPLE_PATH)/Scheduling/concurent_tasks_chain.imi $(EXAMPLE_PATH)/Scheduling/concurent_tasks_chain.pi0 -merge -dynamic-elimination -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/Scheduling/concurent_tasks_chain-dynamic-merge
	
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/full_cpr08.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/full_cpr08.imi $(EXAMPLE_PATH)/Scheduling/full_cpr08.pi0 -merge -with-dot -with-log -depth-limit 30

# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/generic_edf.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/generic_edf.imi $(EXAMPLE_PATH)/Scheduling/generic_edf.pi0 -merge -with-dot -with-log

# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/generic_fp.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/generic_fp.imi $(EXAMPLE_PATH)/Scheduling/generic_fp.pi0 -merge -with-dot -with-log

# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/hppr10_audio.imi -PTA2JPG
# 	$(TARGETV) $(EXAMPLE_PATH)/Scheduling/hppr10_audio.imi $(EXAMPLE_PATH)/Scheduling/hppr10_audio.pi0 -with-dot -with-log
# 	$(TARGETV) $(EXAMPLE_PATH)/Scheduling/hppr10_audio.imi $(EXAMPLE_PATH)/Scheduling/hppr10_audio.pi0 -dynamic-elimination -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/Scheduling/hppr10_audio-dynamic
	
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/LA02_2.imi -PTA2JPG

# 	$(TARGETV) $(EXAMPLE_PATH)/Scheduling/LA02_2.imi $(EXAMPLE_PATH)/Scheduling/LA02_2.pi0 -with-dot -with-log
# 	$(TARGETV) $(EXAMPLE_PATH)/Scheduling/LA02_2.imi $(EXAMPLE_PATH)/Scheduling/LA02_2.pi0 -dynamic-elimination -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/Scheduling/LA02_2-dynamic
	
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/LA02_2.imi $(EXAMPLE_PATH)/Scheduling/LA02_2.pi0 -merge-before -with-dot -with-log

# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/LA02_2_2.5.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/LA02_2_2.5.imi $(EXAMPLE_PATH)/Scheduling/LA02_2.pi0 -merge -with-dot -with-log
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/LA02_2_2.5.imi $(EXAMPLE_PATH)/Scheduling/LA02_2.pi0 -merge-before -with-dot -with-log

# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/LA02_3.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/LA02_3.imi $(EXAMPLE_PATH)/Scheduling/LA02_3.pi0 -merge
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/LA02_3.imi $(EXAMPLE_PATH)/Scheduling/LA02_3.pi0 -merge-before

# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/preemptive_maler.imi -PTA2JPG
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/preemptive_maler.imi $(EXAMPLE_PATH)/Scheduling/preemptive_maler.pi0 -merge -with-dot -with-log
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/preemptive_maler.imi $(EXAMPLE_PATH)/Scheduling/preemptive_maler.pi0 -merge-before -with-dot -with-log

# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/test3.imi $(EXAMPLE_PATH)/Scheduling/test3.v0 -mode cover -cart -merge
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/test3.imi $(EXAMPLE_PATH)/Scheduling/test3.v0 -mode cover -cart -efim -merge
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/test3.imi -mode EF -cart -merge

# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/test5.imi $(EXAMPLE_PATH)/Scheduling/test5.v0 -mode cover -merge -cart -log-prefix $(EXAMPLE_PATH)/Scheduling/test5-BCmerge2535
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/test5.imi -mode EF -incl -merge -cart -log-prefix $(EXAMPLE_PATH)/Scheduling/test5-EFmergeUnbounded -depth-limit 400
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/test5.imi $(EXAMPLE_PATH)/Scheduling/test5.v0 -mode cover -efim -merge -cart -log-prefix $(EXAMPLE_PATH)/Scheduling/test5-EFIMmerge20301525

# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/fmtv-challenge2-v1.imi -mode EF -merge -incl -cart -merge
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/fmtv-challenge2-v1.imi $(EXAMPLE_PATH)/Scheduling/fmtv-challenge2-v1.v0 -mode cover -merge
# 	bin/IMITATOR668 $(EXAMPLE_PATH)/Scheduling/fmtv-challenge2-v1.imi $(EXAMPLE_PATH)/Scheduling/fmtv-challenge2-v1.v0 -mode cover -merge
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/fmtv-challenge2-v1.imi $(EXAMPLE_PATH)/Scheduling/fmtv-challenge2-v1.v0 -mode cover -merge -efim






# 	$(TARGET) $(EXAMPLE_PATH)/Polyhedra/polyhedron1.imi $(EXAMPLE_PATH)/Polyhedra/polyhedron1.v0 -mode cover -cart

# 	$(TARGET) $(EXAMPLE_PATH)/Tests/testpoly.imi -cartonly

# 	$(TARGET) $(EXAMPLE_PATH)/Others/test.imi $(EXAMPLE_PATH)/Others/test.pi0 -with-dot -with-log -with-parametric-log -depth-limit 7 -verbose high -fancy
# 	$(TARGET) $(EXAMPLE_PATH)/Others/test2.imi $(EXAMPLE_PATH)/Others/test2.v0 -mode cover -incl -merge -cart -with-dot
# 	$(TARGET) $(EXAMPLE_PATH)/Others/test3.imi $(EXAMPLE_PATH)/Others/test3.v0 -mode cover -merge -cart
# 	$(TARGET) $(EXAMPLE_PATH)/Others/test3.imi $(EXAMPLE_PATH)/Others/test3.v0 -mode border -merge -cart -step 0.1
# 	$(TARGET) $(EXAMPLE_PATH)/Others/test4.imi $(EXAMPLE_PATH)/Others/test4.v0 -mode border -merge -cart
# 	$(TARGET) $(EXAMPLE_PATH)/Others/giuseppe.imi $(EXAMPLE_PATH)/Others/giuseppe.v0 -mode border -incl -merge -depth-limit 15
# 	$(TARGET) $(EXAMPLE_PATH)/Others/giuseppe3.imi $(EXAMPLE_PATH)/Others/giuseppe3.v0 -mode cover -incl -merge -timed 
# 	$(TARGET) $(EXAMPLE_PATH)/Others/giuseppe_opt.imi $(EXAMPLE_PATH)/Others/giuseppe_opt.v0 -mode cover -incl -merge
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/example-miss.imi $(EXAMPLE_PATH)/Scheduling/example-miss.v0 -mode cover -incl -merge -depth-limit 100 -cart
#	$(TARGET) $(EXAMPLE_PATH)/Scheduling/example-miss.imi $(EXAMPLE_PATH)/Scheduling/example-miss.pi0 -incl -merge -cart -depth-limit 100
# 	$(TARGET) $(EXAMPLE_PATH)/Scheduling/example-miss.imi -mode EF -merge -depth-limit 15 -cart

##### JOB SHOP #####
# 	$(TARGET) $(EXAMPLE_PATH)/Jobshop/maler_2_4.imi -mode statespace -incl 

# 	$(TARGET) $(EXAMPLE_PATH)/Jobshop/maler_2_4.imi $(EXAMPLE_PATH)/Jobshop/maler_2_4.pi0
# 	$(TARGETV) $(EXAMPLE_PATH)/Jobshop/maler_2_4.imi $(EXAMPLE_PATH)/Jobshop/maler_2_4.pi0 -with-dot -with-log
# 	$(TARGETV) $(EXAMPLE_PATH)/Jobshop/maler_2_4.imi $(EXAMPLE_PATH)/Jobshop/maler_2_4.pi0 -dynamic-elimination -with-dot -with-log -log-prefix $(EXAMPLE_PATH)/Jobshop/maler_2_4-dynamic
# 	$(TARGET) $(EXAMPLE_PATH)/Jobshop/maler_2_4.imi $(EXAMPLE_PATH)/Jobshop/maler_2_4.pi0 -merge-before
# 	$(TARGET) $(EXAMPLE_PATH)/Jobshop/maler_2_4.imi $(EXAMPLE_PATH)/Jobshop/maler_2_4.pi0 -acyclic -statistics
# 	$(TARGET) $(EXAMPLE_PATH)/Jobshop/maler_2_4.imi $(EXAMPLE_PATH)/Jobshop/maler_2_4.pi0 -incl
# 	$(TARGET) $(EXAMPLE_PATH)/Jobshop/maler_2_4.imi $(EXAMPLE_PATH)/Jobshop/maler_2_4.pi0 -bab # PROBLEM BAB


# 	$(TARGET) $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi -mode statespace -no-dot -no-log -incl -acyclic -statistics -dynamic
# 	$(TARGET) $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi -mode statespace -no-dot -no-log -incl -acyclic -jobshop -statistics
# 	bin/IMITATOR2.4 $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi -mode statespace -no-dot -no-log -incl -acyclic -jobshop -statistics
# 	bin/IMITATOR2.375 $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi -mode statespace -no-dot -no-log -incl -acyclic -jobshop
# 	bin/IMITATOR2.374 $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi -mode statespace -no-dot -no-log -incl -acyclic -jobshop
# 	bin/IMITATOR2.371 $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi -mode statespace -no-dot -no-log -incl -acyclic -statistics -jobshop
# 	bin/IMITATOR2.36 $(EXAMPLE_PATH)/Jobshop/maler_3_4_inst.imi -mode statespace -no-dot -no-log -incl -acyclic -statistics
# 	bin/IMITATOR2.35 $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi -mode statespace -no-dot -no-log -incl -statistics -depth-limit 10
# 	bin/IMITATOR2.34.111115 $(EXAMPLE_PATH)/Jobshop/maler_3_4_inst.imi -mode statespace -no-dot -no-log -IMincl

# 	$(TARGET) $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi $(EXAMPLE_PATH)/Jobshop/maler_3_4.pi0 -merge -timed
# 	$(TARGET) $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi $(EXAMPLE_PATH)/Jobshop/maler_3_4.pi0 -incl -merge-before -timed
# 	bin/IMITATOR2.41 $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi $(EXAMPLE_PATH)/Jobshop/maler_3_4.pi0 -no-dot -no-log -incl
# 	bin/IMITATOR2.4 $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi $(EXAMPLE_PATH)/Jobshop/maler_3_4.pi0 -no-dot -no-log -incl -jobshop
# 	bin/IMITATOR2.375 $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi $(EXAMPLE_PATH)/Jobshop/maler_3_4.pi0 -no-dot -no-log -incl -jobshop
# 	bin/IMITATOR2.371 $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi $(EXAMPLE_PATH)/Jobshop/maler_3_4.pi0 -no-dot -no-log -incl -statistics -depth-limit 9

# 	$(TARGET) $(EXAMPLE_PATH)/Jobshop/maler_3_4_inst.imi -mode statespace -no-dot -no-log -incl -statistics
# 	bin/IMITATOR2.36 $(EXAMPLE_PATH)/Jobshop/maler_3_4_inst.imi -mode statespace -no-dot -no-log -incl -statistics
# 	bin/IMITATOR2.35 $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi_inst -mode statespace -no-dot -no-log -incl -statistics
# 	bin/IMITATOR2.34.111115 $(EXAMPLE_PATH)/Jobshop/maler_3_4_inst.imi -mode statespace -no-dot -no-log -IMincl

# 	$(TARGET) $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi -mode statespace -no-dot -no-log -incl -statistics
# 	bin/IMITATOR2.371 $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi -mode statespace -no-dot -no-log -incl -statistics
# 	bin/IMITATOR2.370 $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi -mode statespace -no-dot -no-log -incl -statistics
# 	bin/IMITATOR2.36 $(EXAMPLE_PATH)/Jobshop/maler_3_4.ancien.imi -mode statespace -no-dot -no-log -incl -statistics
# 	bin/IMITATOR2.35 $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi -mode statespace -no-dot -no-log -incl -statistics
# 	bin/IMITATOR2.34.111115 $(EXAMPLE_PATH)/Jobshop/maler_3_4.imi -mode statespace -no-dot -no-log -IMincl


# 	$(TARGET) $(EXAMPLE_PATH)/Jobshop/maler_4_4.imi -mode statespace -no-dot -no-log -incl -statistics -PTA2GrML
# 	$(TARGET) $(EXAMPLE_PATH)/Jobshop/maler_4_4.imi -mode statespace -no-dot -no-log -incl -acyclic -depth-limit 10
# 	bin/IMITATOR2.375 $(EXAMPLE_PATH)/Jobshop/maler_4_4.imi -mode statespace -no-dot -no-log -incl -acyclic -depth-limit 10
# 	bin/IMITATOR2.370 $(EXAMPLE_PATH)/Jobshop/maler_4_4.imi -mode statespace -no-dot -no-log -incl -statistics -depth-limit 8
# 	bin/IMITATOR2.36 $(EXAMPLE_PATH)/Jobshop/maler_4_4.imi -mode statespace -no-dot -no-log -incl -statistics



count: clean
	@ for f in src/*.ml src/*.mli ; do wc -l $$f; done | sort -n -r -


clean: rmtpf rmuseless
	@rm -rf $(OBJS) $(OBJS_OPT) $(CMIS)  $(PAR_ML) $(PAR_CMI) $(OBJS:.cmo=.o)
	@rm -rf $(LEX_CMI) $(LEX_ML)
	@for f in $(PARSERS); do rm -rf src/$$f.mli; done
	@rm -rf $(TARGET) $(IMILIB) $(TARGET_OPT) $(IMILIB_OPT)
	@rm -rf .depend
	@echo [Now clean]

rmtpf:
	@rm -rf *~


rmuseless:
	@rm -rf $(FILES:+=cmo) $(FILES:+=cmx) $(FILES:+=cmi) $(FILES:+=o) $(MAIN) $(MAIN:.cmo=.cmi) $(MAIN:.cmo=.cmx)
	@rm -rf $(FILESMLI:+=cmi)
 
# include .depend
