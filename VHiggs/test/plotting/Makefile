# Makefile to build the correct data cards
#
# Important targets:
#
# General analysis
# ================
#
#  fake_rates.C:	build the fake rate correction functions
#
# Limit Setting
# =============
#
#  For the limits, the channel can be selected by:
#  	make channel=XXX [target], where XXX is in [combined, emt, mmt]
#
#  analyze: 		run the analysis (maybe doing the fake rates to)
#
#  cards: 		build the ASCII and .root cards 
#  asymp: 		compute the asymptotic limits
#  asympplot: 		make the asymptotic limit plot
#  clsplot: 		make the CLs limit plot
#
#  cls_submits: 	builds the submit directories (in $scratch/cls_limits) 
#  			to submit condor jobs
#  grids: 		hadd add together the results from the condor jobs
#  			(requires condor jobs from cls_submits to be finished)
#  cls: 		compute the CLs limits 
#  			(requires condor jobs from cls_submits to be finished)
#
#  table: 		make a .tex table with the results

# The name of the un-stat-shaped root file - output of the analysis
raw_shape_file=wh_shapes_raw.root

################################################################################
##
##         ==============
##         Analysis Tasks 
##         ==============
##
################################################################################

################################################################################
## Computing the fake rates ####################################################
################################################################################

# How to build the single muon fake rate result file
results_singleMuFakeRates.root: singleMuFakeRates.py
	python singleMuFakeRates.py

results_fakeRates.root: fakeRates.py
	python fakeRates.py

# How to combine all the fake rate measurements
fake_rates.json: results_singleMuFakeRates.root results_fakeRates.root combineFakeRates.py
	python combineFakeRates.py

# How to turn it into a ROOT macro
fake_rates.C: fake_rates.json make_fakerates.py
	python make_fakerates.py

################################################################################
## Building the correction factors #############################################
################################################################################

# Measure the MuEG trigger efficiency
mueg_trig_correction_results.json: muEGTriggerMeasurement.py
	python muEGTriggerMeasurement.py

# Produce the corrections root macro
corrections.C: mueg_trig_correction_results.json make_corrections.py
	python make_corrections.py

################################################################################
## The main analysis job  ######################################################
################################################################################

# Define the files produced by the analysis
ana_output=$(raw_shape_file) #mmt_mumu_events.json emt_emu_events.json mmt_mumu_fakerate_summary.json emt_emu_fakerate_summary.json emt_emu_summary.json mmt_mumu_summary.json

#$(ana_output): analysis.py analysis_cfg.py corrections.C fake_rates.C
	#python analysis.py

#analyze: $(ana_output)


################################################################################
##
##         =============
##         Limit Setting
##         =============
##
################################################################################

