#! /usr/bin/env ruby
#
#
# category type name
#
require 'csv'
require 'rdf'
require 'rdf/vocab'
require 'rdf/turtle'

baseurl = "http://purl.jp/bio/10/med2rdf/dbnsfp/"
rdfs = "http://www.w3.org/2000/01/rdf-schema#"
ensemblGene = "http://rdf.ebi.ac.uk/resource/ensembl.gene/"
ensemblTranscript = "http://rdf.ebi.ac.uk/resource/ensembl.transcript/"
ensemblProtein = "http://rdf.ebi.ac.uk/resource/ensembl.protein/"
identifierEnsembl = "https://identifiers.org/ensembl/"
sio = "http://semanticscience.org/ontology/"
m2r = "http://med2rdf.org/ontology/med2rdf#"
faldo = "http://biohackathon.org/resource/faldo#"
hco = "http://identifiers.org/hco/"

hasValue = RDF.value
rdfsLabel = RDF::URI.new(rdfs + "label")
seeAlso = RDF::URI.new(rdfs + "seeAlso")
identifier = RDF::URI.new("http://dublincore.org/documents/dcmi-terms/identifier")
Variant = RDF::URI.new(m2r+"Variation")
hasPrediction = RDF::URI.new(baseurl+"hasPrediction")
Prediction = "Damage Prediction"
PredictionC = RDF::URI.new(baseurl+"DamagePrediction")
hasConservation = RDF::URI.new(baseurl+"hasConservation")
Conservation = "Allele Conservation"
ConservationC = RDF::URI.new(baseurl+"AlleleConservation")
hasStatistics = RDF::URI.new(baseurl+"hasStatistics")
Statistics = "Allele Statistics"
StatisticsC = RDF::URI.new(baseurl+"AlleleStatistics")
hasMV = RDF::URI.new(sio+"SIO_000216")
hasResult = RDF::URI.new(baseurl+"result")
hasCondition = RDF::URI.new(baseurl+"hasCondition")
Score = RDF::URI.new(baseurl+"PredictionScore")
RankScore = RDF::URI.new(baseurl+"PredictionRankScore")
CScore = RDF::URI.new(baseurl+"ConservationScore")
CRankScore = RDF::URI.new(baseurl+"ConservationRankScore")
Count = RDF::URI.new(sio+"SIO_000794")
Frequency = RDF::URI.new(sio+"SIO_001367")
PAlgorithm = "Prediction algorithm"
CAlgorithm = "Conservation algorithm"
Poplation = "Population"
PAlgorithmC = RDF::URI.new(baseurl+"PredictionAlgorithm")
CAlgorithmC = RDF::URI.new(baseurl+"ConservationAlgorithm")
PopulationC = RDF::URI.new(baseurl+"Population")
PAlgorithmP = RDF::URI.new(baseurl+"algorithm")
CAlgorithmP = RDF::URI.new(baseurl+"conservationAlgorithm")
PopulationP = RDF::URI.new(baseurl+"population")

LabelList = [Prediction, Conservation, Statistics]
ClassList = [PredictionC, ConservationC, StatisticsC]
PropList = [hasPrediction, hasConservation, hasStatistics]
TypePList = [PAlgorithmP, CAlgorithmP, PopulationP]
TypeCList = [PAlgorithmC, CAlgorithmC, PopulationC]
TypePreList = [baseurl+"algorithm/", baseurl+"conservation/", baseurl+"population/"]

confname = ARGV[0]
filename = ARGV[1]

def transType(value,typ)
	if typ == "float"
		value.to_f
	elsif typ == "int"
		value.to_i
	else
		value
	end
end


