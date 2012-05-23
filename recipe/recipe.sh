#!/bin/bash

: ${CMSSW_BASE:?"CMSSW_BASE is not set!  Run cmsenv before recipe.sh"}

cd $CMSSW_BASE/src
echo "Checking out extra packages"
addpkg -z -f FinalStateAnalysis/recipe/tags

# PAT RECIPE V08-06-55
addpkg DataFormats/PatCandidates  V06-04-19-04
addpkg PhysicsTools/PatAlgos      V08-06-55
addpkg PhysicsTools/PatUtils      V03-09-18
addpkg CommonTools/ParticleFlow   B4_2_X_V00-03-04
addpkg PhysicsTools/SelectorUtils V00-03-24
addpkg PhysicsTools/UtilAlgos     V08-02-14

echo "Checking out Tau POG recipe"
addpkg DataFormats/TauReco CMSSW_5_2_4 # yes, this is correct
addpkg RecoTauTag/TauTagTools CMSSW_5_2_4
cvs co -r V01-04-17 RecoTauTag/RecoTau
cvs co -r V01-04-01 RecoTauTag/Configuration
cvs co -r V00-04-01 CondFormats/EgammaObjects
cvs up -r 1.53 PhysicsTools/PatAlgos/python/tools/tauTools.py

# Add and patch to way speed up trigger matching
echo "Applying pat trigger matching speedup"
patch -N -p0 < FinalStateAnalysis/recipe/patches/V06-04-16_DataFormats_PatCandidates_PassStrByRef.patch

echo "Adding 2D expression histogram feature"
addpkg -z CommonTools/Utils 
patch -N -p0 < FinalStateAnalysis/recipe/patches/V00-04-02_CommonTools_Utils_Add2DHistoFeature.patch

# Add support for PU Jet ID
# See https://twiki.cern.ch/twiki/bin/view/CMS/PileupJetID
cvs co -r V00-00-09 -d CMGTools/External UserCode/CMG/CMGTools/External

# Add MVA MET
# See https://twiki.cern.ch/twiki/bin/view/CMS/MVAMet
#cvs co -r V00-00-09 -d CMGTools/External UserCode/CMG/CMGTools/External
cvs co -r V00-02 -d  pharris/MVAMet UserCode/pharris/MVAMet
# Evan's patches on the MVA MET (will hopefully be official soon)
tar xvzf /afs/cern.ch/user/f/friis/public/mvaMETRefactor.tgz 
cvs up -r 1.22 PhysicsTools/SelectorUtils/interface/PFJetIDSelectionFunctor.h

# Add Marias patch for negative SSV 
patch -p0 < FinalStateAnalysis/recipe/marias_negativeSSV.patch

# Add Electron ID MVA
cvs co -r V00-00-08 -d EGamma/EGammaAnalysisTools UserCode/EGamma/EGammaAnalysisTools
# Get updated effective areas
cvs up -r 1.3 EGamma/EGammaAnalysisTools/interface/ElectronEffectiveArea.h
pushd EGamma/EGammaAnalysisTools/data
cat download.url | xargs wget
popd

# Get Electron ISO MVA weights
cvs co -r V00-00-00 UserCode/sixie/EGamma/EGammaAnalysisTools/data/

# Add muon MVA
cvs co -r V00-00-10 -d Muon/MuonAnalysisTools UserCode/sixie/Muon/MuonAnalysisTools 

# Get electron energy calibrations
# See https://twiki.cern.ch/twiki/bin/viewauth/CMS/EgammaElectronEnergyScale
# :( no tag is provided on the twiki
cvs co -D "07/05/2012" -d EgammaCalibratedGsfElectrons UserCode/EGamma/EgammaCalibratedGsfElectrons

pushd $CMSSW_BASE/src/FinalStateAnalysis/recipe/
echo "Installing Higgs xsec lookup tables"
./install_HCSaW.sh
popd

# Note you now need to install virtual env
echo "Now run ./install_python.sh to install python"

echo "To compile: scram b -j 4"