clean:
	rm -f cards/*

################################################################################
## Building "statistical" shape uncertainties ##################################
################################################################################

# The naem of the shape root file with interpolated histograms
interp_shape_file=wh_shapes_interp.root
# The naem of the shape root file with the FF and SM4 templates
extensions_shape_file=wh_shapes_sm4_ff.root
# The name of the shape root file
shape_file=vhtt_shapes.root
# Mass points to run limits on
#masspoints=100 110 120 130 140 150 160 
#masspoints=110 120 130 140 
masspoints=110 115 120 125 130 135 140 145 150 160
# Exclusion range to use when building CLs grid
min_cls="0.2"
max_cls="70"
channel=combined
# Optionally change which final selection is used to make the limits
selection=final


# Define the cards we want to make
txt_cards=$(patsubst %, cards/$(channel)_%.txt,$(masspoints))
root_cards=$(patsubst %, cards/$(channel)_%.root,$(masspoints))
extra_txt_cards=$(patsubst %, cards/$(channel)_%FF.txt,$(masspoints)) $(patsubst %, cards/$(channel)_%SM4.txt,$(masspoints)) 
cls_submitters=$(patsubst %, $(scratch)/cls_limits/$(channel)_%/submit,$(masspoints))
asymp_results=$(patsubst %, cards/$(channel)_%.asymp.json,$(masspoints))
cls_results=$(patsubst %, cards/$(channel)_%.cls.json,$(masspoints))

cards: $(shape_file) $(txt_cards) $(root_cards)

extra_cards: $(extra_txt_cards)

cls_submits: $(cls_submitters)

grids: $(patsubst %, $(scratch)/cls_limits/$(channel)_%/grid.root,$(masspoints))

asymp: $(asymp_results)

asympplot: cards/$(channel).asymp.pdf

cls: $(cls_results)

clsplot: cards/$(channel).cls.pdf cards/$(channel).cls.tex

vh_cards.tgz: $(root_cards)
	tar -cvzf $@ $(root_cards)

vh_cards_txt.tgz: $(txt_cards)
	tar -cvzf $@ $(shape_file) $(txt_cards)

# Make the tex table for the note
table: final_yields.tex

final_yields.tex: $(shape_file) make_tex_tables.py
	./make_tex_tables.py -f $(shape_file) > $@

# Just show what mass points we are running
ls_mass_points: 
	echo $(masspoints)

################################################################################
## Building "statistical" shape uncertainties ##################################
################################################################################

# Add missing signal mass points
$(interp_shape_file): $(raw_shape_file) interpolateSignalHistograms.py
	cp $(raw_shape_file) $(interp_shape_file)
	./interpolateSignalHistograms.py $(interp_shape_file)

# Add Fermiphobic and SM4 corrected templates
$(extensions_shape_file): $(interp_shape_file) addSMExtensions.py
	cp $(interp_shape_file) $(extensions_shape_file)
	./addSMExtensions.py $(extensions_shape_file)

$(shape_file): $(extensions_shape_file) addStatShapes.py
	cp $(extensions_shape_file) $(shape_file)
	./addStatShapes.py $(shape_file)

# Make a copy in the cards directory
cards/$(shape_file): $(shape_file)
	cp $< $@

################################################################################
## Building the data cards themselves  #########################################
################################################################################

# Rule to make a $(channel) ASCII card
cards/$(channel)_%.txt: $(shape_file) make_data_card.py
	python make_data_card.py -o $@ -m $* -f $(shape_file) \
	  --channels $(channel) --selection $(selection) \
	  --emt_shape SubleadingMass \
	  --mmt_shape MuTauMass 
	  #--emt_shape count \
	  #--mmt_shape count 

# Rule to make a RooWorkspace card from an ASCII one
cards/$(channel)_%.root: cards/$(channel)_%.txt
	text2workspace.py $< -o $@

################################################################################
## Computing the asymptotic limit ##############################################
################################################################################

# Rule to compute the asymptotic limit from a given card file
cards/$(channel)_%.asymp.json: cards/$(channel)_%.root
	combine $< -M Asymptotic -H ProfileLikelihood \
	  -m `echo $* | sed "s|FF||" | sed "s|SM4||" | sed "s|WW||" | sed "s|tt||"` \
	  | limit2JSON.py --mass $* > $@
	rm higgsCombineTest.Asymptotic.mH`echo $* | sed "s|FF||" | sed "s|SM4||"| sed "s|WW||" | sed "s|tt||"`.root

################################################################################
## Tools for computing the full CLs limits  ####################################
################################################################################

# Rule to generate a submit directories
# The script to make the submit files is in StatTools/scripts
$(scratch)/cls_limits/$(channel)_%/submit: cards/$(channel)_%.root
	make_grid_submission.py -submitdir `dirname $@` \
	  -i `readlink -f $<`  -mass $* \
	  -min $(min_cls) -max $(max_cls)

# Now define the $(channel) grid result - will get updated as more files show up 
# This combines all the points into a "mass slice"
$(scratch)/cls_limits/$(channel)_%/grid.root: $(scratch)/cls_limits/$(channel)_%/point_*root
	hadd -f $@ $^ 

# Given the card file and the computed grid, compute the obs and exp CLs limits
cards/$(channel)_%.cls.json: cards/$(channel)_%.root $(scratch)/cls_limits/$(channel)_%/grid.root 
	compute_cls.sh $^ $* > $@

################################################################################
## Tools for plotting the limits ###############################################
################################################################################

# Rule to plot the CLs limits
cards/$(channel).cls.pdf: $(cls_results) legendpos.py
	python $(fsa)/StatTools/scripts/plotlimit.py \
	  --max-y 40 \
	  --lumi 5000 \
	  --method cls cards/$(channel)_*.cls.json -o $@ \
	  --showpoints \
	  --blurb "`./blurbtext.py $@`" \
	  --blurbpos "0.15, 0.12, 0.5, 0.20" \
	  --legendpos `./legendpos.py $@`

cards/$(channel).cls.tex: $(cls_results)  
	python $(fsa)/StatTools/scripts/texlimit.py \
	  --method cls cards/$(channel)_*.cls.json > $@

cards/$(channel).asymp.tex: $(asymp_results)  
	python $(fsa)/StatTools/scripts/texlimit.py \
	  --method asymp cards/$(channel)_*.asymp.json > $@

# Rule to plot the asymptotic limits
cards/$(channel).asymp.pdf: $(asymp_results) legendpos.py
	python $(fsa)/StatTools/scripts/plotlimit.py \
	  --max-y 40 \
	  --lumi 5000 \
	  --method asymp cards/$(channel)_*.asymp.json -o $@ \
	  --showpoints \
	  --blurb "`./blurbtext.py $@`" \
	  --blurbpos "0.5, 0.15, 0.95, 0.22" \
	  --blurbalign 11
	  --legendpos `./legendpos.py $@`


################################################################################
## Tools for committing into combination SVN ###################################
################################################################################

combination=moriond12
combination_mass_points=$(shell seq 110 140) 
#combination_FF_mass_points=$(shell seq 120 145)

combination_cards: $(patsubst %, $(combination)/%/vhtt.txt, $(combination_mass_points)) \
  $(patsubst %, $(combination)/%/SM4_vhtt.txt, $(combination_mass_points))  \
  $(patsubst %, $(combination)/%/vhtt_shapes.root, $(combination_mass_points)) 

#$(patsubst %, $(combination)/%/FF_vhtt.txt, $(combination_FF_mass_points)) \

# Make a version of the shape file with minimal info
$(combination)/%/vhtt_shapes.root: $(shape_file) trim_shape_file.py
	./trim_shape_file.py --mass $* --out $@ $(shape_file) \
	  emt_emu_final_count \
	  mmt_mumu_final_count

$(combination)/%/vhtt.txt: cards/combined_%.txt $(combination)/%/vhtt_shapes.root
	cp $< $@

$(combination)/%/FF_vhtt.txt: cards/combined_%FF.txt $(combination)/%/vhtt_shapes.root
	cp $< $@

$(combination)/%/SM4_vhtt.txt: cards/combined_%SM4.txt $(combination)/%/vhtt_shapes.root
	cp $< $@

################################################################################
## Debug cards, using only TauTau and WW contributions #########################
################################################################################

debug_points=120 130 140 150 160
debug_cards: $(patsubst %, cards/$(channel)_%tt.txt, $(debug_points)) \
  $(patsubst %, cards/$(channel)_%WW.txt, $(debug_points))

debug_limits: $(patsubst %, cards/$(channel)_%tt.asymp.json, $(debug_points)) \
  $(patsubst %, cards/$(channel)_%WW.asymp.json, $(debug_points))

debug_plots: debug_limits
	python $(fsa)/StatTools/scripts/plotlimit.py cards/$(channel)*WW.asymp.json --method asymp --label WW -o cards/$(channel)_wwOnly.pdf --max-y 70 --showpoints --blurb "$(channel) WW only"
	python $(fsa)/StatTools/scripts/plotlimit.py cards/$(channel)*tt.asymp.json --method asymp --label tt -o cards/$(channel)_ttOnly.pdf --max-y 70 --showpoints --blurb "$(channel) tautau only"

################################################################################
## AN-12-076 (ZH only cards) ###################################################
################################################################################

zh_mass_points=$(shell seq 110 10 160) 

zh_cards/card_%.root: zh_cards/hzz2l2t_%.txt 
	text2workspace.py $< -o $@

zh_cards/card_%.asymp.json: zh_cards/card_%.root
	combine $< -M Asymptotic -H ProfileLikelihood \
	  -m `echo $* | sed "s|FF||" | sed "s|SM4||" | sed "s|WW||" | sed "s|tt||"` \
	  | limit2JSON.py --mass $* > $@
	rm higgsCombineTest.Asymptotic.mH`echo $* | sed "s|FF||" | sed "s|SM4||"| sed "s|WW||" | sed "s|tt||"`.root

zh_asymp: $(patsubst %, zh_cards/card_%.asymp.json, $(zh_mass_points)) $(patsubst %, zh_cards/card_%.root, $(zh_mass_points))

zh_cards/zh_asymp.pdf: zh_asymp
	python $(fsa)/StatTools/scripts/plotlimit.py \
	  --max-y 35 \
	  --lumi 5000 \
	  --method asymp zh_cards/card*asymp.json -o $@ \
	  --showpoints \
	  --blurb "" \
	  --blurbpos "0.15, 0.12, 0.5, 0.20" \
	  --legendpos "0.2,0.68,0.45,0.92"
	
################################################################################
## HIG-12-010   ################################################################
################################################################################

#wh3l_cards=/afs/cern.ch/user/c/ceballos/public/limits/limits_wh3l/sm/
wh3l_cards=$(PWD)/3l_cards/

trilepton_mass_points=$(shell seq 110 10 140) $(shell seq 150 10 200)

trilepton_cards/combined_%.txt: cards/vhtt_shapes.root cards/combined_%.txt $(wh3l_cards)/%/vh3l_cut.txt  zh_cards/hzz2l2t_%.txt zh_cards/*.root
	combineCards.py -S TT=cards/combined_$*.txt WWW=$(wh3l_cards)/$*/vh3l_cut.txt ZH=zh_cards/hzz2l2t_$*.txt > $@

