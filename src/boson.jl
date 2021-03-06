# @inline ldof(S) = Int(2S+1)
function creator(M::Integer)
    ret = Float64[sqrt(m) for m in M:-1:1]
    return diagm(1=>ret)
end
function creator(M::Integer, L::Integer, i::Integer)
    ld = M+1
    leftN = ld^(i-1)
    rightN = ld^(L-i)
    kron(eye(leftN), kron(creator(M), eye(rightN)))
end

function annihilator(M::Integer)
    ret = Float64[sqrt(m+1) for m in M-1:-1:0]
    return diagm(-1=>ret)
end
function annihilator(M::Integer, L::Integer, i::Integer)
    ld = M+1
    leftN = ld^(i-1)
    rightN = ld^(L-i)
    kron(eye(leftN), kron(annihilator(M), eye(rightN)))
end

function number(M::Integer)
    ret = Float64[m for m in M:-1:0]
    return diagm(0=>ret)
end
function number(M::Integer, L::Integer, i::Integer)
    ld = M+1
    leftN = ld^(i-1)
    rightN = ld^(L-i)
    kron(eye(leftN), kron(number(M), eye(rightN)))
end

function numberdensity(M::Integer,L::Integer,
                       k::Integer=0)
    ld = M+1
    N = ld^L
    n = number(M)
    res = zeros(N)
    invV = 1.0/L
    for i in 1:N
        for (j,m) in enumerate(digits(i-1,base=ld,pad=L))
            res[i] += n[m+1,m+1] * cospi(k*invV*(j-1))
        end
    end
    res .*= 1.0/L
    return diagm(0=>res)
end

function bosonchain(M::Integer, L::Integer,
                    t::Real, V::Real, U::Real,
                    mu::Real,
                    Guni::Real, Gstag::Real)
    ld = M+1
    c = creator(M)
    a = annihilator(M)
    x = c+a
    n = number(M)
    i = eye(ld)

    G  = [-(Guni+Gstag), -(Guni-Gstag)]
    onsite = [-mu.*n .+ U.*n.*(n.-1.0) .+ G[i].*x for i in 1:2]
    bondH = V.*kron(n,n) .- t.*(kron(c,a) .+ kron(a,c))

    N = ld^L
    H = zeros(N,N)
    for i in 1:L
        H .+= kron(eye(ld^(i-1)), kron(onsite[mod1(i,2)], eye(ld^(L-i))))
    end
    H .+= V.*kron(n, kron(eye(div(N,ld*ld)), n))
    H .-= t .* kron(c, kron(eye(div(N,ld*ld)), a))
    H .-= t .* kron(a, kron(eye(div(N,ld*ld)), c))

    leftN = 1
    rightN = ld^(L-2)
    for i in 1:L-1
        H .+= kron(eye(leftN), kron(bondH, eye(rightN)))
        leftN *= ld
        rightN = div(rightN,ld)
    end
    return H
end

doc"""
\mathcal{H} = -t\sum_i(a_i c_{i+1} + c_i a_{i+1}) + V\sum_i n_i n_{i+1} + U \sum_i n_i(n_i-1) - mu \sum_i n_i - G \sum_i (c_i + a_i)
"""
struct BosonChainSolver <: Solver
    ef :: Eigen{Float64, Float64, Matrix{Float64}, Vector{Float64}}
    M :: Int
    L :: Int
    function BosonChainSolver(M::Integer, L::Integer
                              ;
                              t::Real=1.0, V::Real=0.0, U::Real=0.0,
                              mu::Real=0.0, Guni::Real=0.0, Gstag::Real=0.0,
                             )
        new(eigen(bosonchain(M, L, t, V, U, mu, Guni, Gstag)), M, L)
    end
end

creator(solver::BosonChainSolver) = creator(solver.M)
creator(solver::BosonChainSolver, i::Integer) = creator(solver.M, solver.L, i)
annihilator(solver::BosonChainSolver) = annihilator(solver.M)
annihilator(solver::BosonChainSolver, i::Integer) = annihilator(solver.M, solver.L, i)
basis(solver::BosonChainSolver) = number(solver.M)
basis(solver::BosonChainSolver, i::Integer) = number(solver.M, solver.L, i)
orderparameter(solver::BosonChainSolver, k::Integer=0) = numberdensity(solver.M, solver.L, k)

