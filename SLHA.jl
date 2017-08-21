
module SLHA

#using Base.Test
#export test

export readSLHA,writeSLHA
export SLHAblock, SLHAmatrix, SLHAitem, SLHAlist, SLHAraw, SLHAnumber, SLHAvevaciousresults,VEVACIOUSsubblock

type SLHAblock{T}
    name::AbstractString
    comment::AbstractString
    data::T
    scale::Float64
end

#SLHAblock{T}(name,comment,data)=SLHAblock{T}(name,comment,data,NaN)

type SLHAmatrix
    data::Array{Float64,2}
    comment::Array{String,2}
end

type SLHAitem
    number::Float64
    string::AbstractString
    comment::AbstractString
end

type SLHAHBcoup{T}
    number::T
    string::AbstractString
    comment::AbstractString
end


type SLHAlist{T}
    dict::Dict{T,SLHAitem}
end

type SLHAHBcouplings
    dict::Dict{Union{Tuple{Int64,Int64,Int64},Tuple{Int64,Int64,Int64,Int64}},SLHAHBcoup}
end

type SLHADecayChannel
	number::Float64
	string::AbstractString
	comment::AbstractString
end

type SLHADecay
    dict::Dict{Union{Tuple{Int64,Int64},Tuple{Int64,Int64,Int64},Tuple{Int64,Int64,Int64,Int64}},SLHADecayChannel}
end



type SLHAraw
    data::AbstractString
end

type SLHAnumber
	number::Float64
	comment::AbstractString
end

type VEVACIOUSsubblock
	number::Float64
	description::AbstractString
	comment::AbstractString
	data::Array{Float64,1}
	dataDescription::Array{String,1}
	dataComment::Array{String,1}
end

type SLHAvevaciousresults
	stability::VEVACIOUSsubblock
	inputMinimum::VEVACIOUSsubblock
	globalMinimum::VEVACIOUSsubblock
end

@enum SLHAtype SLHAnoneType SLHArawType SLHAnumberType SLHAlistType SLHAmatrixType SLHAvevaciousresultsType SLHAHiggsXsectionType SLHAEffHiggsCouplingsType SLHAFWcoeffType SLHAHBcouplingsType SLHADecayType

        #m=match(r"\s*(\d+)\s*(\d+)\s*([\w\.\+\-\d]+)",line)
function createSLHArawblock(name,comment,data,scale=NaN)
    SLHAblock{SLHAraw}(name,comment,SLHAraw(data),scale)
end

function mparse(ttype,num)
	m=match(r"([\.\d]+)[dD](\d+)",num)
	if typeof(m)==Void
		res = try parse(ttype,num) catch; NaN end
	else
		res = parse(ttype,m[1])*10^parse(Int64,m[2])
	end
	res
end

function createVEVACIOUSresultsSubBlock(data)
	stability=0.0
	description=""
	comment=""
	
	maxRowIndex=1
	rowIndices=Array{Int64,1}()
	elements=Array{Float64,1}()
	desc=Array{String,1}()
	com=Array{String,1}()
	for line in eachline(IOBuffer(data))
#		println(line)
        	m=match(r"\s*(\d+)\s+(\d+)\s+([\+\-\deEdD\.]+)\s+(\S+)\s+#?\s*(.*)",line)
#		println(m)
		if m[2]=="0"
			stability=mparse(Float64,m[3])
			description=m[4]
			comment=m[5]
		else
			push!(rowIndices,mparse(Int64,m[2]))
	        	if rowIndices[end]>maxRowIndex
		            maxRowIndex=rowIndices[end]
		        end
	        	push!(elements,mparse(Float64,m[3]))
		 	push!(desc,m[4])
		 	push!(com,m[5])
		end

	end
#	println(rowIndices)
#	println(elements)
#	println(desc)
#	println(com)
	data=zeros(Float64,maxRowIndex)
	dataDescription=fill("",maxRowIndex)
	dataComment=fill("",maxRowIndex)
	    for i in 1:length(rowIndices)
	        data[rowIndices[i]]=elements[i]
	        dataDescription[rowIndices[i]]=desc[i]
	        dataComment[rowIndices[i]]=com[i]
	    end
 
	VEVACIOUSsubblock(stability,description,comment,data,dataDescription,dataComment)