trilepton_cards/combined_%.root: trilepton_cards/combined_%.txt
	text2workspace.py $< -o $@

trilepton_cards/combined_170.txt: $(wh3l_cards)/170/vh3l_cut.txt
	combineCards.py -S WWW=$(wh3l_cards)/170/vh3l_cut.txt > $@

trilepton_cards/combined_180.txt: $(wh3l_cards)/180/vh3l_cut.txt
	combineCards.py -S WWW=$(wh3l_cards)/180/vh3l_cut.txt > $@

trilepton_cards/combined_190.txt: $(wh3l_cards)/190/vh3l_cut.txt
	combineCards.py -S WWW=$(wh3l_cards)/190/vh3l_cut.txt > $@

trilepton_cards/combined_200.txt: $(wh3l_cards)/200/vh3l_cut.txt
	combineCards.py -S WWW=$(wh3l_cards)/200/vh3l_cut.txt > $@

trilepton_cards/combined_%.asymp.json: trilepton_cards/combined_%.txt
	combine $< -M Asymptotic -H ProfileLikelihood \
	  -m `echo $* | sed "s|FF||" | sed "s|SM4||" | sed "s|WW||" | sed "s|tt||"` \
	  | limit2JSON.py --mass $* > $@
	rm higgsCombineTest.Asymptotic.mH`echo $* | sed "s|FF||" | sed "s|SM4||"| sed "s|WW||" | sed "s|tt||"`.root

