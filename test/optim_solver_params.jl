import Pkg
Pkg.activate("/home/cdsw/MacroModelling.jl-ss_solver2/MacroModelling.jl-ss_solver/")
Pkg.add(["Turing", "Optimization", "OptimizationNLopt", "OptimizationMetaheuristics", "BlackBoxOptim", "Optim", "OptimizationMultistartOptimization"])

using MacroModelling, Optimization, OptimizationNLopt, OptimizationMetaheuristics, OptimizationMultistartOptimization, Optim
import BlackBoxOptim#, OptimizationEvolutionary

max_time = 8 * 60^2
transformation = 1
algo = "BBO_DE"

# max_time = Meta.parse(ENV["maxtime"]) # "4" # 
# transformation = Meta.parse(ENV["transformation"]) # "4" # 
# algo = ENV["algorithm"] # "ESCH" # 


# logic to implement

# when finding the NSSS the first time: use the system with aux variables as unknowns, parameters and solved vars as unknowns, separate the system into smaller blocks if possible
# do redundant var reduction only if the vars to reduce are not part of nonlinear expressions
# search for optim parameters that solve any of the models with a side condition of having the least necessary iterations
# for estimation use the small system (no aux, pars and solved vars) and again look for optim parameters that solve the system with the least necessary iterations during estimation


include("../test/models/RBC_CME_calibration_equations_and_parameter_definitions_lead_lags_numsolve.jl")
# include("../test/models/RBC_CME_calibration_equations_and_parameter_definitions.jl")
include("../models/Backus_Kehoe_Kydland_1992.jl")
include("../models/Baxter_King_1993.jl")
include("../models/SW03.jl")
include("../models/GNSS_2010.jl")
include("../models/Ghironi_Melitz_2005.jl")
include("../models/SGU_2003_debt_premium.jl")
include("../models/NAWM_EAUS_2008.jl") # stands out
include("../models/JQ_2012_RBC.jl")
include("../models/Ireland_2004.jl")
include("../models/Caldara_et_al_2012.jl")
include("../models/Gali_Monacelli_2005_CITR.jl")
include("../models/Gali_2015_chapter_3_nonlinear.jl")
include("../models/Aguiar_Gopinath_2007.jl")
include("../models/Ascari_Sbordone_2014.jl") # stands out
include("../models/FS2000.jl")
include("../models/SW07.jl")
include("../models/SW07_nonlinear.jl")
# include("../models/RBC_baseline.jl") # no solver block / everything analytical
include("../models/Guerrieri_Iacoviello_2017.jl") # stands out


all_models = [
    # SW07_nonlinear,
    Guerrieri_Iacoviello_2017,
    # NAWM_EAUS_2008, 
    # GNSS_2010, 
    # Ascari_Sbordone_2014, 
    SW03, 
    # Backus_Kehoe_Kydland_1992, 
    # m, 
    # Baxter_King_1993, 
    # Ghironi_Melitz_2005, 
    # SGU_2003_debt_premium, 
    # JQ_2012_RBC, 
    # Ireland_2004, 
    # Caldara_et_al_2012, 
    # Gali_Monacelli_2005_CITR, 
    # Gali_2015_chapter_3_nonlinear, 
    # Aguiar_Gopinath_2007, 
    FS2000, 
    # SW07
];

function calc_total_iters(model, par_inputs, starting_point)
    outmodel = try model.SS_solve_func(model.parameter_values, model, false, starting_point, par_inputs) catch end

    iters = outmodel isa Tuple{Vector{Float64}, Tuple{Float64, Int64}} ? 
        (outmodel[2][1] > 1e-12) || !isfinite(outmodel[2][1]) ? 
            10000 : 
        outmodel[2][2] : 
        10000

    if model.model_name == "SWnonlinear"
        iters = outmodel[1][indexin([:y], model.var)][1] > .01 ? iters : 100000
    end

    return iters
end


maxiters = 250