end
	
function createSLHAvevaciousresultsblock(name,comment,data,scale=NaN)
#	println(data)

	splitData=fill("",(3,))
	for line in eachline(IOBuffer(data))
        	m=match(r"^\s*(\d+)\s+",line)
		subblock=mparse(Int64,m[1])+1
		splitData[subblock]=splitData[subblock]*line
	end
	stability = createVEVACIOUSresultsSubBlock(splitData[1])
	inputMinimum = createVEVACIOUSresultsSubBlock(splitData[2])
	globalMinimum = createVEVACIOUSresultsSubBlock(splitData[3])
	SLHAblock{SLHAvevaciousresults}(name,comment,SLHAvevaciousresults(stability,inputMinimum,globalMinimum),scale)
end

function createSLHAnumberblock(name,comment,data,scale=NaN)
    m=match(r"\s*([\+\-\d\.eEdD]+)\s+#?\s*(.*)",data)
    num=mparse(Float64,m[1])
    lcomment=m[2]
    SLHAblock{SLHAnumber}(name,comment,SLHAnumber(num,lcomment),scale)
end

function createSLHAmatrixblock(name,comment,data,scale=NaN)
    length(data)
    maxRowIndex=1
    maxColIndex=1
    rowIndices=Array{Int64,1}()
    colIndices=Array{Int64,1}()
    elements=Array{Float64,1}()
    comments=Array{String,1}()
    for line in eachline(IOBuffer(data))
        m=match(r"\s*(\d+)\s+(\d+)\s+([\+\-\deEdD\.]+)\s+#?\s*(.*)",line)
        push!(rowIndices,mparse(Int64,m[1]))
        if rowIndices[end]>maxRowIndex
            maxRowIndex=rowIndices[end]
        end
        push!(colIndices,mparse(Int64,m[2]))
        if colIndices[end]>maxColIndex
            maxColIndex=colIndices[end]
        end
        push!(elements,mparse(Float64,m[3]))
 	push!(comments,m[4])
    end
    matrix=zeros(Float64,(maxRowIndex,maxColIndex))
    matrixcomments=fill("",(maxRowIndex,maxColIndex))
    for i in 1:length(rowIndices)
        matrix[rowIndices[i],colIndices[i]]=elements[i]
        matrixcomments[rowIndices[i],colIndices[i]]=comments[i]
    end
    SLHAblock{SLHAmatrix}(name,comment,SLHAmatrix(matrix,matrixcomments),scale)
end

function createSLHAlistInt64block(name,comment,data,scale=NaN)
    dict=Dict{Int64,SLHAitem}()
    for line in eachline(IOBuffer(data))
        #m=match(r"\s*(\d+)\s+([\+\-\.EedD\d]*)\s+#?\s*(.*)",line)
        m=match(r"\s*(\d+)\s+([^#]+)\s+#?\s*(.*)",line)
        key=mparse(Int64,m[1])
        mstring=m[2]
	lcomment=m[3]
        #lcomment=""
	num = mparse(Float64,mstring)
        dict[key]=SLHAitem(num,mstring,lcomment)
    end
    SLHAblock{SLHAlist{Int64}}(name,comment,SLHAlist{Int64}(dict),scale)
end

function createSLHAHiggsXsectionblock(name,comment,data,scale=NaN)
    dict=Dict{Tuple{Int64,Int64},SLHAitem}()
    for line in eachline(IOBuffer(data))
        #m=match(r"\s*(\d+)\s+([\+\-\.EedD\d]*)\s+#?\s*(.*)",line)
        m=match(r"\s*(\d+)\s+(\d+)\s+([^#]+)\s+#?\s*(.*)",line)
        key=(mparse(Int64,m[1]),mparse(Int64,m[2]))
        mstring=m[3]
	lcomment=m[4]
        #lcomment=""
	num = mparse(Float64,mstring)
        dict[key]=SLHAitem(num,mstring,lcomment)
    end
    SLHAblock{SLHAlist{Tuple{Int64,Int64}}}(name,comment,SLHAlist{Tuple{Int64,Int64}}(dict),scale)
end

