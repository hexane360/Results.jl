using Pkg

coverage_env = Pkg.project().path

Pkg.activate(@__DIR__)
Pkg.test("Results"; coverage=true, julia_args=["--inline=no"])

lcov_file = joinpath(@__DIR__, "lcov.info")
lcov_dir = joinpath(@__DIR__, "coverage")

println("Processing coverage...")
Pkg.activate(coverage_env)
using Coverage

coverage = process_folder(joinpath(@__DIR__, "src"))
covered, total = get_summary(coverage)
println("$covered/$total lines covered ($(100*covered/total)%)")

println("Writing to 'lcov.info'")
LCOV.writefile(lcov_file, coverage)

function find_exec(name, opts...)
	try
		run(`$name $opts`)
		name
	catch
		batch_name = name * ".bat"
		try
			run(`$batch_name $opts`)
			batch_name
		catch
			println("'$name' not found, not using it.")
			nothing
		end
	end
end

genhtml = find_exec("genhtml", "-v")
if !isnothing(genhtml)
	title = "Results.jl"
	try
		run(`$genhtml -t $title -o $lcov_dir $lcov_file`)
	catch e
		@warn "'genhtml' failed, error: $e"
	end
end

if haskey(ENV, "CODECOV_TOKEN") && length(ENV["CODECOV_TOKEN"]) > 0
	println("Trying to upload to codecov...")
	Codecov.submit_local(coverage)
end