using Turing
# Function to calculate the posterior log likelihood
function evaluate_pars_loglikelihood(pars, models)
    log_lik = 0.0
    
    model_iters = zeros(Int, length(models))
    
    pars[1:2] = sort(pars[1:2], rev = true)

    # Apply prior distributions
    log_lik -= logpdf(filldist(MacroModelling.Gamma(1.0, 1.0, μσ = true), 19),pars[1:19])
    log_lik -= logpdf(MacroModelling.Normal(0.0, 5.0), pars[20])

    # Example solver parameters - this needs to be replaced with actual logic
    par_inputs = MacroModelling.solver_parameters(eps(), eps(), maxiters, pars[1:19]..., transformation, 0.0, 2)

    # Iterate over all models and calculate the total iterations
    for (i,model) in enumerate(models)
        total_iters = calc_total_iters(model, par_inputs, pars[20])
#        model_iters[i] = 1e1 * total_iters
        model_iters[i] = total_iters
    end
    
    return Float64(log_lik / 1e1 + sum(model_iters))
end

# best which solves all
# parameters = [15.223285246843304, 0.95517, 38.52678, 43.54497, 0.0008500000000000058, 0.62934, 75.54509549110291, 7.261945059036699, 85.51936289088874, 87.41658873754673, 55.07229950750884, 4.11876, 39.10866, 19.048629999998944, 10.314559999999997, 28.678813991497712, 36.343002891808354, 20.09102186880269, 8.49258045180932, 2.4593900000000004]
  
# parameters = [33.22212, 0.95517, 38.52678, 43.54497, 0.00085, 0.62934, 46.08991, 7.42148, 88.03616, 95.55800, 85.29771, 4.11876, 39.10866, 19.04863, 10.31456, 40.92975, 36.34300, 69.75309, 30.12526, 2.45939]
# parameters = [37.43453157340342, 0.955165023642146, 38.52677779968875, 95.04867034722088, 0.000853689773926441, 0.6293394580085896, 93.73768759873417, 2.1182394698715467e-11, 12.95559055961808, 99.99999999999662, 24.3348635729501, 4.118758409516733, 39.10864859959332, 99.99999999999999, 10.31461007643029, 40.85122820001249, 15.98399822778196, 6.030696898083779e-8, 95.4840354280116, 2.4593914105545123]
# parameters = [37.848315380908126, 0.9526763793111475, 38.57687571822749, 95.06299787106212, 0.0008502803638540511, 0.6325649634774726, 93.75, 2.136387910452622e-11, 12.938130858544689, 99.99999999999662, 24.31858091208389, 4.11777400869617, 39.204774174235276, 100.0, 10.324167321843138, 40.72731100951839, 15.9844287184187, 6.03635340082695e-8, 81.9907380880773, 2.3287839364442786]
# parameters = [37.848315380909575, 0.9526763793111475, 38.57687571822749, 95.06299787106212, 0.0008502803638540511, 0.6325649634774871, 93.75, 2.2813386285476825e-11, 12.938130858546138, 99.99999999999807, 24.318580912085338, 4.11777400869617, 39.204774174235276, 100.0, 10.324167321843138, 40.7273110095184, 15.98442871842015, 6.036498351545045e-8, 81.9907380880773, 2.3287839364442786]
# parameters = [38.237414502003325, 0.9527636074246202, 38.57687571822749, 95.06299787106212, 0.0008502803638540511, 0.6325649634774871, 100.0, 2.8077962648754957e-11, 12.938130858546138, 99.99999999999807, 24.318580912085338, 4.11777400869617, 39.204774174235276, 100.0, 10.324167321843138, 40.7273110095184, 15.98442871842015, 6.036498351545045e-8, 81.9907380880773, 2.3287839364442786]
# parameters = [40.653449421030615, 0.9579543617960843, 9.97332192578991, 81.98802086152607, 0.008909032074826044, 0.5645562343804136, 89.01800964358117, 60.85834318907328, 53.862153957134666, 79.94101658022927, 66.47498026777562, 13.524117918347589, 4.664804437126141, 79.64865112828011, 31.157157536515367, 26.612793916106224, 77.91244651627218, 1.8858853864455494, 63.60002535111804, 2.41565115787875]
# parameters = [0.12093703888495441, 2.220446049250313e-16, 61.878895561555915, 65.84447938424393, 2.220446049250313e-16, 2.220446049250313e-16, 6.933804874728828, 0.03550533269177629, 2.320205642186332, 2.220446049250313e-16, 0.11105635242360294, 26.04149988887009, 2.2262295630876796, 15.050993533154083, 0.46563877913151125, 0.0011852170148789498, 7.918691209270494, 0.058009549651149024, 0.38452735521908066, 2.4680472122656134]
# parameters = [2.9699835653158626, 2.220446049250313e-16, 2.220446049250313e-16, 100.0, 2.220446049250313e-16, 2.220446049250313e-16, 15.70610701003443, 0.7621920764720541, 81.36639856950987, 2.220446049250313e-16, 100.0, 98.89303867353514, 22.02471417808018, 84.44731715339454, 2.220446049250313e-16, 2.220446049250313e-16, 100.0, 37.624811147776846, 13.281021688292757, 4.318100177071883]
# parameters = [2.0613343866845275, 0.8640348498807412, 98.12952506814149, 8.391075855914728, 2.220446049250313e-16, 0.00039247645151413365, 0.39152149242423145, 3.271716018599044, 2.220446049250313e-16, 0.5396861590700143, 0.024481377276542992, 38.2048416891502, 78.47102658051715, 61.533985856719, 0.016794191100658155, 2.220446049250313e-16, 0.8770574214422433, 0.0026513744112316136, 0.785831661396662, 2.769459604291346]