function createSLHAEffHiggsCouplingsblock(name,comment,data,scale=NaN)
    dict=Dict{Tuple{Int64,Int64,Int64},SLHAitem}()
    for line in eachline(IOBuffer(data))
        #m=match(r"\s*(\d+)\s+([\+\-\.EedD\d]*)\s+#?\s*(.*)",line)
        m=match(r"\s*(\d+)\s+(\d+)\s+(\d+)\s+([^#]+)\s+#?\s*(.*)",line)
        key=(mparse(Int64,m[1]),mparse(Int64,m[2]),mparse(Int64,m[3]))
        mstring=m[4]
	lcomment=m[5]
        #lcomment=""
	num = mparse(Float64,mstring)
        dict[key]=SLHAitem(num,mstring,lcomment)
    end
    SLHAblock{SLHAlist{Tuple{Int64,Int64,Int64}}}(name,comment,SLHAlist{Tuple{Int64,Int64,Int64}}(dict),scale)
end


function createSLHAFWcoeffblock(name,comment,data,scale=NaN)
    dict=Dict{Tuple{String,String,String,String},SLHAitem}()
    for line in eachline(IOBuffer(data))
	#m=match(r"\s*(\d+)\s+([\+\-\.EedD\d]*)\s+#?\s*(.*)",line)
	m=match(r"\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+([^#]+)\s+#?\s*(.*)",line)
	key=(m[1],m[2],m[3],m[4])
	mstring=m[5]
	lcomment=m[6]
	#lcomment=""
	num = mparse(Float64,mstring)
	dict[key]=SLHAitem(num,mstring,lcomment)
    end
    SLHAblock{SLHAlist{Tuple{String,String,String,String}}}(name,comment,SLHAlist{Tuple{String,String,String,String}}(dict),scale)
end

function createSLHAHBcouplingsblock(name,comment,data,scale=NaN)
    dict=Dict{Union{Tuple{Int64,Int64,Int64},Tuple{Int64,Int64,Int64,Int64}},SLHAHBcoup}()
    for line in eachline(IOBuffer(data))
        #m=match(r"\s*(\d+)\s+([\+\-\.EedD\d]*)\s+#?\s*(.*)",line)
        if ismatch(r"^\s*([\+\-\deEdD\.]+)\s+(\d+)\s+",line)
        	m=match(r"^\s*([\+\-\deEdD\.]+)\s+(\d+)",line)
        	mstring=m[1]
		num = mparse(Float64,mstring)
		arg=mparse(Int64,m[2])
		lcomment=""
		key=(0,0,0)
		if arg==3
	        	m=match(r"^\s*([\+\-\deEdD\.]+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+#?\s*(.*)",line)
        		key=(mparse(Int64,m[3]),mparse(Int64,m[4]),mparse(Int64,m[5]))
			lcomment=m[6]
		else 
		        m=match(r"^\s*([\+\-\deEdD\.]+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+#?\s*(.*)",line)
			key=(mparse(Int64,m[3]),mparse(Int64,m[4]),mparse(Int64,m[5]),mparse(Int64,m[6]))
			lcomment=m[7]
		end
	        dict[key]=SLHAHBcoup{Float64}(num,mstring,lcomment)
	else	
		#        if ismatch(r"^\s*([\+\-\deEdD\.]+)\s+([\+\-\deEdD\.]+)\s+(\d+)",line)
        	m=match(r"^\s*([\+\-\deEdD\.]+)\s+([\+\-\deEdD\.]+)\s+(\d+)",line)
        	mstring=m[1]*"\t"*m[2]
		num = mparse(Float64,m[1])+1im*mparse(Float64,m[2])
		arg=mparse(Int64,m[3])
		lcomment=""
		key=(0,0,0)
		if arg==3
	        	m=match(r"^\s*([\+\-\deEdD\.]+)\s+([\+\-\deEdD\.]+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+#?\s*(.*)",line)
        		key=(mparse(Int64,m[4]),mparse(Int64,m[5]),mparse(Int64,m[6]))
			lcomment=m[7]
		else 
		        m=match(r"^\s*([\+\-\deEdD\.]+)\s+([\+\-\deEdD\.]+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+#?\s*(.*)",line)
			key=(mparse(Int64,m[4]),mparse(Int64,m[5]),mparse(Int64,m[6]),mparse(Int64,m[7]))
			lcomment=m[8]
		end
	        dict[key]=SLHAHBcoup{Complex128}(num,mstring,lcomment)
	end
    end
    SLHAblock{SLHAHBcouplings}(name,comment,SLHAHBcouplings(dict),scale)