trilep_cards_jobs=$(patsubst %, trilepton_cards/combined_%.txt, $(trilepton_mass_points))

trilep_asymp_jobs=$(patsubst %, trilepton_cards/combined_%.asymp.json, $(trilepton_mass_points))

trilepton_limits: $(trilep_cards_jobs) $(trilep_asymp_jobs) 

trilepton_cards/combined.asymp.pdf: trilepton_limits
	python $(fsa)/StatTools/scripts/plotlimit.py \
	  --max-y 20 \
	  --lumi 5000 \
	  --method asymp trilepton_cards/combined_*.asymp.json -o $@ \
	  --showpoints \
	  --blurb "`./blurbtext.py $@`" \
	  --blurbpos "0.15, 0.12, 0.5, 0.20" \
	  --legendpos `./legendpos.py $@`

################################################################################
## HIG-12-010   CL_s method ####################################################
################################################################################
$(scratch)/trilep_cls_limits/combined_%/submit: trilepton_cards/combined_%.root
	make_grid_submission.py -submitdir `dirname $@` \
	  -i `readlink -f $<`  -mass $* \
	  -min 0.2 -max 30

# Now define the $(channel) grid result - will get updated as more files show up 
# This combines all the points into a "mass slice"
$(scratch)/trilep_cls_limits/combined_%/grid.root: $(scratch)/trilep_cls_limits/combined_%/point_*root
	hadd -f $@ $^ 