# original
# parameters = [2.9912988764832833, 0.8725, 0.0027, 0.028948770826150612, 8.04, 4.076413176215408, 0.06375413238034794, 0.24284340766769424, 0.5634017580097571, 0.009549630552246828, 0.6342888355132347, 0.5275522227754195, 1.0, 0.06178989216048817, 0.5234277812131813, 0.422, 0.011209254402846185, 0.5047, 0.6020757011698457, 0.7688]

parameters = rand(20) .+ 1
parameters[20] -= 1

evaluate_pars_loglikelihood(parameters, all_models)

lbs = fill(eps(),length(parameters))
lbs[20] = -20

ubs = fill(100.0,length(parameters))

prob = OptimizationProblem(evaluate_pars_loglikelihood, parameters, all_models, lb = lbs, ub = ubs)

# maxtime = 23 * 60^2

opt = Options(verbose = true, parallel_evaluation = false)
# sol = solve(prob, NLopt.LN_BOBYQA()); sol.minimum
# sol = solve(prob, NLopt.LN_NELDERMEAD()); sol.minimum
# sol = solve(prob, NLopt.LN_SBPLX()); sol.minimum
# sol = solve(prob, NLopt.LN_PRAXIS()); sol.minimum
# solve(prob, NLopt.G_MLSL_LDS(), local_method =  NLopt.LN_BOBYQA(), maxtime = maxt); sol.minimum

if algo == "ESCH"
    sol = solve(prob, NLopt.GN_ESCH(), maxtime = max_time); sol.minimum
    pars = deepcopy(sol.u)
elseif algo == "SAMIN"   
    sol = Optim.optimize(x -> evaluate_pars_loglikelihood(x, all_models), lbs, ubs, parameters, 
                        SAMIN(  nt = 10, 
                                ns = 10, 
                                rt = 0.95, 
                                verbosity = 2), 
                        Optim.Options(time_limit = max_time, 
#                                        show_trace = true, 
                                        iterations = 10000000,
#                                        extended_trace = true, 
#                                        show_every = 10000
    ))
    pars = Optim.minimizer(sol)
elseif algo == "PS"   
    sol = Optim.optimize(x -> evaluate_pars_loglikelihood(x, all_models), lbs, ubs, parameters, 
                        ParticleSwarm(lower = lbs, 
                                        upper = ubs, 
                                        n_particles = 500), 
                        Optim.Options(time_limit = max_time, 
                                        show_trace = true, 
                                        iterations = 1000000,
                                        extended_trace = true, 
                                        show_every = 100
    ))
    pars = Optim.minimizer(sol)
