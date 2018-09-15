## conversion between spectrum envelop and mel-cepstrum

using FFTW

# TODO(ryuichi) import from MelGeneralizedCepstrums or SPTK
# copied from r9y9/MelGeneralizedCepstrums.jl
function freqt!(wc::AbstractVector, c::AbstractVector, α;
                prev=Array{eltype(wc)}(undef, length(wc)))
    fill!(wc, zero(eltype(wc)))
    dst_order = length(wc) - 1

    m1 = length(c)-1
    for i in -m1:0
        copyto!(prev, wc)
        if dst_order >= 0
            @inbounds wc[1] = c[-i+1] + α*prev[1]
        end
        if dst_order >= 1
            wc[2] = (1.0-α*α)*prev[1] + α*prev[2]
        end
        for m=3:dst_order+1
            @inbounds wc[m] = prev[m-1] + α*(prev[m] - wc[m-1])
        end
    end

    wc
end

function freqt(c::AbstractVector, order=25, α=0.35)
    wc = Array{eltype(c)}(undef, order+1)
    freqt!(wc, c, α)
end

"""
$(SIGNATURES)

sp2mc converts power spectrum envelope to mel-cepstrum

``
|X(\\omega)|^{2} -> c\\_{\\alpha}(m)
``
"""
function sp2mc(powerspec::AbstractVector,
               order,
               α; # all-pass constant
               fftlen::Int=(length(powerspec)-1)*2
    )
    # |X(ω)|² -> log(|X(ω)²|)
    logperiodogram = log.(powerspec)

    # transform log-periodogram to real cepstrum
    # log(|X(ω)|²) -> c(m)
    c = real(irfft(logperiodogram, fftlen))
    c[1] /= 2.0

    # c(m) -> cₐ(m)
    freqt(c, order, α)
end

"""
$(SIGNATURES)

mc2sp converts mel-cepstrum to power spectrum envelope.

``
c\\_{\\alpha}(m) -> |X(\\omega)|^{2}
``

equivalent: `exp(2real(MelGeneralizedCepstrums.mgc2sp(mc, α, 0.0, fftlen)))`
Note that `MelGeneralizedCepstrums.mgc2sp` returns log magnitude spectrum.
"""
function mc2sp(mc::AbstractVector{T}, α, fftlen) where T
    # back to cepstrum from mel-cesptrum
    # cₐ(m) -> c(m)
    c = freqt(mc, fftlen>>1, -α)
    c[1] *= 2.0

    symc = zeros(T, fftlen)
    copyto!(symc, c)
    for i=1:length(c)-1
        symc[end-i+1] = symc[i+1]
    end

    # back to power spectrum
    # c(m) -> log(|X(ω)|²) -> |X(ω)|²
    exp.(real(rfft(symc)))
end

# extend vector to vector transformation for matrix input
for f in [:sp2mc,
          :mc2sp,
          ]
    @eval begin
        function $f(x::AbstractMatrix, args...; kargs...)
            outbuf = $f(view(x, :, 1), args...; kargs...)
            ret = Array{eltype(outbuf)}(undef, length(outbuf), size(x, 2))
            copyto!(ret, 1, outbuf, 1, length(outbuf))
            for i = 2:size(x, 2)
                @inbounds ret[:, i] = $f(view(x, :, i), args...; kargs...)
            end
            ret
        end
    end
end