end

function createSLHADecayblock(name,comment,data,scale=NaN)
    dict=Dict{Union{Tuple{Int64,Int64},Tuple{Int64,Int64,Int64},Tuple{Int64,Int64,Int64,Int64}},SLHADecayChannel}()
    for line in eachline(IOBuffer(data))
        #m=match(r"\s*(\d+)\s+([\+\-\.EedD\d]*)\s+#?\s*(.*)",line)
        	m=match(r"^\s*([\+\-\deEdD\.]+)\s+(\d+)",line)
        	mstring=m[1]
		num = mparse(Float64,mstring)
		arg=mparse(Int64,m[2])
		lcomment=""
		key=(0,0,0)
		if arg==2
	        	m=match(r"^\s*([\+\-\deEdD\.]+)\s+(\d+)\s+([\+\-\d]+)\s+([\+\-\d]+)\s+#?\s*(.*)",line)
        		key=(mparse(Int64,m[3]),mparse(Int64,m[4]))
			lcomment=m[5]
		elseif arg==3
	        	m=match(r"^\s*([\+\-\deEdD\.]+)\s+(\d+)\s+([\+\-\d]+)\s+([\+\-\d]+)\s+([\+\-\d]+)\s+#?\s*(.*)",line)
        		key=(mparse(Int64,m[3]),mparse(Int64,m[4]),mparse(Int64,m[5]))
			lcomment=m[6]
		else 
		        m=match(r"^\s*([\+\-\deEdD\.]+)\s+(\d+)\s+([\+\-\d]+)\s+([\+\-\d]+)\s+([\+\-\d]+)\s+([\+\-\d]+)\s+#?\s*(.*)",line)
			key=(mparse(Int64,m[3]),mparse(Int64,m[4]),mparse(Int64,m[5]),mparse(Int64,m[6]))
			lcomment=m[7]
		end
	        dict[key]=SLHADecayChannel(num,mstring,lcomment)
    end
    SLHAblock{SLHADecay}(name,comment,SLHADecay(dict),scale)
end



#createSLHAnumberblock(name,comment,data)=createSLHArawblock(name,comment,data)
#createSLHAlistblock(name,comment,data)=createSLHArawblock(name,comment,data)
#createSLHAmatrixblock(name,comment,data)=createSLHArawblock(name,comment,data)

function writeSLHAnumberblock(f,data)
    write(f,@sprintf "\t%.8g" data.number)
    write(f,@sprintf "\t# %s\n" data.comment)
end

function writeSLHArawblock(f,data)
    write(f,data.data)
end

function writeSLHAmatrixblock(f,data)
    (maxRow,maxCol)=size(data.data)
    for row in 1:maxRow
        for col in 1:maxCol
#            if data.data[row,col]!=0
                write(f,@sprintf "\t%d\t%d\t%.8g\t# %s\n" row col data.data[row,col] data.comment[row,col])
#            end
        end
    end
end

function writeSLHAlistblock(f,data)
    for key in sort(collect(keys(data.dict)))
        map(k->write(f,@sprintf "\t%d" k),key)
#        write(f,@sprintf "\t%d" key)
	if isnan(data.dict[key].number)
		write(f,@sprintf "\t%s" data.dict[key].string )
	else
		write(f,@sprintf "\t%.8g" data.dict[key].number )
	end
	if length(data.dict[key].comment)>0
		write(f,"\t# "*data.dict[key].comment)
	end
	write(f,"\n")
    end
end

function writeSLHAHBcouplingsblock(f,data)
    for key in sort(collect(keys(data.dict)))
#        write(f,@sprintf "\t%d" key)
	if isnan(data.dict[key].number)
		write(f,@sprintf "\t%s" data.dict[key].string )
	else
		if typeof(data.dict[key].number)==Float64
			write(f,@sprintf "\t%.8g" data.dict[key].number )
		else
			write(f,@sprintf "\t%.8g\t%.8g"	real(data.dict[key].number) imag(data.dict[key].number) )
		end
	end
	write(f,@sprintf "\t%d" length(key))
        map(k->write(f,@sprintf "\t%d" k),key)
	if length(data.dict[key].comment)>0
		write(f,"\t# "*data.dict[key].comment)
	end
	write(f,"\n")
    end
