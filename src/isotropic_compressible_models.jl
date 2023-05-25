export GeneralCompressible, LogarithmicCompressible
"""
Generic Compressible Model

Model:
```math
\\psi_{compressible} = \\psi_{incompressible}(\\vec{\\lambda}_{incompressible})+\\kappa(J-1)^2
```

Parameters:
- ψ
    - Incompressible model parameters (see model selected for parameter names)
- κ

"""
struct GeneralCompressible <: AbstractHyperelasticModel
    incompressible::AbstractHyperelasticModel
end

function NonlinearContinua.StrainEnergyDensity(ψ::GeneralCompressible, λ⃗::AbstractVector, p; kwargs...)
    J = prod(λ⃗)
    StrainEnergyDensity(ψ.incompressible, λ⃗ ./ cbrt(J), p.ψ, kwargs...) + p.κ / 2 * (J - 1)^2
end

function NonlinearContinua.StrainEnergyDensity(ψ::GeneralCompressible, F::AbstractMatrix, p; kwargs...)
    J = det(F)
    F̄ = F ./ cbrt(J)
    StrainEnergyDensity(ψ.incompressible, F̄::AbstractMatrix, p.ψ, kwargs...) + p.κ / 2 * (J - 1)^2
end

function NonlinearContinua.StrainEnergyDensity(ψ::GeneralCompressible, F::AbstractMatrix, p, ::InvariantForm; kwargs...)
    J = det(F)
    F̄ = F ./ cbrt(J)
    StrainEnergyDensity(ψ.incompressible, [I₁(F̄), I₂(F̄), I₃(F̄)], p.ψ, InvariantForm(), kwargs...) + p.κ / 2 * (J - 1)^2
end

function NonlinearContinua.CauchyStressTensor(ψ::GeneralCompressible, λ⃗::AbstractVector, p; kwargs...)
    σ_dev = p.κ * (prod(λ⃗) - 1)
    σ = CauchyStressTensor(ψ.incompressible, λ⃗ ./ cbrt(prod(λ⃗)), p.ψ, kwargs...)
    return σ .+ σ_dev
end

function NonlinearContinua.CauchyStressTensor(ψ::GeneralCompressible, F::AbstractMatrix, p; kwargs...)
    σ_dev = p.κ * (J(F) - 1)
    σ = CauchyStressTensor(ψ.incompressible, F ./ cbrt(J(F)), p.ψ, kwargs...)
    return σ .+ σ_dev
end

function NonlinearContinua.CauchyStressTensor(ψ::GeneralCompressible, F::AbstractMatrix, p, I::InvariantForm; kwargs...)
    σ_dev = p.κ * (J(F) - 1)
    F̄ = F ./ cbrt(J(F))
    σ = CauchyStressTensor(ψ.incompressible, [I₁(F̄), I₂(F̄), I₃(F̄)], p.ψ, I, kwargs...)
    return σ .+ σ_dev
end

function NonlinearContinua.SecondPiolaKirchoffStressTensor(ψ::GeneralCompressible, λ⃗::AbstractVector, p; kwargs...)
    s_dev = p.κ * (J(F) - 1) ./ λ⃗
    s = SecondPiolaKirchoffStressTensor(ψ.incompressible, λ⃗ ./ cbrt(J(λ⃗)), p.ψ, kwargs...)
    return s .+ s_dev
end

function NonlinearContinua.SecondPiolaKirchoffStressTensor(ψ::GeneralCompressible, F::AbstractMatrix, p; kwargs...)
    s_dev = p.κ * (J(F) - 1) .* inv(F)
    s = SecondPiolaKirchoffStressTensor(ψ.incompressible, F ./ cbrt(J(F)), p.ψ, kwargs...)
    return s .+ s_dev
end

function NonlinearContinua.SecondPiolaKirchoffStressTensor(ψ::GeneralCompressible, F::AbstractMatrix, p, ::InvariantForm; kwargs...)
    s_dev = p.κ * (J(F) - 1) .* inv(F)
    F̄ = F ./ cb
    s = SecondPiolaKirchoffStressTensor(ψ.incompressible,[I₁(F̄), I₂(F̄), I₃(F̄)], p.ψ, InvariantForm(), kwargs...)
    return s .+ s_dev