# Given the card file and the computed grid, compute the obs and exp CLs limits
trilepton_cards/limit_%.cls.json: trilepton_cards/combined_%.txt $(scratch)/trilep_cls_limits/combined_%/grid.root
	compute_cls.sh $^ $* > $@

trilepton_cls_submitters=$(patsubst %, $(scratch)/trilep_cls_limits/combined_%/submit, $(trilepton_mass_points))

trilepton_cls_results=$(patsubst %, trilepton_cards/limit_%.cls.json, $(trilepton_mass_points))

trilepton_cls_grids=$(patsubst %, $(scratch)/trilep_cls_limits/combined_%/grid.root, $(trilepton_mass_points))

trilepton_cls_submits: $(trilepton_cls_submitters)

trilepton_cls: $(trilepton_cls_results) $(trilepton_cls_grids)

trilepton_cards/combined.cls.pdf: trilepton_cls
	python $(fsa)/StatTools/scripts/plotlimit.py \
	  --max-y 20 \
	  --lumi 5000 \
	  --method cls trilepton_cards/limit_*.cls.json -o $@ \
	  --showpoints \
	  --blurb "`./blurbtext.py $@`" \
	  --blurbpos "0.15, 0.12, 0.5, 0.20" \
	  --legendpos `./legendpos.py $@`

################################################################################
## Now the versions with HBB, etc ##############################################
################################################################################

paper_mass_points=$(shell seq 110 10 140) $(shell seq 150 10 200)

paper_cards/combined_%.txt: cards/vhtt_shapes.root cards/combined_%.txt $(wh3l_cards)/%/vh3l_cut.txt zh_cards/hzz2l2t_%.txt zh_cards/*.root  post-moriond12/%/hgglep.mH*.0.txt
	combineCards.py -S TT=cards/combined_$*.txt WWW=$(wh3l_cards)/$*/vh3l_cut.txt ZH=zh_cards/hzz2l2t_$*.txt GG=post-moriond12/$*/hgglep.mH$*.0.txt > $@

paper_cards/combined_%.root: paper_cards/combined_%.txt
	text2workspace.py $< -o $@