end

function writeSLHADecayblock(f,data)
    for key in sort(collect(keys(data.dict)))
#        write(f,@sprintf "\t%d" key)
	if isnan(data.dict[key].number)
		write(f,@sprintf "\t%s" data.dict[key].string )
	else
		write(f,@sprintf "\t%.8g" data.dict[key].number )
	end
	write(f,@sprintf "\t%d" length(key))
        map(k->write(f,@sprintf "\t%d" k),key)
	if length(data.dict[key].comment)>0
		write(f,"\t# "*data.dict[key].comment)
	end
	write(f,"\n")
    end
end


function writeSLHAFWcoefflistblock(f,data)
    for key in sort(collect(keys(data.dict)))
        map(k->write(f,@sprintf "\t%s" k),key)
#        write(f,@sprintf "\t%s" data.dict[key].coeff1) 
#        write(f,@sprintf "\t%s" data.dict[key].coeff2) 
#        write(f,@sprintf "\t%s" data.dict[key].coeff3) 
#        write(f,@sprintf "\t%s" data.dict[key].coeff4) 
#        write(f,@sprintf "\t%d" key)
	if isnan(data.dict[key].number)
		write(f,@sprintf "\t%s" data.dict[key].string )
	else
		write(f,@sprintf "\t%.8g" data.dict[key].number )
	end
	if length(data.dict[key].comment)>0
		write(f,"\t# "*data.dict[key].comment)
	end
	write(f,"\n")
    end
end


function writeVEVACIOUSresultsSubBlock(f,num,block)
	write(f,@sprintf "\t%d\t%d\t%.8g\t%s\t# %s\n" num 0 block.number block.description block.comment)
	maxRow=length(block.data)
	for row in 1:maxRow
		write(f,@sprintf "\t%d\t%d\t%.8g\t%s\t# %s\n" num row block.data[row] block.dataDescription[row] block.dataComment[row])
    	end
end

function writeSLHAvevaciousresults(f,data)
	writeVEVACIOUSresultsSubBlock(f,0,data.stability)
	writeVEVACIOUSresultsSubBlock(f,1,data.inputMinimum)
	writeVEVACIOUSresultsSubBlock(f,2,data.globalMinimum)
end


function writeSLHA(slha,fname)
    open(fname,"w") do f
# check whether MODSEL is in dictionary and print it separately
	if haskey(slha,"MODSEL")
		d=slha["MODSEL"]
		write(f,"Block "*d.name)
		if length(d.comment)>0
			write(f," # "*d.comment)
		end
		write(f,"\n")
		writeSLHAlistblock(f,d.data)
	end
        for (k,d) in slha
		# don't print MODSEL
		if uppercase(d.name)=="MODSEL"
			continue
		end
            if typeof(d.data)==SLHADecay
		write(f,"Decay "*d.name)	    
	    else
		 write(f,"Block "*d.name)
	    end
	    if !isnan(d.scale)
		    write(f,@sprintf " Q=  %.8g " d.scale)
	    end
	    if length(d.comment)>0
		    write(f," # "*d.comment)
	    end
	    write(f,"\n")
            if typeof(d.data)==SLHAnumber
                writeSLHAnumberblock(f,d.data)
            elseif typeof(d.data)==SLHAmatrix
                writeSLHAmatrixblock(f,d.data)
            elseif typeof(d.data) in (SLHAlist{Int64},SLHAlist{Tuple{Int64,Int64}},SLHAlist{Tuple{Int64,Int64,Int64}})
                writeSLHAlistblock(f,d.data)
	    elseif typeof(d.data)==SLHAlist{Tuple{String,String,String,String}}
		    writeSLHAFWcoefflistblock(f,d.data)
	    elseif typeof(d.data)==SLHAHBcouplings
		    writeSLHAHBcouplingsblock(f,d.data)
            elseif typeof(d.data)==SLHAraw
                writeSLHArawblock(f,d.data)
            elseif typeof(d.data)==SLHAvevaciousresults
                writeSLHAvevaciousresults(f,d.data)
	elseif typeof(d.data)==SLHADecay
		writeSLHADecayblock(f,d.data)
	    else
                write(f,"unknown type\n")
            end
        end
        close(f)
    end