end

function Base.show(io::IO, ψ::GeneralCompressible)
    println(io, "Incompressible Model: W=", ψ.incompressible)
    println(io, "Compressible Model: W=", "kappa*(J-1)")
end

"""
Logarithmic Compressible Model

Model:
```math
\\psi_{compressible} = \\psi_{incompressible}(\\vec{\\lambda}_{incompressible})+\\kappa(J\\log{J} - J)
```

Parameters:
- ψ
    - See Selected hyperelastic model for the required parameters.
- κ

"""
struct LogarithmicCompressible <: AbstractHyperelasticModel
    incompressible::AbstractHyperelasticModel
end

function NonlinearContinua.StrainEnergyDensity(ψ::LogarithmicCompressible, λ⃗::AbstractVector, p)
    StrainEnergyDensity(ψ.incompressible, λ⃗./cbrt(J(λ⃗)), p.ψ) + p.κ * (J(λ⃗) * log(J(λ⃗)) - J(λ⃗))
end

function NonlinearContinua.CauchyStressTensor(ψ::LogarithmicCompressible, λ⃗::AbstractVector, p; kwargs...)
    σ_dev = p.κ * (log(J(λ⃗)))
    σ = CauchyStressTensor(ψ.incompressible, λ⃗ ./ cbrt(prod(λ⃗)), p.ψ, kwargs...)
    return σ .+ σ_dev
end

function NonlinearContinua.CauchyStressTensor(ψ::LogarithmicCompressible, F::AbstractMatrix, p; kwargs...)
    σ_dev = p.κ * (log(J(F)))
    σ = CauchyStressTensor(ψ.incompressible, F ./ cbrt(J(F)), p.ψ, kwargs...)
    return σ .+ σ_dev
end

function NonlinearContinua.CauchyStressTensor(ψ::LogarithmicCompressible, F::AbstractMatrix, p, ::InvariantForm; kwargs...)
    σ_dev = p.κ * (log(J(F)))
    F̄ = F ./ cbrt(J(F))
    σ = CauchyStressTensor(ψ.incompressible, [I₁(F̄), I₂(F̄), I₃(F̄)], p.ψ, InvariantForm(), kwargs...)
    return σ .+ σ_dev
end

function NonlinearContinua.SecondPiolaKirchoffStressTensor(ψ::LogarithmicCompressible, λ⃗::AbstractVector, p; kwargs...)
    s_dev = p.κ * (log(J(λ))) ./ λ
    s = SecondPiolaKirchoffStressTensor(ψ.incompressible, λ⃗ ./ cbrt(J(λ⃗)), p.ψ, kwargs...)
    return s .+ s_dev
end

function NonlinearContinua.SecondPiolaKirchoffStressTensor(ψ::LogarithmicCompressible, F::AbstractMatrix, p; kwargs...)
    s_dev = p.κ * (log(J(λ))) ./ λinv(F)
    s = SecondPiolaKirchoffStressTensor(ψ.incompressible, F ./ cbrt(J(F)), p.ψ, kwargs...)
    return s .+ s_dev
end

function NonlinearContinua.SecondPiolaKirchoffStressTensor(ψ::LogarithmicCompressible, F::AbstractMatrix, p, ::InvariantForm; kwargs...)
    s_dev = p.κ * (log(J(λ))) ./ λinv(F)
    F̄ = F ./ cb
    s = SecondPiolaKirchoffStressTensor(ψ.incompressible, [I₁(F̄), I₂(F̄), I₃(F̄)], p.ψ, InvariantForm(), kwargs...)
    return s .+ s_dev
end

function Base.show(io::IO, ψ::LogarithmicCompressible)
    println(io, "Incompressible Model: \n \t W = ", ψ.incompressible)
    println(io, "Compressible Model: \n\t W = ", "kappa*(J*log(J)-J)")
end