elseif algo == "MLSL"   
    sol = solve(prob, NLopt.G_MLSL_LDS(), local_method =  NLopt.LN_BOBYQA(), maxtime = max_time); sol.minimum
    pars = deepcopy(sol.u)
elseif algo == "TikTak"   
    sol = solve(prob, MultistartOptimization.TikTak(5000), NLopt.LN_NELDERMEAD(), maxtime = max_time); sol.minimum
    pars = deepcopy(sol.u)
elseif algo == "BBO_SS"   
    sol = BlackBoxOptim.bboptimize(x -> evaluate_pars_loglikelihood(x, all_models), parameters, 
            SearchRange = [(lb, ub) for (ub, lb) in zip(ubs, lbs)], 
            NumDimensions = length(parameters),
            MaxTime = max_time, 
#            PopulationSize = 500, 
            TraceMode = :verbose, 
            TraceInterval = 60, 
            Method = :generating_set_search)#
#            Method = :adaptive_de_rand_1_bin_radiuslimited)
            
    pars = BlackBoxOptim.best_candidate(sol)  
elseif algo == "BBO_DXNES"   
    sol = BlackBoxOptim.bboptimize(x -> evaluate_pars_loglikelihood(x, all_models), parameters, 
            SearchRange = [(lb, ub) for (ub, lb) in zip(ubs, lbs)], 
            NumDimensions = length(parameters),
            MaxTime = max_time, 
#            PopulationSize = 500, 
            TraceMode = :verbose, 
            TraceInterval = 60, 
            Method = :dxnes)#
#            Method = :adaptive_de_rand_1_bin_radiuslimited)
            
    pars = BlackBoxOptim.best_candidate(sol)  
elseif algo == "BBO_DE"   
    sol = BlackBoxOptim.bboptimize(x -> evaluate_pars_loglikelihood(x, all_models), parameters, 
            SearchRange = [(lb, ub) for (ub, lb) in zip(ubs, lbs)], 
            NumDimensions = length(parameters),
            MaxTime = max_time, 
            PopulationSize = 500, 
            TraceMode = :verbose, 
            TraceInterval = 60, 
#            Method = :generating_set_search)#
            Method = :adaptive_de_rand_1_bin_radiuslimited)
            
    pars = BlackBoxOptim.best_candidate(sol)   
elseif algo == "DE"
    sol = solve(prob, DE(options = opt), maxtime = max_time); sol.minimum
    pars = deepcopy(sol.u)
elseif algo == "SA" # terminates early with not great results
    sol = solve(prob, SA(options = opt), maxtime = max_time); sol.minimum
    pars = deepcopy(sol.u)
elseif algo == "ECA"
    sol = solve(prob, ECA(options = opt), maxtime = max_time); sol.minimum 
    pars = deepcopy(sol.u)
elseif algo == "MCCGA" # terminates early with not great results
    sol = solve(prob, MCCGA(options = opt), maxtime = max_time); sol.minimum
    pars = deepcopy(sol.u)
elseif algo == "BRKGA" # terminates early with not great results
    sol = solve(prob, BRKGA(options = opt), maxtime = max_time); sol.minimum
    pars = deepcopy(sol.u)
elseif algo == "PSO"
    sol = solve(prob, PSO(options = opt), maxtime = max_time); sol.minimum
    pars = deepcopy(sol.u)
elseif algo == "WOA"
    sol = solve(prob, WOA(N = 500, options = opt), maxtime = max_time); sol.minimum 
    pars = deepcopy(sol.u)
elseif algo == "ABC"
    sol = solve(prob, ABC(N = 500, options = opt), maxtime = max_time); sol.minimum
    pars = deepcopy(sol.u)
elseif algo == "NOMAD" # terminates early with not great results
    sol = solve(prob, NOMADOpt(), maxtime = max_time); sol.minimum
    pars = deepcopy(sol.u)
