
using ProximalOperators
using DRSOM
using ProximalAlgorithms
using Plots
using Printf
using LazyStack
using HTTP
using LaTeXStrings
using LinearAlgebra
using Statistics
using Optim
using ForwardDiff
using ReverseDiff
using LineSearches

function run_drls(x0, f, g, L, σ, tol=1e-6, maxiter=100, freq=10)
    ########################################################
    name = "DRLS"
    method = ProximalAlgorithms.DRLSIteration
    @printf("%s\n", '#'^60)
    @printf("running: %s with tol: %.3e\n", name, tol)
    if L !== nothing
        if σ !== nothing
            iter = method(x0=x0, f=f, g=g, Lf=L, mf=σ)
        else
            iter = method(x0=x0, f=f, g=g, Lf=L)
        end
    else
        iter = method(x0=x0, f=f, g=g)
    end
    arr_obj = []
    rb = nothing
    for (k, state::ProximalAlgorithms.DRLSState) in enumerate(iter)
        norm_res = norm(state.res, Inf)
        obj = f_composite(state.v)
        push!(arr_obj, obj)
        if k >= maxiter || DRSOM.default_stopping_criterion(tol, state)
            DRSOM.default_display(k, obj, state.gamma, norm_res)
            rb = (state, k)
            break
        end
        mod(k, freq) == 0 && DRSOM.default_display(k, obj, state.gamma, norm_res)
    end
    @printf("finished with iter: %.3e, objval: %.3e\n", rb[2], arr_obj[end])
    return name, rb..., arr_obj
end

function run_fista(x0, f, g, L=nothing, σ=nothing, tol=1e-6, maxiter=200, freq=40)
    ########################################################
    name = "FISTA"
    method = ProximalAlgorithms.FastForwardBackwardIteration
    @printf("%s\n", '#'^60)
    @printf("running: %s with tol: %.3e\n", name, tol)
    if L !== nothing
        if σ !== nothing
            iter = method(x0=x0, f=f, g=g, Lf=L, mf=σ)
        else
            iter = method(x0=x0, f=f, g=g, Lf=L)
        end
    else
        iter = method(x0=x0, f=f, g=g)
    end
    arr_obj = []
    rb = nothing
    for (k, state::ProximalAlgorithms.FastForwardBackwardState) in enumerate(iter)
        norm_res = norm(state.res, Inf)
        obj = f_composite(state.x)
        push!(arr_obj, obj)
        if k >= maxiter || DRSOM.default_stopping_criterion(tol, state)
            DRSOM.default_display(k, obj, state.gamma, norm_res)
            rb = (state, k)
            break
        end
        mod(k, freq) == 0 && DRSOM.default_display(k, obj, state.gamma, norm_res)
    end
    @printf("finished with iter: %.3e, objval: %.3e\n", rb[2], arr_obj[end])
    return name, rb..., arr_obj
end


########################################################
# the DRSOM runner
########################################################
# provide 4 types of run:
# - run_drsomf: (forward), run DRSOM with forward automatic differentiation
# - run_drsomb: (backward), run DRSOM with backward automatic differentiation (recommended)
# - run_drsomd: (direct mode), run DRSOM with provided g(⋅) and H(⋅)
# - run_drsomd_traj: (direct mode) run add save trajactory

function run_drsomf(x0, f_composite; tol=1e-6, maxiter=100, freq=1)
    ########################################################
    name = "DRSOM"
    arr_obj = []
    rb = nothing
    @printf("%s\n", '#'^60)
    @printf("running: %s with tol: %.3e\n", name, tol)
    cfg = ForwardDiff.GradientConfig(f_composite, x0, ForwardDiff.Chunk(x0))
    iter = DRSOM.DRSOMFreeIteration(x0=x0, rh=DRSOM.hessfa, f=f_composite, cfg=cfg, mode=:forward)
    for (k, state::DRSOM.DRSOMFreeState) in enumerate(iter)
        push!(arr_obj, state.fx)
        if k >= maxiter || DRSOM.drsom_stopping_criterion(tol, state)
            rb = (state, k)
            DRSOM.drsom_display(k, state)
            break
        end
        mod(k, freq) == 0 && DRSOM.drsom_display(k, state)
    end
    @printf("finished with iter: %.3e, objval: %.3e\n", rb[2], arr_obj[end])
    return name, rb..., arr_obj
end

function run_drsomb(x0, f_composite; tol=1e-6, maxiter=100, freq=1)
    ########################################################
    name = "DRSOM"
    arr_obj = []
    rb = nothing
    @printf("%s\n", '#'^60)
    @printf("running: %s with tol: %.3e\n", name, tol)
    f_tape = ReverseDiff.GradientTape(f_composite, x0)
    f_tape_compiled = ReverseDiff.compile(f_tape)
    @printf("compile finished\n")
    @printf("%s\n", '#'^60)
    iter = DRSOM.DRSOMFreeIteration(x0=x0, rh=DRSOM.hessba, f=f_composite, tp=f_tape_compiled, mode=:backward)
    for (k, state::DRSOM.DRSOMFreeState) in enumerate(iter)
        push!(arr_obj, state.fx)
        if k >= maxiter || DRSOM.drsom_stopping_criterion(tol, state)
            rb = (state, k)
            DRSOM.drsom_display(k, state)
            break
        end
        mod(k, freq) == 0 && DRSOM.drsom_display(k, state)
    end
    @printf("finished with iter: %.3e, objval: %.3e\n", rb[2], arr_obj[end])
    return name, rb..., arr_obj
end

function run_drsomd(x0, f_composite, g, H; tol=1e-6, maxiter=100, freq=1)
    ########################################################
    name = "DRSOM"
    arr_obj = []
    rb = nothing
    @printf("%s\n", '#'^60)
    @printf("running: %s with tol: %.3e\n", name, tol)
    iter = DRSOM.DRSOMFreeIteration(x0=x0, f=f_composite, g=g, H=H, mode=:direct)
    for (k, state::DRSOM.DRSOMFreeState) in enumerate(iter)
        push!(arr_obj, state.fx)
        if k >= maxiter || DRSOM.drsom_stopping_criterion(tol, state)
            rb = (state, k)
            DRSOM.drsom_display(k, state)
            break
        end
        mod(k, freq) == 0 && DRSOM.drsom_display(k, state)
    end
    @printf("finished with iter: %.3e, objval: %.3e\n", rb[2], arr_obj[end])
    return name, rb..., arr_obj
end

function run_drsomd_traj(x0, f_composite, g, H; tol=1e-6, maxiter=100, freq=1)
    ########################################################
    name = "DRSOM"
    arr_obj = []
    traj = []
    rb = nothing
    @printf("%s\n", '#'^60)
    @printf("running: %s with tol: %.3e\n", name, tol)
    iter = DRSOM.DRSOMFreeIteration(x0=x0, f=f_composite, g=g, H=H, mode=:direct)
    for (k, state::DRSOM.DRSOMFreeState) in enumerate(iter)
        push!(traj, state)
        if k >= maxiter || DRSOM.drsom_stopping_criterion(tol, state)
            rb = (state, k)
            DRSOM.drsom_display(k, state)
            break
        end
        mod(k, freq) == 0 && DRSOM.drsom_display(k, state)
    end
    @printf("finished with iter: %.3e, objval: %.3e\n", rb[2], rb[1].fx)
    return name, rb..., traj
end


# general options for Optim
# GD and LBFGS, Trust Region Newton,
options = Optim.Options(
    g_tol=1e-6,
    iterations=10000,
    store_trace=true,
    show_trace=true,
    show_every=50,
)