end

function createSLHAblock(currenttype,currentblockname,currentcomment,currentdata,currentscale=NaN)
#	println(@sprintf "%s %s" currentblockname currenttype)
	if currenttype==SLHAnumberType
		return	createSLHAnumberblock(currentblockname,currentcomment,currentdata,currentscale)
	elseif currenttype==SLHAHiggsXsectionType
#		println("EffHiggsXsection")
		return	createSLHAHiggsXsectionblock(currentblockname,currentcomment,currentdata,currentscale)
	elseif currenttype==SLHAEffHiggsCouplingsType
#		println("EffHiggsCouplings")
		return	createSLHAEffHiggsCouplingsblock(currentblockname,currentcomment,currentdata,currentscale)
	elseif currenttype==SLHAFWcoeffType
#		println("EffHiggsCouplings")
		return	createSLHAFWcoeffblock(currentblockname,currentcomment,currentdata,currentscale)
	elseif currenttype==SLHAHBcouplingsType
#		println("EffHiggsCouplings")
		return	createSLHAHBcouplingsblock(currentblockname,currentcomment,currentdata,currentscale)
	elseif currenttype==SLHAlistType
		return	createSLHAlistInt64block(currentblockname,currentcomment,currentdata,currentscale)
	elseif currenttype==SLHAmatrixType
		return	createSLHAmatrixblock(currentblockname,currentcomment,currentdata,currentscale)
	elseif currenttype==SLHAvevaciousresultsType
#		println("VEVACIOUS blockL: ",currentblockname)
#		println(currentdata)
		return	createSLHAvevaciousresultsblock(currentblockname,currentcomment,currentdata,currentscale)
	elseif currenttype==SLHADecayType
		return	createSLHADecayblock(currentblockname,currentcomment,currentdata,currentscale)
	else 
		return	createSLHArawblock(currentblockname,currentcomment,currentdata,currentscale)
	end 
end


function readSLHA(fname,multiScale=false)
	# does not handle yet multiple blocks with the same name
    SLHAblocks=Dict{Union{AbstractString,Tuple{AbstractString,Float64}},SLHAblock}()
    #SLHAblocks=Dict{AbstractString,SLHAblock}()
    open(fname) do f
        currentblockname=""
        currentcomment=""
        #currentdata=Array{String,1}()
        currentdata=""
	currentscale=NaN
        currenttype=SLHAnoneType
        for line in eachline(f)
            #line=chomp(line)
            # remove comments
            if ismatch(r"^\s*#.*",line) || ismatch(r"^\s*$",line)
		    continue
	    end
            if startswith(uppercase(line),"BLOCK")
                if length(currentblockname)>0
#			println(currenttype)
#			println(currentblockname)
#			println(currentcomment)
#			println(currentscale)
#			SLHAblocks[uppercase(currentblockname)]
#			println(typeof(createSLHAblock(currenttype,currentblockname,currentcomment,currentdata)))
			if multiScale && currentscale!=0.0
				SLHAblocks[(uppercase(currentblockname),currentscale)]=createSLHAblock(currenttype,currentblockname,currentcomment,currentdata,currentscale)
			else
				SLHAblocks[uppercase(currentblockname)]=createSLHAblock(currenttype,currentblockname,currentcomment,currentdata,currentscale)
			end
               end
#		line=chomp(line)
                m=match(r"\s*(\w+)\s+#?\s*(.*)",line,6)
                currentblockname=m[1]
		currentcomment=m[2]
		if ismatch(r"\s*Q=\s*([\+\-\deEdD\.]+)\s+#\s*(.*)",currentcomment)
			m=match(r"\s*Q=\s*([\+\-\deEdD\.]+)\s+#\s*(.*)",currentcomment)
			currentscale=mparse(Float64,m[1])
			currentcomment=m[2]
		else
			currentscale=NaN
		end
                #currentdata=Array{String,1}()
                currentdata=""
                currenttype=SLHAnoneType
                if uppercase(currentblockname)=="MODSEL"
			currenttype=SLHAlistType
