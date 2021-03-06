Workflow
========

The analysis proceeds in three steps.  First, a pat tuple containing the final
states is produced from AOD content.  The PAT tuple can then be analyzed
(selections + plots) directly, using the PATFinalStateAnalysis tool.  The
analysis typically runs at about 500+ events/second.  As an optional third step,
the PATFinalStateAnalysis can produce a bare ROOT ntuple at any stage of the
processing.  One can then apply additional selections.


PAT Tuple production
--------------------
 
The pat tuple production runs on sod events and runs at about two events per
second.  The PAT tuplization does the following:

* Compute and embed all object IDs
* Apply corrections and embed systematics
* Produce event weights
* Compose all possible final states of interest.  Example: DoubleMu + Tau
 
The tuplization only needs to be done occasionally.  The PAT tuple is configured
in four places.

* PatTools/python/datadefs.py provides a global defintion of all MC and data
     samples.

* PatTools/python/patTupleProduction.py defines the PAT production sequence,
  the corrections applied to different objects, and the PATFinalState
  production.

* PatTools/test/patTuple_cfg.py is the top-level cfg which builds the tuple.

* PatTools/test/submit_tuplization.py submits the jobs to condor.