RDF::Turtle::Writer.open(filename + ".ttl", stream: true, base_uri:  baseurl, prefixes:  {
	nil => baseurl,
	rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
	rdfs:  "http://www.w3.org/2000/01/rdf-schema#",
	dcterms: "http://dublincore.org/documents/dcmi-terms/",
	sio: "http://semanticscience.org/ontology/",
	ebig: ensemblGene,
	ebit: ensemblTranscript,
	ebip: ensemblProtein,
	idf: identifierEnsembl,
	m2r: m2r,
	hco: hco,
	faldo: faldo
	
	}
	) do |writer|

	i = 0
	for cl in ClassList
		statement = [cl, rdfsLabel, LabelList[i] ]
		writer << statement
		i = i + 1
	end

	header = nil
	open(filename) do |file|
		csv = CSV.new(file, headers: true, col_sep: "\t")
		header = csv.shift
	end

	outConf = Hash.new
	outData = Hash.new
	outCond = Hash.new
	open(confname) do |cfile|
		conf = CSV.new(cfile, headers: false, col_sep: "\t")
		while row = conf.shift
			newFlag = false
			category = ""
			if row[0] != ""
				category = row[0]
			end
			att = row[1]
			val = row[2]
			typ = row[3]
			if !outConf.has_key?(category)
				outConf[category] = -1
				outData[category] = Array.new
				outCond[category] = Array.new
			end
			if outConf[category] == -1
				newFlag = true
			end
			if header.header?(val)
				case att
				when "score"
					outConf[category] = 0
					outData[category].push([att,val,typ,Score])
				when "rankscore"
					outConf[category] = 0
					outData[category].push([att,val,typ,RankScore])
				when "prediction"
					outConf[category] = 0
					outData[category].push(["result",val,typ])
				when "cscore"
					outConf[category] = 1
					outData[category].push([att,val,typ,CScore])
				when "crankscore"
					outConf[category] = 1
					outData[category].push([att,val,typ,CRankScore])
				when "count"
					outConf[category] = 2
					outData[category].push([att,val,typ,Count])
				when "frequency"
					outConf[category] = 2
					outData[category].push([att,val,typ,Frequency])
				else
					outCond[category].push([att,val,typ])
				end

				if newFlag and outConf[category] != -1
					statement = [RDF::URI.new(TypePreList[outConf[category]] + category), RDF.type, TypeCList[outConf[category]] ]
					writer << statement

					statement = [RDF::URI.new(TypePreList[outConf[category]] + category), rdfsLabel, RDF::Literal.new(row[0]) ]
					writer << statement
				end
			end
		end
	end

	open(filename) do |file|
		csv = CSV.new(file, headers: true, col_sep: "\t")
		while row = csv.shift
			blist = ["grch38", row["#chr"], row["pos(1-based)"], row["ref"], row["alt"] ]
			plist = ["grch38", row["#chr"], row["pos(1-based)"]]
			bid = blist.join("_")
			posid = plist.join("_")
			burl = "variation/" + bid
			buri = RDF::URI.new(baseurl+burl)
			faldouri = RDF::URI.new(baseurl + "faldo/" + posid)
			
			statement = [buri, identifier, bid]
			writer << statement
			
			statement = [buri, RDF.type, Variant]
			writer << statement
			
			statement = [buri, RDF::URI.new(faldo + "location"), faldouri]
			writer << statement
			
			statement = [faldouri, identifier, posid]
			writer << statement
			
			statement = [faldouri, RDF::URI.new(faldo + "reference"), RDF::URI.new(hco + row["#chr"] + "#GRCh38")]
			writer << statement
			
			statement = [faldouri, RDF::URI.new(faldo + "position"), RDF::Literal.new(row["pos(1-based)"].to_i)]
			writer << statement
			
			statement = [faldouri, RDF.type, RDF::URI.new(faldo + "ExactPosition")]
			writer << statement
			
			statement = [buri, RDF::URI.new(m2r + "reference_allele"), RDF::Literal.new(row["ref"])]
			writer << statement
			
			statement = [buri, RDF::URI.new(m2r + "alternative_allele"), RDF::Literal.new(row["alt"])]
			writer << statement

			vlist = row["genename"].split(/[;\:]/)
			if vlist.length >= 2
				elist = row["Ensembl_geneid"].split(/[;\:]/)
				i = 0
				for value in vlist do
					guri = RDF::URI.new(baseurl + "gene/" + value)
					statement = [buri, RDF::URI.new(m2r + "gene"), guri]
					writer << statement
					
					statement = [guri, RDF.type, RDF::URI.new(m2r + "Gene")]
					writer << statement
					
					statement = [guri, rdfsLabel, RDF::Literal.new(value)]
					writer << statement
					
					ensemblURI = RDF::URI.new(ensemblGene + elist[i])
					identifierURI = RDF::URI.new(identifierEnsembl + elist[i])
					
					statement = [guri, seeAlso, ensemblURI]
					writer << statement
					
					statement = [guri, seeAlso, identifierURI]
					writer << statement
					
					i += 1
				end
			else
				guri = RDF::URI.new(baseurl + "gene/" + row["genename"])
				statement = [buri, RDF::URI.new(m2r + "gene"), guri]
				writer << statement
				
				statement = [guri, RDF.type, RDF::URI.new(m2r + "Gene")]
				writer << statement
				
				statement = [guri, rdfsLabel, RDF::Literal.new(row["genename"])]
				writer << statement
				
				ensemblURI = RDF::URI.new(ensemblGene + row["Ensembl_geneid"])
				identifierURI = RDF::URI.new(identifierEnsembl + row["Ensembl_geneid"])
				
				statement = [guri, seeAlso, ensemblURI]
				writer << statement
				
				statement = [guri, seeAlso, identifierURI]
				writer << statement
				
			end

			hg19list = ["grch37", row["hg19_chr"], row["hg19_pos(1-based)"], row["ref"], row["alt"] ]
			hg19poslist = ["grch37", row["hg19_chr"], row["hg19_pos(1-based)"] ]
			hg19id = hg19list.join("_")
			hg19posid = hg19poslist.join("_")
			hg19uri = RDF::URI.new(baseurl + "variation/" + hg19id)
			hg19faldouri = RDF::URI.new(baseurl + "faldo/" + hg19posid)
			
			statement = [buri, RDF::URI.new(baseurl + "grch37"), hg19uri]
			writer << statement
			
			statement = [hg19uri, identifier, hg19id]
			writer << statement
			
			statement = [hg19uri, RDF.type, Variant]
			writer << statement
			
			statement = [hg19uri, RDF::URI.new(faldo + "location"), hg19faldouri]
			writer << statement
			
			statement = [hg19faldouri, identifier, hg19posid]
			writer << statement
			
			statement = [hg19faldouri, RDF::URI.new(baseurl + "reference"), RDF::URI.new(hco + row["hg19_chr"] + "#GRCh37")]
			writer << statement
			
			statement = [hg19faldouri, RDF::URI.new(faldo + "position"), RDF::Literal.new(row["hg19_pos(1-based)"].to_i)]
			writer << statement
			
			statement = [hg19faldouri, RDF.type, RDF::URI.new(faldo + "ExactPosition")]
			writer << statement
			
			statement = [buri, RDF::URI.new(baseurl + "reference_amino_acid"), RDF::Literal.new(row["aaref"])]
			writer << statement
			
			statement = [buri, RDF::URI.new(baseurl + "alternative_amino_acid"), RDF::Literal.new(row["aaalt"])]
			writer << statement
			
			outConf.each_key do |category|
				curi = RDF::URI.new(baseurl+burl+"_" + category)
				
				condSingle = Hash.new
				condMultiple = Hash.new
				noout = true
				for cList in outCond[category] do
					prop = cList[0]
					values = row[cList[1]]
					typ = cList[2]
					puri = RDF::URI.new(baseurl+prop)
					condMultiple[prop] = Array.new
					if values and values != "."
						noout = false
						vlist = values.split(/[;\:]/)
						if vlist.length >= 2
							for value in vlist do
								muri = RDF::URI.new(baseurl+burl+"_" + category)
								if prop == "ensembl_transcript" || prop == "ensembl_protein"
									case prop
									when "ensembl_transcript"
										ensemblURI = RDF::URI.new(ensemblTranscript + value)
									when "ensembl_protein"
										ensemblURI = RDF::URI.new(ensemblProtein + value)
									end
									identifierURI = RDF::URI.new(identifierEnsembl + value)
									condMultiple[prop].push(ensemblURI)
									
									statement = [muri, puri, ensemblURI]
									writer << statement
									
									statement = [ensemblURI, seeAlso, identifierURI]
									writer << statement
								else
									vnode = RDF::Literal.new(transType(value,typ))
									condMultiple[prop].push(vnode)
									
									statement = [muri, puri, vnode]
									writer << statement
								end
							end
						else
								muri = RDF::URI.new(baseurl+burl+"_" + category)

								if prop == "ensembl_transcript" || prop == "ensembl_protein"
									case prop
									when "ensembl_transcript"
										ensemblURI = RDF::URI.new(ensemblTranscript + values)
									when "ensembl_protein"
										ensemblURI = RDF::URI.new(ensemblProtein + values)
									end
									identifierURI = RDF::URI.new(identifierEnsembl + values)
									condSingle[prop] = ensemblURI
									
									statement = [muri, puri, ensemblURI]
									writer << statement
									
									statement = [ensemblURI, seeAlso, identifierURI]
									writer << statement
									
								else
									vnode = RDF::Literal.new(transType(values,typ))
									condSingle[prop] = vnode
									
									statement = [muri, puri, vnode]
									writer << statement
									
								end
						end
					end
				end
				for cList in outData[category] do
					prop = cList[0]
					puri = RDF::URI.new(baseurl+prop)
					values = row[cList[1]]
					typ = cList[2]
					type = cList[3]
					
					if values and values != "."
						noout = false
						vlist = values.split(/[;\:]/)
						if vlist.length >= 2
							i = 0
							for value in vlist do
								i = i + 1
								muri = RDF::URI.new(baseurl+burl+"_" + category + "_" + prop + "_" + i.to_s)
								vnode = RDF::Literal.new(transType(value,typ))
								if cList.length == 3
									statement = [curi, puri, vnode]
									writer << statement
									
								else
									statement = [curi, hasMV, muri]
									writer << statement

									statement = [muri, RDF.type, type]
									writer << statement

									statement = [muri, hasValue, vnode]
									writer << statement
								end
								
								for dname in condMultiple.keys do
									duriList = condMultiple[dname]
									if i <= duriList.length
										dpuri = RDF::URI.new(baseurl+dname)
										statement = [muri, dpuri, duriList[i-1]]
										writer << statement
									end
								end
							end
						else
								muri = RDF::URI.new(baseurl+burl+"_" + category + "_" + prop)
								vnode = RDF::Literal.new(transType(values,typ))
								if cList.length == 3
									statement = [curi, puri, vnode]
									writer << statement
								
								else
									statement = [curi, hasMV, muri]
									writer << statement

									statement = [muri, RDF.type, type]
									writer << statement

									statement = [muri, hasValue, vnode]
									writer << statement
								end

								for dname in condSingle.keys do
									duri = condSingle[dname]
									dpuri = RDF::URI.new(baseurl+dname)
									
									statement = [muri, dpuri, duri]
									writer << statement
								end
						end
					end
				end
				if noout == false
					statement = [buri, PropList[outConf[category]], curi]
					writer << statement

					statement = [curi, RDF.type, ClassList[outConf[category]]]
					writer << statement

					statement = [curi, TypePList[outConf[category]],RDF::URI.new(TypePreList[outConf[category]] + category) ]
					writer << statement
				end
			end
		end
	end
end

