using DataFrames, CSV
using Distributions
using Optim
using DataFramesMeta, Lazy
using Distributions

a = CSV.read("juliacon_19.csv")


a[:like_rat] = a[:likes]./a[:views]
a[:dislike_rat] = a[:disklikes]./a[:views]

qq = 0.05

function hehe3(qq, a)
    function abc(n, bads)
        p = bads/n
        res = optimize(q->(sum(pdf.(Binomial(n, q), 0:bads)) - qq)^2, 0.0, bads/n*2)
        Optim.minimizer(res)
    end

    function abc2(n, bads)
        p = bads/n
        res = optimize(q->(sum(pdf.(Binomial(n, q), 0:bads)) - (1-qq))^2, 0.0, bads/n*2)
        Optim.minimizer(res)
    end

    a[:drat] = abc.(a[:views], a[:disklikes])
    a[:lrat] = abc2.(a[:views], a[:likes])


    a[:score] = a[:lrat] .- a[:drat]

    a = sort(a, [:like_rat], rev = true)
    a[:rank_like] = 1:size(a,1)

    a = sort(a, [:dislike_rat], rev = true)
    a[:rank_dislike] = 1:size(a,1)


    a = sort(a, [:score], rev = true)
    a[:rank] = 1:size(a,1)
    a
end


function hehe2(qq, a)
    a = hehe3(qq, a)

    res1 = @> begin
        a
        @where :titles .== "Towards Faster Sorting and Group-by operations"
        @select :rank
    end

    res1[:rank][1]
end

@time which_is_best = hehe2.(0.01:0.01:0.99, Ref(a))

a = hehe3(0.05, a)

a1 = @> begin
    a
    @select :titles :rank :score :views :likes :disklikes
end

using TableView

showtable(a1)

a1[:titles] = replace.(a[:titles], Ref("," => "_"))

CSV.write("fnl_rank.csv", a1)

# using BrowseTables
#
# open_html_table(a)