#	                println(currentblockname,": modsel")
		elseif uppercase(currentblockname) in ("HIGGSLHC7",
			"HIGGSLHC8","HIGGSLHC13","HIGGSLHC14","HIGGSFCC100")
			currenttype=SLHAHiggsXsectionType
		elseif uppercase(currentblockname)=="EFFHIGGSCOUPLINGS"
			currenttype=SLHAEffHiggsCouplingsType
		elseif uppercase(currentblockname) in ("FWCOEF","IMFWCOEF")
#			println(currentblockname)
#			println(currentscale)
#			println(currentcomment)
			currenttype=SLHAFWcoeffType
		elseif	uppercase(currentblockname) in ("HIGGSBOUNDSINPUTHIGGSCOUPLINGSBOSONS","HIGGSBOUNDSINPUTHIGGSCOUPLINGSFERMIONS")
			currenttype=SLHAHBcouplingsType
		elseif uppercase(currentblockname)=="VEVACIOUSRESULTS"
			currenttype=SLHAvevaciousresultsType
#                        println(currentblockname,": vevacious")
		elseif uppercase(currentblockname)=="VEVACIOUSWARNINGS"
			currenttype==SLHAlistType
#			println(currentblockname,": raw")
		end
	#end
                    # ismatch(r"^\s*(\d+)\s*([\+\-\d]+\.[eE\+\-\d]+)",line)
                    #    currenttype=SLHAnumberListType
                    #    println(currentblockname,": number list")
                    #elseif 
#                    println(line)
	    elseif startswith(uppercase(line),"DECAY")
                if length(currentblockname)>0
#			println(currenttype)
#			println(currentblockname)
#			println(currentcomment)
#			println(currentscale)
#			SLHAblocks[uppercase(currentblockname)]
#			println(typeof(createSLHAblock(currenttype,currentblockname,currentcomment,currentdata)))
			if multiScale && currentscale!=0.0
				SLHAblocks[(uppercase(currentblockname),currentscale)]=createSLHAblock(currenttype,currentblockname,currentcomment,currentdata,currentscale)
			else
				SLHAblocks[uppercase(currentblockname)]=createSLHAblock(currenttype,currentblockname,currentcomment,currentdata,currentscale)
			end
               end
#
	    m=match(r"\s*(\d+)\s+([\+\-\deEdD\.]+)\s+#\s*(.*)",line,6)
#		println("DECAY blocks are currently ignored")
#			m=match(r"\s*(\w+)\s+#?\s*(.*)",line,6)
#		println(line)
#		println(m)
	        currentblockname=m[1]
		currentcomment=m[3]
        	currentdata=""
		currentscale=mparse(Float64,m[2])
		currenttype=SLHADecayType
	    else
#		    println(line)
                currentdata=currentdata*line
		if currenttype==SLHAnoneType
			if ismatch(r"^\s*([\+\-\d]+\.[eE\+\-\d]+)",line)
	               	    currenttype=SLHAnumberType
#			    println(currentblockname,": number")
	               	elseif ismatch(r"^\s*(\d+)\s+(\d+)\s+([\+\-\d]+\.[eE\+\-\d]+)",line)
				currenttype=SLHAmatrixType
#				println(currentblockname,": matrix")
		        elseif ismatch(r"^\s*(\d+)\s+(.+)\s+",line)
                	       	currenttype=SLHAlistType
			else 
				currenttype=SLHArawType
#		                println(currentblockname,": raw")
                	end
		end
	end
#            println(line)
   end
   close(f)
#   println(currentblockname)
#   println(currenttype)
#   println(currentdata)
   if length(currentblockname)>0
	   if multiScale && currentscale!=0.0
		   SLHAblocks[(uppercase(currentblockname),currentscale)]=createSLHAblock(currenttype,currentblockname,currentcomment,currentdata,currentscale)
	   else
		   SLHAblocks[uppercase(currentblockname)]=createSLHAblock(currenttype,currentblockname,currentcomment,currentdata,currentscale)
	   end
   end
#
   end
   SLHAblocks
end

       
function test()
	mtest=readSLHA("test.slha");
	println(mtest["SUSHIinfo"].data.dict[1].string)
	for (k,d) in mtest
	    println(d.name)
	    println("comment: ",d.comment)
	    println(d.data)
	    println("--------------------------\n")
	end

	println("Tests passing. Good job.")
end



end



