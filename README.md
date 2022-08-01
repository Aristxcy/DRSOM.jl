# DRSOM: A Dimension-Reduced Second-Order Method for Convex and Nonconvex Optimization

DRSOM.jl is a Julia implementation of the Dimension-Reduced Second-Order Method for unconstrained smooth optimization. The DRSOM works with the following iteration:

$$
\begin{aligned}
        x_{k+1}     = x_k- \alpha_k^1 g_k +\alpha_k^2 d_k, \\
        \alpha_k  = \arg \min m_k^\alpha(\alpha)
\end{aligned}
$$
where the 2-dimensional quadratic model $m_k^\alpha(\alpha)$ is defined as follows:
$$\begin{aligned}
        m_k^\alpha(\alpha) & := f(x_k) + (c _k)^{T} \alpha+\frac{1}{2} \alpha^{T} Q_k \alpha         \\
                           & Q_k=\begin{bmatrix}
                                     ( g_k)^{T} H_k g_k  & -( d_k)^{T} H_k g_k \\
                                     -( d_k)^{T} H_k g_k & ( d_k)^{T} H_k d_k
                                 \end{bmatrix} \in \mathcal S^{2}, c _k=\begin{bmatrix}
                                                                            -\left\| g_k\right\|^{2} \\
                                                                            +( g_k)^{T} d_k
                                                                        \end{bmatrix} \in \real^{2}.
    
\end{aligned}
$$

- $g_k, H_k$ are gradient and Hessian, respectively. However, **DRSOM does not have to compute **$H_k$**; instead, it only requires Hessian-vector products.
- The differentiation is done by `ForwardDiff` and `ReverseDiff` using finite-difference. Alternatively, you may provide 

## Examples
We provide easy examples for DRSOM.jl. All examples are listed in `examples/` directory. To run an example, start at the root directory of DRSOM.jl.

### L2 regression for diabetes dataset

```bash
julia -i --project=./ test/test_l2_diabetes.jl
```

### Sensor network localization

You can change parameters
```bash
julia -i --project=./ test/test_snl.jl
```


If everything works, it should output a `.html` for visualization results (see the [example](example/snl.default.html))

## Acknowledgment
- We are heavily inspired by the wonderful Julia package [ProximalAlgorithms.jl](https://github.com/JuliaFirstOrder/ProximalAlgorithms.jl).  We also appreciate the elegant implementation of [Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl/) that enables effortless comparison and benchmarking.
- Special thanks go to the COPT team and Tianyi Lin [(Darren)](https://tydlin.github.io/) for helpful suggestions.

## Known issues
`DRSOM.jl` is still under active development. Please add issues on GitHub.
## Reference
[1] Chuwen Zhang, Dongdong Ge, Bo Jiang, and Yinyu Ye. DRSOM: A Dimension Reduced Second-Order Method and Preliminary Analyses, working paper. arXiv