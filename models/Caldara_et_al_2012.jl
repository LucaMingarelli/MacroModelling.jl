@model Caldara_et_al_2012 begin
	V[0] = ((1 - β) * (c[0] ^ ν * (1 - l[0]) ^ (1 - ν)) ^ ((1 - γ) / ((1 - γ) / (1 - 1 / ψ))) + β * exp(s[0]) ^ (1 / ((1 - γ) / (1 - 1 / ψ)))) ^ ((1 - γ) / (1 - 1 / ψ) / (1 - γ))

	exp(s[0]) = V[1] ^ (1 - γ)

	1 = (1 + ζ * exp(z[1]) * k[0] ^ (ζ - 1) * l[1] ^ (1 - ζ) - δ) * c[0] * β * (((1 - l[1]) / (1 - l[0])) ^ (1 - ν) * (c[1] / c[0]) ^ ν) ^ ((1 - γ) / ((1 - γ) / (1 - 1 / ψ))) / c[1] * (V[1] ^ (1 - γ) / exp(s[0])) ^ (1 - 1 / ((1 - γ) / (1 - 1 / ψ)))

	Rᵏ[0] = ζ * exp(z[1]) * k[0] ^ (ζ - 1) * l[1] ^ (1 - ζ) - δ

	SDF⁺¹[0] = c[0] * β * (((1 - l[1]) / (1 - l[0])) ^ (1 - ν) * (c[1] / c[0]) ^ ν) ^ ((1 - γ) / ((1 - γ) / (1 - 1 / ψ))) / c[1] * (V[1] ^ (1 - γ) / exp(s[0])) ^ (1 - 1 / ((1 - γ) / (1 - 1 / ψ)))

	1 + Rᶠ[0] = 1 / SDF⁺¹[0]

	(1 - ν) / ν * c[0] / (1 - l[0]) = (1 - ζ) * exp(z[0]) * k[-1] ^ ζ * l[0] ^ (-ζ)

	c[0] + i[0] = exp(z[0]) * k[-1] ^ ζ * l[0] ^ (1 - ζ)

	k[0] = i[0] + k[-1] * (1 - δ)

	z[0] = λ * z[-1] + σ[0] * ϵᶻ[x]

	y[0] = exp(z[0]) * k[-1] ^ ζ * l[0] ^ (1 - ζ)

	log(σ[0]) = (1 - ρ) * log(σ̄) + ρ * log(σ[-1]) + η * ω[x]

end


@parameters Caldara_et_al_2012 begin
	β = 0.991

	l[ss] = 1/3 | ν

	ζ = 0.3

	δ = 0.0196

	λ = 0.95

	ψ = 0.5

	γ = 10

	σ̄ = 0.021

	η = 0.1

	ρ = 0.9

end