elseif algo == "GA"
    sol = solve(prob, Evolutionary.GA(), maxtime = max_time); sol.minimum
    pars = deepcopy(sol.u)
end



# do another local optim refinement
prob = OptimizationProblem(evaluate_pars_loglikelihood, pars, all_models, lb = lbs, ub = ubs)
sol = solve(prob, NLopt.LN_NELDERMEAD()); sol.minimum
sol = solve(prob, NLopt.LN_BOBYQA()); sol.minimum
sol = solve(prob, NLopt.LN_PRAXIS()); sol.minimum
sol = solve(prob, NLopt.LN_SBPLX()); sol.minimum #80.79
# sol = solve(prob, NLopt.LN_COBYLA()); sol.minimum
pars = deepcopy(sol.u)


# SW07 nonlinear
# [0.5892723157762478, 0.5887527065005829, 0.0006988523559835617, 0.009036867721330505, 0.14457591298892497, 1.3282546133453548, 1.378515451210324, 1.7661485851863441e-6, 2.6206711939142943e-7, 7.052160321659248e-12, 1.8442212583051863e-6, 5.118937128189348, 13.301617690046848, 6.044293140571821e-13, 1.691251847378593, 0.03319322730594751, 0.1201767636895742, 0.0007802908980930664, 0.011310267585075185, 1.0032972640942657]
# Iterations per model: [37, 10000, 10000, 35, 38, 10000, 18, 10000, 9, 21, 10, 22, 5, 27, 6, 12, 15, 10000, 21]

# refinement across models which solved (see above)
# [1.0242323883590136, 0.5892723157762478, 0.0006988523559835617, 0.009036867721330505, 0.14457591298892497, 1.3282546133453548, 0.7955753778741823, 1.7661485851863441e-6, 2.6206711939142943e-7, 7.052160321659248e-12, 1.06497513443326e-6, 5.118937128189348, 90.94952163302091, 3.1268025435012207e-13, 1.691251847378593, 0.5455751102495228, 0.1201767636895742, 0.0007802908980930664, 0.011310267585075185, 1.0032972640942657]
# [44, 10000, 83, 36, 40, 10000, 13, 22, 9, 18, 9, 11, 5, 24, 5, 11, 15, 10000, 20]


# Guerrieri_Iacoviello_2017, SW03, FS2000
# [2.2166000934038386, 0.3342989316385292, 1.322105676270657, 2.4423579385973486, 5.28291512449182, 0.2436333363251138, 2.0392909437375537, 2.220446049250313e-16, 0.1179149349062645, 1.7950574466127827, 5.645113651574673e-14, 29.199406403144636, 21.508413489197178, 7.358430465764362, 1.139797041569637, 3.5086499739182466, 2.4965112615295393, 2.268534694762562, 12.120815210691354, 0.884940029673057]
# [10000, 16, 10000, 10000, 10000, 45, 22, 10000, 21, 35, 26, 10000, 7, 10000, 7, 16, 12, 10, 200]

println("Transform: $transformation")
println("Parameters: $pars")

model_iters = zeros(Int, length(all_models))
    
pars[1:2] = sort(pars[1:2], rev = true)

# Example solver parameters - this needs to be replaced with actual logic
par_inputs = MacroModelling.solver_parameters(eps(), eps(), maxiters, pars[1:19]..., transformation, 0.0, 2)

# Iterate over all models and calculate the total iterations
for (i,model) in enumerate(all_models)
    total_iters = calc_total_iters(model, par_inputs, pars[20])
    model_iters[i] = total_iters
end

println("Iterations per model: $model_iters")
println("Total iterations across model: $(sum(model_iters))")

# SWnonlinear.SS_solve_func(SWnonlinear.parameter_values, SWnonlinear, false, pars[20], par_inputs)
# Guerrieri_Iacoviello_2017.SS_solve_func(Guerrieri_Iacoviello_2017.parameter_values, Guerrieri_Iacoviello_2017, false, pars[20], par_inputs)

# SS(Guerrieri_Iacoviello_2017)

# SWnonlinear.bounds