import FWCore.ParameterSet.Config as cms

from FinalStateAnalysis.PatTools.jets.patJetEmbedId_cfi import patJetId

from FinalStateAnalysis.PatTools.jets.patJetPUId_cfi import \
        puJetIdSqeuence, puJetId, puJetMva, patJetsPUID

from FinalStateAnalysis.PatTools.jets.patJetUncorrectedEmbedder_cfi import \
        patJetUncorrectedEmbedder

from FinalStateAnalysis.PatTools.jets.patJetEmbedSystematics_cfi import \
        patJetEmbedSystematics
from FinalStateAnalysis.PatTools.jets.patJetEmbedSmear_cfi import \
        patJetEmbedSmear

from FinalStateAnalysis.PatTools.jets.patMuonInJetEmbedder_cfi import \
        patMuonInJetEmbedder

from FinalStateAnalysis.PatTools.jets.patSSVJetEmbedder_cfi import \
        patSSVJetEmbedder

# Need to attach this to process to get SSV BTag production
simpleSecondaryVertex = cms.ESProducer(
    "SimpleSecondaryVertexESProducer",
    use3d = cms.bool(True),
    unBoost = cms.bool(False),
    useSignificance = cms.bool(True),
    minTracks = cms.uint32(2)
)

customizeJetSequence = cms.Sequence()

customizeJetSequence += patJetId

# Add in the PAT Jet PU ID
customizeJetSequence += puJetIdSqeuence # sic
# Fix the input tags of the PU JET ID value map producers
puJetId.jets = cms.InputTag("patJetId")
puJetMva.jets = cms.InputTag("patJetId")
# Embed the PU IDs
customizeJetSequence += patJetsPUID

# Embed Maria's information about jets
customizeJetSequence += patMuonInJetEmbedder
customizeJetSequence += patSSVJetEmbedder

# Remove low pt garbage jets.  This cut is propagated to the taus - only taus
# that have an existing jet are kept.  This cut is important, so we require
# it is explicitly defined elsewhere.
patJetGarbageRemoval = cms.EDFilter(
    "PATJetSelector",
    src = cms.InputTag("fixme"),
    cut = cms.string("fixme"),
    filter = cms.bool(False),
)
customizeJetSequence += patJetGarbageRemoval

# We have to embed the uncorrected P4 of the jet before we start any monkey
# business with smearing so that we can apply type 1 corrections to MET later
customizeJetSequence += patJetUncorrectedEmbedder
# NB that it is critical that these are applied AFTER the corrections
customizeJetSequence += patJetEmbedSmear
# This has to go second, so the MC smeared value is used as the central value.
customizeJetSequence += patJetEmbedSystematics
