@testset showtiming = true "Hyperelastics Models" begin
    # AD Backends to test.
    ADs = [AutoForwardDiff(), AutoFiniteDiff(), AutoZygote(), AutoEnzyme()]

    # Determine if the model is exported by hyperelastics.
    usemodel(model) = Base.isexported(Hyperelastics, Symbol(model))

    # collect all incompressible hyperelastic models
    incompressible_models = filter(usemodel, subtypes(Hyperelastics.AbstractIncompressibleModel))

    # Collect all compressible hyperelastics models
    compressible_models = filter(usemodel, subtypes(Hyperelastics.AbstractCompressibleModel))

    # Collect all available incompressible hyperelastic models with invariant forms
    invariant_incompressible_models = filter(Base.Fix2(applicable, InvariantForm()), incompressible_models)

    # Test the incompressible form of the model
    for model in incompressible_models
        # Instantiate model
        ψ = model()
        @test ψ isa Hyperelastics.AbstractIncompressibleModel

        # Create an empty parameter set
        guess = Dict{Symbol,Union{Matrix{Float64},Vector{Float64},Float64}}()

        # Get the parametrs for the model and check return type
        ps = parameters(ψ)
        @test ps isa Tuple

        # Use scalars, vectors, or matrices based on the symbol provided.
        for p in ps
            if ψ isa GeneralMooneyRivlin
                guess[p] = [1.0 1.0; 1.0 1.0]
            elseif contains(string(p), '⃗')
                guess[p] = ones(10)
            else
                guess[p] = 1.0
            end
        end

        # Check for bounds on the model
        lb, ub = parameter_bounds(ψ, Treloar1944Uniaxial())
        @test lb isa NamedTuple || isnothing(lb)
        @test ub isa NamedTuple || isnothing(ub)

        # Move the guess to within the parameter bounds
        if !isnothing(lb) && !isnothing(ub)
            for (k, v) in pairs(lb)
                lb_val = !isinf(getfield(lb, k)) ? (float(getfield(lb, k))) : (1.0)
                ub_val = !isinf(getfield(ub, k)) ? (float(getfield(ub, k))) : (1.0)
                guess[k] = (lb_val + ub_val) / 2.0
            end
        elseif !isnothing(lb)
            for (k, v) in pairs(lb)
                guess[k] = !isinf(getfield(lb, k)) ? (getfield(lb, k)) + 1.0 : (1.0)
            end
        elseif !isnothing(ub)
            for (k, v) in pairs(ub)
                guess[k] = !isinf(getfield(ub, k)) ? (getfield(ub, k)) - 1.0 : (1.0)
            end
        end
        guess = NamedTuple(guess)

        # Example deformation for testing
        λ⃗ = [1.1, inv(sqrt(1.1)), inv(sqrt(1.1))]
        F = diagm(λ⃗)
        λ⃗_c = λ⃗./0.99
        F_c = diagm(λ⃗_c)

        # if ψ isa Shariff
        #     continue
        # end

        for compressible_model in compressible_models
            ψ̄ = compressible_model(ψ)
            @test ψ̄ isa Hyperelastics.AbstractCompressibleModel

            compressible_guess = (κ=1.1, ψ=guess)

            for compressible_deformation in [λ⃗_c, F_c]

                # Principal Value Form Test
                W = StrainEnergyDensity(ψ̄, compressible_deformation, compressible_guess)
                @test !isnan(W)
                @test !isinf(W)

                for AD in ADs
                    # Second Piola Kirchoff Test
                    s = SecondPiolaKirchoffStressTensor(ψ̄, compressible_deformation, compressible_guess; ad_type=AD)
                    @test sum(isnan.(s)) == 0
                    @test sum(isinf.(s)) == 0

                    # Cauchy Stress Test
                    σ = CauchyStressTensor(ψ̄, compressible_deformation, compressible_guess; ad_type=AD)
                    @test sum(isnan.(σ)) == 0
                    @test sum(isinf.(σ)) == 0

                    # Predict Test
                    # @test predict(ψ̄, Treloar1944Uniaxial(), compressible_guess, ad_type = AD) isa Hyperelastics.AbstractHyperelasticTest
                end

                # Invariant Form Test
                if model in invariant_incompressible_models
                    ψ̄_inv = compressible_model(model(InvariantForm()))
                    W = StrainEnergyDensity(ψ̄_inv, [I₁(compressible_deformation), I₂(compressible_deformation), I₃(compressible_deformation)], compressible_guess)
                    @test !isnan(W)
                    @test !isinf(W)
                end
            end
        end


    end
end