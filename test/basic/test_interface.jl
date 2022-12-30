###############
# file: test_lp_smooth.jl
# project: src
# created Date: Tu Mar yyyy
# author: <<author>
# -----
# last Modified: Mon Apr 18 2022
# modified By: Chuwen Zhang
# -----
# (c) 2022 Chuwen Zhang
# -----
# HISTORY:
# Date      	By	Comments
# ----------	---	---------------------------------------------------------
###############


include("../lp.jl")

using ProximalOperators
using DRSOM
using ProximalAlgorithms
using Random
using Distributions
using Plots
using Printf
using LazyStack
using KrylovKit
using HTTP
using LaTeXStrings
using LinearAlgebra
using Statistics
using LinearOperators
using Optim
using Test
using .LP


params = LP.parse_commandline()
m = n = params.n
D = Normal(0.0, 1.0)
A = rand(D, (n, m)) .* rand(Bernoulli(0.85), (n, m))
v = rand(D, m) .* rand(Bernoulli(0.5), m)
b = A * v + rand(D, (n))
x0 = zeros(m)

Q = A' * A
h = Q' * b
L, _ = LinearOperators.normest(Q, 1e-4)
σ = 0.0
@printf("preprocessing finished\n")


f_composite(x) = 1 / 2 * x' * Q * x - h' * x
g(x) = Q * x - h
H(x) = Q

@testset "DRSOM" begin
    alg = DRSOM2()
    @testset "direct hess" begin
        r = alg(x0=copy(x0), f=f_composite, g=g, H=H, fog=:direct, sog=:hess)
    end
    @testset "direct direct" begin
        r = alg(x0=copy(x0), f=f_composite, g=g, fog=:direct, sog=:direct)
    end

    @testset "forward direct" begin
        r = alg(x0=copy(x0), f=f_composite, fog=:forward, sog=:direct)
    end
    @testset "forward forward" begin
        r = alg(x0=copy(x0), f=f_composite, fog=:forward, sog=:forward)
    end
    @testset "backward direct" begin
        r = alg(x0=copy(x0), f=f_composite, fog=:backward, sog=:direct)
    end
    @testset "backward backward" begin
        r = alg(x0=copy(x0), f=f_composite, fog=:backward, sog=:backward)
    end
end