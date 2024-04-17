
PP = get_initial_covariance(Val(:theoretical), values, coordinates, dimensions)
observables = data_in_deviations

T = size(observables, 2) + 1

u = [zeros(size(C,2)) for _ in 1:T]

u_mid = deepcopy(u)

z = [zeros(size(observables, 1)) for _ in 1:T]

P_mid = [deepcopy(PP) for _ in 1:T]

temp_N_N = similar(PP)

P = deepcopy(P_mid)

B_prod = 𝐁
# Ct = collect(C')
CP = [zero(C) for _ in 1:T]

K = [zero(C') for _ in 1:T]

cc = C * C'

V = [zero(cc) for _ in 1:T]

invV = [zero(cc) for _ in 1:T]

V[1] += ℒ.I
invV[1] = inv(V[1])

innovation = deepcopy(z)

# V[1] .= C * P[1] * C'

loglik = (0.0)



for t in 2:T
    CP[t] .= C * P_mid[t-1]

    V[t] .= CP[t] * C'

    luV = ℒ.lu(V[t], check = false)

    Vdet = ℒ.det(luV)
    
    invV[t] .= inv(luV)
    
    innovation[t] .= observables[:, t-1] - z[t-1]
    
    loglik += log(Vdet) + innovation[t]' * invV[t] * innovation[t]

    K[t] .= P_mid[t-1] * C' * invV[t]

    u[t] .= K[t] * innovation[t] + u_mid[t-1]
    
    P[t] .= P_mid[t-1] - K[t] * CP[t]

    u_mid[t] .= A * u[t]

    z[t] .= C * u_mid[t]

    P_mid[t] .= A * P[t] * A' + B_prod
end

zz = -(loglik + ((size(data_in_deviations, 2) - presample_periods) * size(data_in_deviations, 1)) * log(2 * 3.141592653589793)) / 2 


# reverse pass
zz = -(loglik + ((size(data_in_deviations, 2) - presample_periods) * size(data_in_deviations, 1)) * log(2 * 3.141592653589793)) / 2 
∂z∂z = 1

# z = -(wⁿ⁻¹ + wⁿ⁻²) / 2
∂z∂wⁿ⁻¹ = -∂z∂z/ 2
∂z∂wⁿ⁻² = -∂z∂z/ 2

# wⁿ⁻¹ = loglik = wⁿ⁻³₁ + wⁿ⁻³₂ = for t in 2:4 logdet(V[t]) + innovation[t]' * invV[t] * innovation[t] end
∂wⁿ⁻¹∂wⁿ⁻³₁ = ∂z∂wⁿ⁻¹
∂wⁿ⁻¹∂wⁿ⁻³₂ = ∂z∂wⁿ⁻¹
∂wⁿ⁻¹∂wⁿ⁻³₃ = ∂z∂wⁿ⁻¹

# branch wⁿ⁻³₁
# wⁿ⁻³₁ = wⁿ⁻⁴₁ + wⁿ⁻⁵₁ = logdet(V[2]) + innovation[2]' * invV[2] * innovation[2]
∂wⁿ⁻³₁∂wⁿ⁻⁴₁ = ∂wⁿ⁻¹∂wⁿ⁻³₁
∂wⁿ⁻³₁∂wⁿ⁻⁵₁ = ∂wⁿ⁻¹∂wⁿ⁻³₁

# branch wⁿ⁻⁴₁
wⁿ⁻⁴₁ = logdet(wⁿ⁻⁶₁)
wⁿ⁻⁶₁ = C * P[1] * C'#V[2]
∂wⁿ⁻⁴₁∂wⁿ⁻⁶₁ = ∂wⁿ⁻³₁∂wⁿ⁻⁴₁ * inv(wⁿ⁻⁶₁)'

# wⁿ⁻⁶₁ = V[2] = wⁿ⁻⁷₁ * C' = CP[2] * C'
# wⁿ⁻⁷₁ = CP[2] = C * P_mid[1]
∂wⁿ⁻⁶₁∂wⁿ⁻⁷₁ = ∂wⁿ⁻⁴₁∂wⁿ⁻⁶₁ * C

∂wⁿ⁻⁷₁∂P = C' * ∂wⁿ⁻⁶₁∂wⁿ⁻⁷₁


# ∂z∂P_mid = ∂z∂z * ∂z∂wⁿ⁻¹ * ∂wⁿ⁻¹∂wⁿ⁻³₁ * ∂wⁿ⁻³₁∂wⁿ⁻⁴₁ * ∂wⁿ⁻⁴₁∂wⁿ⁻⁶₁ *  ∂wⁿ⁻⁶₁∂wⁿ⁻⁷₁ * ∂wⁿ⁻⁷₁∂P_mid


# branch wⁿ⁻³₂
# wⁿ⁻³₂ = wⁿ⁻⁴₂ + wⁿ⁻⁵₂ = logdet(V[3]) + innovation[3]' * invV[3] * innovation[3]
∂wⁿ⁻³₂∂wⁿ⁻⁴₂ = ∂wⁿ⁻¹∂wⁿ⁻³₂
∂wⁿ⁻³₂∂wⁿ⁻⁵₂ = ∂wⁿ⁻¹∂wⁿ⁻³₂

# branch wⁿ⁻⁴₂
# wⁿ⁻⁴₂ = logdet(wⁿ⁻⁶₂)
wⁿ⁻⁶₂ = C * P_mid[2] * C'#V[3]
∂wⁿ⁻⁴₂∂wⁿ⁻⁶₂ = ∂wⁿ⁻³₂∂wⁿ⁻⁴₂ * inv(wⁿ⁻⁶₂)'

# wⁿ⁻⁶₂ = V[3] = wⁿ⁻⁷₂ * C' = CP[3] * C'
# wⁿ⁻⁷₂ = CP[3] = C * P_mid[2] = C * wⁿ⁻⁸₂
∂wⁿ⁻⁶₂∂wⁿ⁻⁷₂ = ∂wⁿ⁻⁴₂∂wⁿ⁻⁶₂ * C

∂wⁿ⁻⁷₂∂wⁿ⁻⁸₂ = C' * ∂wⁿ⁻⁶₂∂wⁿ⁻⁷₂

# wⁿ⁻⁸₂ = P_mid[2] = wⁿ⁻⁹₂ + B_prod = A * P[2] * A' + B_prod

∂wⁿ⁻⁸₂∂wⁿ⁻⁹₂ = ∂wⁿ⁻⁷₂∂wⁿ⁻⁸₂

# wⁿ⁻⁹₂ = A * P[2] * A' = AP[2] * A' = wⁿ⁻¹⁰₂ * A'
wⁿ⁻¹⁰₂ = A * P[2]
∂wⁿ⁻⁹₂∂A = (wⁿ⁻¹⁰₂' * ∂wⁿ⁻⁸₂∂wⁿ⁻⁹₂)'

∂wⁿ⁻⁹₂∂wⁿ⁻¹⁰₂ = ∂wⁿ⁻⁸₂∂wⁿ⁻⁹₂ * A
∂wⁿ⁻¹⁰₂∂A = ∂wⁿ⁻⁹₂∂wⁿ⁻¹⁰₂ * P[2]'

∂z∂A = ∂wⁿ⁻¹⁰₂∂A + ∂wⁿ⁻⁹₂∂A

# ∂z∂A = ∂wⁿ⁻⁷₂∂wⁿ⁻⁸₂ * ∂z∂z * ∂z∂wⁿ⁻¹ * ∂wⁿ⁻¹∂wⁿ⁻³₁ * ∂wⁿ⁻³₂∂wⁿ⁻⁴₂ * ∂wⁿ⁻⁴₂∂wⁿ⁻⁶₂ * ∂wⁿ⁻⁶₂∂wⁿ⁻⁷₂  * ∂wⁿ⁻⁸₂∂wⁿ⁻⁹₂ * (∂wⁿ⁻⁹₂∂A + ∂wⁿ⁻⁹₂∂wⁿ⁻¹⁰₂ * ∂wⁿ⁻¹⁰₂∂A)
∂z∂A = -1/2 * C' * inv(C * P_mid[2] * C')' * C * (A * P[2] + A * P[2]')


zyggrad = Zygote.gradient(x -> -1/2*logdet(C * (x * (P[2] - P[2] * C' * invV[3] * C * P[2]) * x' + 𝐁) * C'), A)[1]

isapprox(∂z∂A, zyggrad)

# continue with wⁿ⁻¹⁰₂ derivative wrt P[2]
∂wⁿ⁻⁹₂∂wⁿ⁻¹⁰₂ = ∂wⁿ⁻⁸₂∂wⁿ⁻⁹₂ * A
# AP[2] = A * P[2] = A * wⁿ⁻¹¹₂
∂wⁿ⁻¹⁰₂∂wⁿ⁻¹¹₂ = A' * ∂wⁿ⁻⁹₂∂wⁿ⁻¹⁰₂

# wⁿ⁻¹¹₂ = P[2] =  P_mid[1] - K[2] * CP[2] = wⁿ⁻¹²₂ - wⁿ⁻¹³₂
∂wⁿ⁻¹¹₂∂P = ∂wⁿ⁻¹⁰₂∂wⁿ⁻¹¹₂
∂wⁿ⁻¹¹₂∂wⁿ⁻¹³₂ = -∂wⁿ⁻¹⁰₂∂wⁿ⁻¹¹₂


# wⁿ⁻¹³₂ = K[2] * CP[2] = wⁿ⁻¹⁴₂ * wⁿ⁻¹⁵₂
∂wⁿ⁻¹³₂∂wⁿ⁻¹⁴₂ = ∂wⁿ⁻¹¹₂∂wⁿ⁻¹³₂ * CP[2]'
∂wⁿ⁻¹³₂∂wⁿ⁻¹⁵₂ = K[2]' * ∂wⁿ⁻¹¹₂∂wⁿ⁻¹³₂


# wⁿ⁻¹⁴₂ = K[2] = PC[1] * invV[2] = P_mid[1] * C' * invV[2] = wⁿ⁻¹⁶₂ * wⁿ⁻¹⁷₂
∂wⁿ⁻¹⁴₂∂wⁿ⁻¹⁶₂ = ∂wⁿ⁻¹³₂∂wⁿ⁻¹⁴₂ * invV[2]'
∂wⁿ⁻¹⁴₂∂wⁿ⁻¹⁷₂ = (P_mid[1] * C')' * ∂wⁿ⁻¹³₂∂wⁿ⁻¹⁴₂

wⁿ⁻¹⁶₂ = P_mid[1] * C'
∂wⁿ⁻¹⁶₂∂P = ∂wⁿ⁻¹⁴₂∂wⁿ⁻¹⁶₂ * C

# wⁿ⁻¹⁷₂ = inv(V[2]) = inv(wⁿ⁻¹⁸₂)
∂wⁿ⁻¹⁷₂∂wⁿ⁻¹⁸₂ = -invV[2]' * ∂wⁿ⁻¹⁴₂∂wⁿ⁻¹⁷₂ * invV[2]'

# wⁿ⁻¹⁸₂ = V[2] = CP[2] * C' = wⁿ⁻¹⁹₂ * C' = wⁿ⁻⁶₁
# wⁿ⁻¹⁹₂ = CP[2] = C * P_mid[1]
∂wⁿ⁻¹⁸₂∂wⁿ⁻¹⁹₂ = ∂wⁿ⁻¹⁷₂∂wⁿ⁻¹⁸₂ * C
∂wⁿ⁻¹⁹₂∂P = C' * ∂wⁿ⁻¹⁸₂∂wⁿ⁻¹⁹₂


# wⁿ⁻¹⁹₂ = wⁿ⁻¹⁵₂
∂wⁿ⁻¹⁵₂∂P = C' * ∂wⁿ⁻¹³₂∂wⁿ⁻¹⁵₂


∂z∂P = ∂wⁿ⁻¹⁵₂∂P + ∂wⁿ⁻¹⁹₂∂P + ∂wⁿ⁻¹⁶₂∂P + ∂wⁿ⁻¹¹₂∂P + ∂wⁿ⁻⁷₁∂P

isapprox(∂wⁿ⁻¹⁵₂∂P, C' * K[2]' * -A' * C' * -∂z∂z / 2 * invV[3]' * C * A)

isapprox(∂wⁿ⁻¹⁹₂∂P, C' * -invV[2]' * (P_mid[1] * C')' * -A' * C' * -∂z∂z / 2 * invV[3]' * C * A * CP[2]' * invV[2]' * C)
# isapprox(∂wⁿ⁻¹⁹₂∂P, C' * -K[2]' * -A' * C' * -∂z∂z / 2 * invV[3]' * C * A * K[2] * C)

isapprox(∂wⁿ⁻¹⁶₂∂P, -A' * C' * -∂z∂z / 2 * invV[3]' * C * A * CP[2]' * invV[2]' * C)
# isapprox(∂wⁿ⁻¹⁶₂∂P, -A' * C' * -∂z∂z / 2 * invV[3]' * C * A * K[2] * C)

isapprox(∂wⁿ⁻¹¹₂∂P, A' * C' * -∂z∂z / 2 * invV[3]' * C * A)

isapprox(∂wⁿ⁻⁷₁∂P, C' * -∂z∂z/ 2 * invV[2]' * C)




core = C' * -∂z∂z / 2 * invV[3]' * C
isapprox(∂wⁿ⁻¹⁵₂∂P, C' * K[2]' * -A' * core * A)

isapprox(∂wⁿ⁻¹⁹₂∂P, C' * -invV[2]' * (P_mid[1] * C')' * -A' * core * A * CP[2]' * invV[2]' * C)
# isapprox(∂wⁿ⁻¹⁹₂∂P, C' * -K[2]' * -A' * core * A * K[2] * C)

isapprox(∂wⁿ⁻¹⁶₂∂P, -A' * core * A * CP[2]' * invV[2]' * C)
# isapprox(∂wⁿ⁻¹⁶₂∂P, -A' * core * A * K[2] * C)

isapprox(∂wⁿ⁻¹¹₂∂P, A' * core * A)


core = C' * -∂z∂z / 2 * invV[3]' * C
AcoreA = A' * core * A
AcoreA * (ℒ.I - CP[2]' * invV[2]' * C) + C' * invV[2]' * (P_mid[1] * C')' * AcoreA * CP[2]' * invV[2]' * C - C' * K[2]' * AcoreA


zyggrad = Zygote.gradient(x -> -1/2*logdet(C * x * C'), PP)[1]

isapprox(∂wⁿ⁻⁷₁∂P, zyggrad)

∂wⁿ⁻¹¹₂∂P

zyggrad = Zygote.gradient(x -> -1/2*(logdet(C * (A * (x - PP * C' * inv(C * PP * C') * C * PP) * A' + 𝐁) * C')), PP)[1]
isapprox(∂wⁿ⁻¹¹₂∂P, zyggrad)


zyggrad = Zygote.gradient(x -> -1/2*(logdet(C * (A * (x) * A' + 𝐁) * C')), PP)[1]



zyggrad = Zygote.gradient(x -> -1/2*(logdet(C * (A * (x - x * C' * inv(C * x * C') * C * x) * A' + 𝐁) * C') + logdet(C * x * C')), PP)[1]
forgrad = ForwardDiff.gradient(x -> -1/2*(logdet(C * (A * (x - x * C' * inv(C * x * C') * C * x) * A' + 𝐁) * C') + logdet(C * x * C')), PP)

isapprox(zyggrad, ∂z∂P)
isapprox(zyggrad, forgrad)


# fingrad = FiniteDifferences.grad(FiniteDifferences.central_fdm(4,1),
# x -> begin
# P_mid[1] = deepcopy(x)
# P[1] = deepcopy(x)
# loglik = 0.0
# for t in 2:3
#     CP[t] .= C * P_mid[t-1]

#     V[t] .= CP[t] * C'

#     luV = ℒ.lu(V[t], check = false)

#     Vdet = ℒ.det(luV)
    
#     invV[t] .= inv(luV)
    
#     innovation[t] .= observables[:, t-1] - z[t-1]
    
#     loglik += log(Vdet)# + innovation[t]' * invV[t] * innovation[t]

#     K[t] .= P_mid[t-1] * C' * invV[t]

#     u[t] .= K[t] * innovation[t] + u_mid[t-1]
    
#     P[t] .= P_mid[t-1] - K[t] * CP[t]

#     u_mid[t] .= A * u[t]

#     z[t] .= C * u_mid[t]

#     P_mid[t] .= A * P[t] * A' + B_prod
# end
# return -1/2*loglik
# end, PP)[1]

zyggrad - fingrad


core = C' * -∂z∂z / 2 * invV[4]' * C
AcoreA = A' * core * A
AcoreA = A' * AcoreA * A
AcoreA * (ℒ.I - CP[2]' * invV[2]' * C) + C' * invV[2]' * (P_mid[1] * C')' * AcoreA * CP[2]' * invV[2]' * C - C' * K[2]' * AcoreA



isapprox(∂z∂P, fingrad)
isapprox(zyggrad, fingrad)
maximum(abs, zyggrad - fingrad)



# continue with t = 4
# branch wⁿ⁻³₃
# wⁿ⁻³₃ = wⁿ⁻⁴₃ + wⁿ⁻⁵₃ = logdet(V[4]) + innovation[4]' * invV[4] * innovation[4]
∂wⁿ⁻³₃∂wⁿ⁻⁴₃ = ∂wⁿ⁻¹∂wⁿ⁻³₃
∂wⁿ⁻³₃∂wⁿ⁻⁵₃ = ∂wⁿ⁻¹∂wⁿ⁻³₃

# branch wⁿ⁻⁴₃
# wⁿ⁻⁴₃ = logdet(wⁿ⁻⁶₃)
wⁿ⁻⁶₃ = C * P_mid[3] * C'#V[4]
∂wⁿ⁻⁴₃∂wⁿ⁻⁶₃ = ∂wⁿ⁻³₃∂wⁿ⁻⁴₃ * inv(wⁿ⁻⁶₃)'

# wⁿ⁻⁶₃ = V[4] = wⁿ⁻⁷₃ * C' = CP[4] * C'
# wⁿ⁻⁷₃ = CP[4] = C * P_mid[3] = C * wⁿ⁻⁸₃
∂wⁿ⁻⁶₃∂wⁿ⁻⁷₃ = ∂wⁿ⁻⁴₃∂wⁿ⁻⁶₃ * C

∂wⁿ⁻⁷₃∂wⁿ⁻⁸₃ = C' * ∂wⁿ⁻⁶₃∂wⁿ⁻⁷₃

# wⁿ⁻⁸₃ = P_mid[3] = wⁿ⁻⁹₃ + B_prod = A * P[3] * A' + B_prod

∂wⁿ⁻⁸₃∂wⁿ⁻⁹₃ = ∂wⁿ⁻⁷₃∂wⁿ⁻⁸₃

# wⁿ⁻⁹₃ = A * P[3] * A' = AP[3] * A' = wⁿ⁻¹⁰₃ * A'
wⁿ⁻¹⁰₃ = A * P[3]
∂wⁿ⁻⁹₃∂A = (wⁿ⁻¹⁰₃' * ∂wⁿ⁻⁸₃∂wⁿ⁻⁹₃)'

∂wⁿ⁻⁹₃∂wⁿ⁻¹⁰₃ = ∂wⁿ⁻⁸₃∂wⁿ⁻⁹₃ * A

∂wⁿ⁻¹⁰₃∂A = ∂wⁿ⁻⁹₃∂wⁿ⁻¹⁰₃ * P[3]'

∂z∂A = ∂wⁿ⁻¹⁰₃∂A + ∂wⁿ⁻⁹₃∂A

# ∂z∂A = ∂wⁿ⁻⁷₃∂wⁿ⁻⁸₃ * ∂z∂z * ∂z∂wⁿ⁻¹ * ∂wⁿ⁻¹∂wⁿ⁻³₁ * ∂wⁿ⁻³₃∂wⁿ⁻⁴₃ * ∂wⁿ⁻⁴₃∂wⁿ⁻⁶₃ * ∂wⁿ⁻⁶₃∂wⁿ⁻⁷₃  * ∂wⁿ⁻⁸₃∂wⁿ⁻⁹₃ * (∂wⁿ⁻⁹₃∂A + ∂wⁿ⁻⁹₃∂wⁿ⁻¹⁰₃ * ∂wⁿ⁻¹⁰₃∂A)
∂z∂A = -1/2 * C' * inv(C * P_mid[3] * C')' * C * (A * P[3] + A * P[3]')


zyggrad = Zygote.gradient(x -> -1/2*logdet(C * (x * (P[3] - P[3] * C' * invV[4] * C * P[3]) * x' + 𝐁) * C'), A)[1]

isapprox(∂z∂A, zyggrad)

# continue with wⁿ⁻¹⁰₃ derivative wrt P[3]
∂wⁿ⁻⁹₃∂wⁿ⁻¹⁰₃ = ∂wⁿ⁻⁸₃∂wⁿ⁻⁹₃ * A
# AP[3] = A * P[3] = A * wⁿ⁻¹¹₃
∂wⁿ⁻¹⁰₃∂wⁿ⁻¹¹₃ = A' * ∂wⁿ⁻⁹₃∂wⁿ⁻¹⁰₃

# wⁿ⁻¹¹₃ = P[3] =  P_mid[2] - K[3] * CP[3] = wⁿ⁻¹²₃ - wⁿ⁻¹³₃
∂wⁿ⁻¹¹₃∂wⁿ⁻¹²₃ = ∂wⁿ⁻¹⁰₃∂wⁿ⁻¹¹₃
∂wⁿ⁻¹¹₃∂wⁿ⁻¹³₃ = -∂wⁿ⁻¹⁰₃∂wⁿ⁻¹¹₃

# wⁿ⁻¹²₃ = P_mid[2] = wⁿ⁻¹²₃¹ + B_prod = A * P[2] * A' + B_prod
∂wⁿ⁻¹²₃∂wⁿ⁻¹²₃¹ = ∂wⁿ⁻¹¹₃∂wⁿ⁻¹²₃

# wⁿ⁻¹²₃¹ = A * P[2] * A' = AP[2] * A' = wⁿ⁻¹²₃² * A'
wⁿ⁻¹²₃² = A * P[2]
∂wⁿ⁻¹²₃¹∂A = (wⁿ⁻¹²₃²' * ∂wⁿ⁻¹¹₃∂wⁿ⁻¹²₃)'
∂wⁿ⁻¹²₃¹∂wⁿ⁻¹²₃² = ∂wⁿ⁻¹¹₃∂wⁿ⁻¹²₃ * A

∂wⁿ⁻¹²₃²∂A = ∂wⁿ⁻¹²₃¹∂wⁿ⁻¹²₃² * P[2]'

# effect through wⁿ⁻¹³₃ = K[3] * CP[3]
# wⁿ⁻¹³₃ = K[3] * CP[3] = wⁿ⁻¹⁴₃ * wⁿ⁻¹⁵₃
∂wⁿ⁻¹³₃∂wⁿ⁻¹⁴₃ = ∂wⁿ⁻¹¹₃∂wⁿ⁻¹³₃ * CP[3]'
∂wⁿ⁻¹³₃∂wⁿ⁻¹⁵₃ = K[3]' * ∂wⁿ⁻¹¹₃∂wⁿ⁻¹³₃

# wⁿ⁻¹⁴₃ = K[3] = PC[2] * invV[3] = P_mid[2] * C' * invV[3] = wⁿ⁻¹⁶₃ * wⁿ⁻¹⁷₃
∂wⁿ⁻¹⁴₃∂wⁿ⁻¹⁶₃ = ∂wⁿ⁻¹³₃∂wⁿ⁻¹⁴₃ * invV[3]'
∂wⁿ⁻¹⁴₃∂wⁿ⁻¹⁷₃ = (P_mid[2] * C')' * ∂wⁿ⁻¹³₃∂wⁿ⁻¹⁴₃

# wⁿ⁻¹⁶₃ = P_mid[2] * C' = wⁿ⁻¹⁶₃¹ * C'
∂wⁿ⁻¹⁶₃∂wⁿ⁻¹⁶₃¹ = ∂wⁿ⁻¹⁴₃∂wⁿ⁻¹⁶₃ * C

# wⁿ⁻¹⁶₃¹ = P_mid[2] = wⁿ⁻¹⁶₃² + B_prod = A * P[2] * A' + B_prod
# wⁿ⁻¹⁶₃² = A * P[2] * A' = AP[2] * A' = wⁿ⁻¹⁶₃³ * A'
wⁿ⁻¹⁶₃³ = A * P[2]
∂wⁿ⁻¹⁶₃²∂A = (wⁿ⁻¹⁶₃³' * ∂wⁿ⁻¹⁶₃∂wⁿ⁻¹⁶₃¹)'
∂wⁿ⁻¹⁶₃²∂wⁿ⁻¹⁶₃³ = ∂wⁿ⁻¹⁶₃∂wⁿ⁻¹⁶₃¹ * A

∂wⁿ⁻¹⁶₃³∂A = ∂wⁿ⁻¹⁶₃²∂wⁿ⁻¹⁶₃³ * P[2]'


# wⁿ⁻¹⁷₃ = inv(V[3]) = inv(wⁿ⁻¹⁸₃)
∂wⁿ⁻¹⁷₃∂wⁿ⁻¹⁸₃ = -invV[3]' * ∂wⁿ⁻¹⁴₃∂wⁿ⁻¹⁷₃ * invV[3]'

# wⁿ⁻¹⁸₃ = V[3] = CP[3] * C' = wⁿ⁻¹⁹₃ * C' = wⁿ⁻⁶₁
# wⁿ⁻¹⁹₃ = CP[3] = C * P_mid[2] = C * wⁿ⁻²⁰₃
∂wⁿ⁻¹⁸₃∂wⁿ⁻¹⁹₃ = ∂wⁿ⁻¹⁷₃∂wⁿ⁻¹⁸₃ * C
∂wⁿ⁻¹⁹₃∂wⁿ⁻²⁰₃ = C' * ∂wⁿ⁻¹⁸₃∂wⁿ⁻¹⁹₃

# wⁿ⁻²⁰₃ = P_mid[2] = wⁿ⁻²⁰₃² + B_prod = A * P[2] * A' + B_prod
# wⁿ⁻²⁰₃² = A * P[2] * A' = AP[2] * A' = wⁿ⁻²⁰₃³ * A'
wⁿ⁻²⁰₃³ = A * P[2]
∂wⁿ⁻²⁰₃²∂A = (wⁿ⁻²⁰₃³' * ∂wⁿ⁻¹⁹₃∂wⁿ⁻²⁰₃)'
∂wⁿ⁻²⁰₃²∂wⁿ⁻²⁰₃³ = ∂wⁿ⁻¹⁹₃∂wⁿ⁻²⁰₃ * A

∂wⁿ⁻²⁰₃³∂A = ∂wⁿ⁻²⁰₃²∂wⁿ⁻²⁰₃³ * P[2]'



# wⁿ⁻¹⁹₃ = wⁿ⁻¹⁵₃ = CP[3] = C * P_mid[2] = C * wⁿ⁻¹⁵₃¹
∂wⁿ⁻¹⁵₃∂P = C' * ∂wⁿ⁻¹³₃∂wⁿ⁻¹⁵₃

∂wⁿ⁻¹⁵₃∂wⁿ⁻¹⁵₃¹ = C' * ∂wⁿ⁻¹³₃∂wⁿ⁻¹⁵₃

# wⁿ⁻¹⁵₃¹ = P_mid[2] = wⁿ⁻¹⁵₃² + B_prod = A * P[2] * A' + B_prod
# wⁿ⁻¹⁵₃² = A * P[2] * A' = AP[2] * A' = wⁿ⁻¹⁵₃³ * A'
wⁿ⁻¹⁵₃¹ = A * P[2]
∂wⁿ⁻¹⁵₃²∂A = (wⁿ⁻¹⁵₃¹' * ∂wⁿ⁻¹⁵₃∂wⁿ⁻¹⁵₃¹)'
∂wⁿ⁻¹⁵₃²∂wⁿ⁻¹⁵₃³ = ∂wⁿ⁻¹⁵₃∂wⁿ⁻¹⁵₃¹ * A

∂wⁿ⁻¹⁵₃³∂A = ∂wⁿ⁻¹⁵₃²∂wⁿ⁻¹⁵₃³ * P[2]'

∂z∂A₃ = ∂wⁿ⁻¹⁰₃∂A + ∂wⁿ⁻⁹₃∂A + ∂wⁿ⁻¹²₃¹∂A + ∂wⁿ⁻¹²₃²∂A + ∂wⁿ⁻¹⁶₃²∂A + ∂wⁿ⁻¹⁶₃³∂A + ∂wⁿ⁻²⁰₃²∂A + ∂wⁿ⁻²⁰₃³∂A + ∂wⁿ⁻¹⁵₃²∂A + ∂wⁿ⁻¹⁵₃³∂A # this is correct and captues the effect for t = 4

∂wⁿ⁻⁹₃∂A   ≈ ((A * P[3])' *                                             C' * -∂z∂z/ 2 * inv(V[4])' * C    )'
∂wⁿ⁻¹⁰₃∂A  ≈                                                            C' * -∂z∂z/ 2 * inv(V[4])' * C     * A * P[3]'
∂wⁿ⁻¹²₃¹∂A ≈ ((A * P[2])' * A' *                                        C' * -∂z∂z/ 2 * inv(V[4])' * C     * A)'
∂wⁿ⁻¹⁵₃²∂A ≈ ((A * P[2])' * C' * K[3]' * -A' *                          C' * -∂z∂z/ 2 * inv(V[4])' * C     * A)'
∂wⁿ⁻¹²₃²∂A ≈ A' *                                                       C' * -∂z∂z/ 2 * inv(V[4])' * C     * A * A * P[2]'
∂wⁿ⁻¹⁵₃³∂A ≈ C' * K[3]' * -A' *                                         C' * -∂z∂z/ 2 * inv(V[4])' * C     * A * A * P[2]'
∂wⁿ⁻¹⁶₃²∂A ≈ ((A * P[2])' * -A' *                                       C' * -∂z∂z/ 2 * inv(V[4])' * C     * A * CP[3]' * inv(V[3])' * C)'
∂wⁿ⁻²⁰₃²∂A ≈ ((A * P[2])' * C' * -invV[3]'* (P_mid[2] * C')' * -A' *    C' * -∂z∂z/ 2 * inv(V[4])' * C     * A * CP[3]' * inv(V[3])' * C)'
∂wⁿ⁻¹⁶₃³∂A ≈ -A' *                                                      C' * -∂z∂z/ 2 * inv(V[4])' * C     * A * CP[3]' * inv(V[3])' * C * A * P[2]'
∂wⁿ⁻²⁰₃³∂A ≈ C' *  -invV[3]' * (P_mid[2] * C')' * -A' *                 C' * -∂z∂z/ 2 * inv(V[4])' * C     * A * CP[3]' * inv(V[3])' * C * A * P[2]'

∂z∂A₂ = ∂wⁿ⁻¹⁰₂∂A + ∂wⁿ⁻⁹₂∂A # this is correct and captues the effect for t = 3

∂wⁿ⁻¹⁰₂∂A ≈ C' * -∂z∂z/ 2 * inv(V[3])' * C * A * P[2]'
∂wⁿ⁻⁹₂∂A  ≈ ((A * P[2])' * C' * -∂z∂z/ 2 * inv(V[3])' * C)'
# ∂z∂A = ∂wⁿ⁻⁷₃∂wⁿ⁻⁸₃ * ∂z∂z * ∂z∂wⁿ⁻¹ * ∂wⁿ⁻¹∂wⁿ⁻³₁ * ∂wⁿ⁻³₃∂wⁿ⁻⁴₃ * ∂wⁿ⁻⁴₃∂wⁿ⁻⁶₃ * ∂wⁿ⁻⁶₃∂wⁿ⁻⁷₃  * ∂wⁿ⁻⁸₃∂wⁿ⁻⁹₃ * (∂wⁿ⁻⁹₃∂A + ∂wⁿ⁻⁹₃∂wⁿ⁻¹⁰₃ * ∂wⁿ⁻¹⁰₃∂A)
# ∂z∂A₂ = -1/2 * C' * inv(C * P_mid[3] * C')' * C * (A * P[3] + A * P[3]')


∂z∂A = ∂wⁿ⁻¹⁰₂∂A + ∂wⁿ⁻⁹₂∂A + ∂wⁿ⁻¹⁰₃∂A + ∂wⁿ⁻⁹₃∂A + ∂wⁿ⁻¹²₃¹∂A + ∂wⁿ⁻¹²₃²∂A + ∂wⁿ⁻¹⁶₃²∂A + ∂wⁿ⁻¹⁶₃³∂A + ∂wⁿ⁻²⁰₃²∂A + ∂wⁿ⁻²⁰₃³∂A + ∂wⁿ⁻¹⁵₃²∂A + ∂wⁿ⁻¹⁵₃³∂A # this is correct and captues the effect for all t

zyggrad =   Zygote.gradient(
                x -> begin
                    P_mid2 = x * P[2] * x' + B_prod
                    CP3 = C * P_mid2
                    V3 = CP3 * C'
                    K3 = P_mid2 * C' * inv(V3)
                    P3 = P_mid2 - K3 * CP3

                    P_mid3 = x * P3 * x' + B_prod
                    CP4 = C * P_mid3
                    V4 = CP4 * C'
                    return -1/2*(logdet(V3))
                    # return -1/2*(logdet(V4) + logdet(V3))
                end, 
            A)[1]

isapprox(∂z∂A₂, zyggrad)
∂z∂A - zyggrad

zyggrad =   Zygote.gradient(
                x -> begin
                    P_mid2 = x * P[2] * x' + B_prod
                    CP3 = C * P_mid2
                    V3 = CP3 * C'
                    K3 = P_mid2 * C' * inv(V3)
                    P3 = P_mid2 - K3 * CP3

                    P_mid3 = x * P[3] * x' + B_prod
                    CP4 = C * P_mid3
                    V4 = CP4 * C'
                    return -1/2*logdet(V4)
                end, 
            A)[1]

isapprox(zyggrad, ∂wⁿ⁻¹⁰₃∂A + ∂wⁿ⁻⁹₃∂A)
zyggrad - (∂wⁿ⁻¹⁰₃∂A + ∂wⁿ⁻⁹₃∂A)


zyggrad =   Zygote.gradient(
                x -> begin
                    P_mid2 = x * P[2] * x' + B_prod
                    # CP3 = C * P_mid2
                    # V3 = CP3 * C'
                    # K3 = P_mid2 * C' * inv(V3)
                    P3 = P_mid2 - K[3] * CP[3]

                    P_mid3 = A * P3 * A' + B_prod
                    CP4 = C * P_mid3
                    V4 = CP4 * C'
                    return -1/2*logdet(V4)
                end, 
            A)[1]

isapprox(zyggrad, ∂wⁿ⁻¹²₃¹∂A + ∂wⁿ⁻¹²₃²∂A)
zyggrad - (∂wⁿ⁻¹²₃¹∂A + ∂wⁿ⁻¹²₃²∂A)
maximum(abs, zyggrad - (∂wⁿ⁻¹²₃¹∂A + ∂wⁿ⁻¹²₃²∂A))



zyggrad =   Zygote.gradient(
                x -> begin
                    P_mid2 = x * P[2] * x' + B_prod
                    CP3 = C * P_mid2
                    # V3 = CP3 * C'
                    # K3 = P_mid2 * C' * inv(V3)
                    P3 = P_mid[2] - K[3] * CP3

                    P_mid3 = A * P3 * A' + B_prod
                    CP4 = C * P_mid3
                    V4 = CP4 * C'
                    return -1/2*logdet(V4)
                end, 
            A)[1]





isapprox(fingrad, ∂z∂A)
fingrad - ∂z∂A

∂z∂A = ∂wⁿ⁻¹⁰₃∂A + ∂wⁿ⁻⁹₃∂A + ∂wⁿ⁻¹²₃¹∂A + ∂wⁿ⁻¹²₃²∂A

zyggrad = Zygote.gradient(x -> -1/2*logdet(C * (x * (P[3] - P[3] * C' * invV[4] * C * P[3]) * x' + 𝐁) * C'), A)[1]

zyggrad =   Zygote.gradient(
                x -> begin
                    P_mid2 = x * P[2] * x' + B_prod
                    CP3 = C * P_mid2
                    V3 = CP3 * C'
                    K3 = P_mid2 * C' * inv(V3)
                    P3 = P_mid2 - K3 * CP3

                    P_mid3 = x * P3 * x' + B_prod
                    CP4 = C * P_mid3
                    V4 = CP4 * C'
                    return -1/2*logdet(V4)
                end, 
            A)[1]

isapprox(∂z∂A, zyggrad)

fingrad = FiniteDifferences.grad(FiniteDifferences.central_fdm(4,1),
x -> begin
P_mid[1] = deepcopy(PP)
P[1] = deepcopy(PP)
loglik = 0.0
for t in 2:4
    CP[t] .= C * P_mid[t-1]

    V[t] .= CP[t] * C'

    luV = ℒ.lu(V[t], check = false)

    Vdet = ℒ.det(luV)
    
    invV[t] .= inv(luV)
    
    innovation[t] .= observables[:, t-1] - z[t-1]
    if t == 4
    loglik += log(Vdet)# + innovation[t]' * invV[t] * innovation[t]
    end
    K[t] .= P_mid[t-1] * C' * invV[t]

    u[t] .= K[t] * innovation[t] + u_mid[t-1]
    
    P[t] .= P_mid[t-1] - K[t] * CP[t]

    u_mid[t] .= A * u[t]

    z[t] .= C * u_mid[t]

    P_mid[t] .= x * P[t] * x' + B_prod
end
return -1/2*loglik
end, A)[1]


isapprox(fingrad, zyggrad)

fingrad - ∂z∂A
# wⁿ⁻¹³₃ = K[3] * CP[3] = wⁿ⁻¹⁴₃ * wⁿ⁻¹⁵₃
∂wⁿ⁻¹³₃∂wⁿ⁻¹⁴₃ = ∂wⁿ⁻¹¹₃∂wⁿ⁻¹³₃ * CP[3]'
∂wⁿ⁻¹³₃∂wⁿ⁻¹⁵₃ = K[3]' * ∂wⁿ⁻¹¹₃∂wⁿ⁻¹³₃


# wⁿ⁻¹⁴₃ = K[3] = PC[2] * invV[3] = P_mid[2] * C' * invV[3] = wⁿ⁻¹⁶₃ * wⁿ⁻¹⁷₃
∂wⁿ⁻¹⁴₃∂wⁿ⁻¹⁶₃ = ∂wⁿ⁻¹³₃∂wⁿ⁻¹⁴₃ * invV[3]'
∂wⁿ⁻¹⁴₃∂wⁿ⁻¹⁷₃ = (P_mid[2] * C')' * ∂wⁿ⁻¹³₃∂wⁿ⁻¹⁴₃

wⁿ⁻¹⁶₃ = P_mid[2] * C'
∂wⁿ⁻¹⁶₃∂P = ∂wⁿ⁻¹⁴₃∂wⁿ⁻¹⁶₃ * C

# wⁿ⁻¹⁷₃ = inv(V[3]) = inv(wⁿ⁻¹⁸₃)
∂wⁿ⁻¹⁷₃∂wⁿ⁻¹⁸₃ = -invV[3]' * ∂wⁿ⁻¹⁴₃∂wⁿ⁻¹⁷₃ * invV[3]'

# wⁿ⁻¹⁸₃ = V[3] = CP[3] * C' = wⁿ⁻¹⁹₃ * C' = wⁿ⁻⁶₁
# wⁿ⁻¹⁹₃ = CP[3] = C * P_mid[2] = 
∂wⁿ⁻¹⁸₃∂wⁿ⁻¹⁹₃ = ∂wⁿ⁻¹⁷₃∂wⁿ⁻¹⁸₃ * C
∂wⁿ⁻¹⁹₃∂P = C' * ∂wⁿ⁻¹⁸₃∂wⁿ⁻¹⁹₃


# wⁿ⁻¹⁹₃ = wⁿ⁻¹⁵₃
∂wⁿ⁻¹⁵₃∂P = C' * ∂wⁿ⁻¹³₃∂wⁿ⁻¹⁵₃


∂z∂P = ∂wⁿ⁻¹⁵₃∂P + ∂wⁿ⁻¹⁹₃∂P + ∂wⁿ⁻¹⁶₃∂P + ∂wⁿ⁻¹¹₃∂P + ∂wⁿ⁻⁷₁∂P
