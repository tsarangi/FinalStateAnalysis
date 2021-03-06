# Recipes to discover lists of files

# How to generate the inputs
desc "Query lists of ntuple .root files"
task :getinputs, [:jobid, :source] do |t, args|
  sh "discover_ntuples.sh #{args.jobid} #{args.source} inputs/#{args.jobid}"
end