# No BB for 160
paper_cards/combined_160.txt: cards/vhtt_shapes.root cards/combined_160.txt $(wh3l_cards)/160/vh3l_cut.txt zh_cards/hzz2l2t_160.txt zh_cards/*.root  
	combineCards.py -S TT=cards/combined_160.txt WWW=$(wh3l_cards)/160/vh3l_cut.txt ZH=zh_cards/hzz2l2t_160.txt > $@

paper_cards/combined_170.txt: $(wh3l_cards)/170/vh3l_cut.txt
	combineCards.py -S WWW=$(wh3l_cards)/170/vh3l_cut.txt > $@

paper_cards/combined_180.txt: $(wh3l_cards)/180/vh3l_cut.txt
	combineCards.py -S WWW=$(wh3l_cards)/180/vh3l_cut.txt > $@

paper_cards/combined_190.txt: $(wh3l_cards)/190/vh3l_cut.txt
	combineCards.py -S WWW=$(wh3l_cards)/190/vh3l_cut.txt > $@

paper_cards/combined_200.txt: $(wh3l_cards)/200/vh3l_cut.txt
	combineCards.py -S WWW=$(wh3l_cards)/200/vh3l_cut.txt > $@

paper_cards/combined_%.asymp.json: paper_cards/combined_%.txt
	combine $< -M Asymptotic -H ProfileLikelihood \
	  -m `echo $* | sed "s|FF||" | sed "s|SM4||" | sed "s|WW||" | sed "s|tt||"` \
	  | limit2JSON.py --mass $* > $@
	rm higgsCombineTest.Asymptotic.mH`echo $* | sed "s|FF||" | sed "s|SM4||"| sed "s|WW||" | sed "s|tt||"`.root

paper_cards_jobs=$(patsubst %, paper_cards/combined_%.txt, $(paper_mass_points))

paper_asymp_jobs=$(patsubst %, paper_cards/combined_%.asymp.json, $(paper_mass_points))

paper_limits: $(paper_cards_jobs) $(paper_asymp_jobs) 

paper_cards/combined.asymp.pdf: paper_limits
	python $(fsa)/StatTools/scripts/plotlimit.py \
	  --max-y 20 \
	  --lumi 5000 \
	  --method asymp paper_cards/combined_*.asymp.json -o $@ \
	  --showpoints \
	  --blurb "`./blurbtext.py $@`" \
	  --blurbpos "0.15, 0.12, 0.5, 0.20" \
	  --legendpos `./legendpos.py $@`

$(scratch)/paper_cls_limits/combined_%/submit: paper_cards/combined_%.root
	make_grid_submission.py -submitdir `dirname $@` \
	  -i `readlink -f $<`  -mass $* \
	  -min 0.2 -max 30

# Now define the $(channel) grid result - will get updated as more files show up 
# This combines all the points into a "mass slice"
$(scratch)/paper_cls_limits/combined_%/grid.root: $(scratch)/paper_cls_limits/combined_%/point_*root
	hadd -f $@ $^ 

# Given the card file and the computed grid, compute the obs and exp CLs limits
paper_cards/limit_%.cls.json: paper_cards/combined_%.txt $(scratch)/paper_cls_limits/combined_%/grid.root
	compute_cls.sh $^ $* > $@

paper_cls_submitters=$(patsubst %, $(scratch)/paper_cls_limits/combined_%/submit, $(paper_mass_points))

paper_cls_results=$(patsubst %, paper_cards/limit_%.cls.json, $(paper_mass_points))

paper_cls_grids=$(patsubst %, $(scratch)/paper_cls_limits/combined_%/grid.root, $(paper_mass_points))

paper_cls_submits: $(paper_cls_submitters)

paper_cls: $(paper_cls_results) $(paper_cls_grids)

paper_cards/combined.cls.pdf: paper_cls
	python $(fsa)/StatTools/scripts/plotlimit.py \
	  --max-y 20 \
	  --lumi 5000 \
	  --method cls paper_cards/limit_*.cls.json -o $@ \
	  --showpoints \
	  --blurb "`./blurbtext.py $@`" \
	  --blurbpos "0.15, 0.12, 0.5, 0.20" \
	  --legendpos `./legendpos.py $@`


#For debugging run WWW limits only
3l_cards/limit_%.asymp.json: 3l_cards/%/vh3l_cut.txt
	combine $< -M Asymptotic -H ProfileLikelihood \
	  -m `echo $* | sed "s|FF||" | sed "s|SM4||" | sed "s|WW||" | sed "s|tt||"` \
	  | limit2JSON.py --mass $* > $@
	rm higgsCombineTest.Asymptotic.mH`echo $* | sed "s|FF||" | sed "s|SM4||"| sed "s|WW||" | sed "s|tt||"`.root

www_asymp_jobs=$(patsubst %, 3l_cards/limit_%.asymp.json, $(trilepton_mass_points))

3l_cards/limit.asymp.pdf: $(www_asymp_jobs)
	python $(fsa)/StatTools/scripts/plotlimit.py \
	  --max-y 20 \
	  --lumi 5000 \
	  --method asymp $^ -o $@ \
	  --showpoints \
	  --blurb "`./blurbtext.py $@`" \
	  --blurbpos "0.15, 0.12, 0.5, 0.20" \
	  --legendpos `./legendpos.py $@`

www_limits: $(www_asymp_jobs) 3l_cards/limit.asymp.pdf

