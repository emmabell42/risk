# This code compiles the target capture bisulphite seq candidate table
# Candidates must have a high number of CpGs, high difference in methylation and adjacent windows
options(scipen = 999)
cancerType <- c("OvCa")
min.diff <- 0

grNames <- list.files()[grep("RDS",list.files())]
grNames <- grNames[grep(paste0(cancerType,collapse="|"),grNames)]
for(i in 1:length(grNames)){
	reading <- readRDS(grNames[i])
	toName <- gsub(".RDS",".gr",grNames[i])
	assign(toName,reading)
}
rm(i)
rm(reading)
rm(toName)

# Sequence composition analysis

library(GenomicRanges)
library(BSgenome.Hsapiens.UCSC.hg19, quietly = TRUE)
library(TxDb.Hsapiens.UCSC.hg19.knownGene, quietly = TRUE)
library(stringr)

for(i in 1:length(grNames)){

	grName <- gsub(".RDS",".gr",grNames[i])
	gr <- get(grName)
		
	for(j in 1:23){
		gr.chr <- gr[[j]]
		mcols(gr.chr) <- data.frame(mcols(gr.chr))[,1:6]
		seqs <- getSeq(Hsapiens, seqnames(gr.chr), start(gr.chr), end(gr.chr), as.character = T)

		# Calculate CpG, C and G frequency

		cg.count <- rep(NA,length(gr.chr))
		#c.count <- rep(NA,length(gr.chr))
		#g.count <- rep(NA,length(gr.chr))

		for(k in 1:length(gr.chr)){
				cg.count[k] <- str_count(seqs[k], fixed("CG"))
			#	c.count[k] <- str_count(seqs[k], fixed("C"))
			#	g.count[k] <- str_count(seqs[k], fixed("G"))
		}
		
		# Calculate GC%
		#GC <- (c.count+g.count)/200
		#toName <- paste0(type,".GC")
		#assign(toName,GC)
		
		# Calculate normalised CpG fraction
		
		# Saxonov method
		#oe <- (cg.count/(200))/((GC/2)^2)
		
		# Gardiner-Garden and Frommer method
		#oe <- (cg.count/(c.count*g.count))*200
		#toName <- paste0(type,".CpG.norm")
		#assign(toName,oe)
		
		# Which qualify as a CGI?
		
		#CGI <- GC>=0.5 & oe >=0.6
		
		#mcols(gr.chr) <- cbind(mcols(gr.chr),data.frame(CpGs=cg.count,GC=GC,NormCpG=oe,CGI=CGI))
		mcols(gr.chr) <- cbind(mcols(gr.chr),data.frame(CpGs=cg.count))
		
		gr[[j]] <- gr.chr
	}
	
	# Write to R object
	assign(grName,gr)
	
}
rm(cg.count)
rm(gr.chr)
rm(grName)
rm(gr)
rm(i)
rm(j)
rm(k)
rm(seqs)

# Find adjacent windows

for(i in 1:length(grNames)){

	grName <- gsub(".RDS",".gr",grNames[i])
	gr <- get(grName)
	
	for(j in 1:23){
		gr.chr <- gr[[j]]
		gr.reduce <- reduce(gr.chr)
		gr.reduce <- gr.reduce[which((end(gr.reduce)-start(gr.reduce))>200)]
		
		overlaps <- countOverlaps(gr.chr,gr.reduce)
		
		mcols(gr.chr) <- cbind(mcols(gr.chr),data.frame(adjacent=overlaps))
		gr[[j]] <- gr.chr
	}

	# Write to R object
	assign(grName,gr)
		
}

rm(grName)
rm(gr)
rm(gr.chr)
rm(gr.reduce)
rm(overlaps)
rm(i)
rm(j)

# Exclude windows residing within repetitive elements (i.e. SINE, LINE, LTRs)

annotations <- list.files()[grep("homer",list.files())]
for(i in 1:length(annotations)){
	toName <- gsub(".txt","",annotations[i])
	reading <- read.table(annotations[i],head=T,sep="\t",comment.char="",quote="",stringsAsFactors=F)
	colnames(reading)[1] <- "id"
	assign(toName,reading)
}

rm(annotations)
rm(i)
rm(reading)
rm(toName)

for(i in 1:length(grNames)){

	grName <- gsub(".RDS",".gr",grNames[i])
	gr <- get(grName)
	df.diff <- c()
		
	for(j in 1:23){
		df.diff <- rbind(df.diff,data.frame(seqnames=seqnames(gr[[j]]),starts=start(gr[[j]])-1,ends=end(gr[[j]]),mcols(gr[[j]])))
	}
	
	id <- paste(df.diff[,1],df.diff[,2],sep="_")
	df.diff <- cbind(df.diff,id)
	df.diff[,"id"] <- as.character(df.diff[,"id"])
	
	dfName <- gsub(".RDS",".df",grNames[i])
	assign(dfName,df.diff)
	
}

rm(df.diff)
rm(dfName)
rm(gr)
rm(grName)
rm(i)
rm(j)
rm(id)

dfs <- ls()[grep(".df",ls())]
annotations <- ls()[grep("_homer$",ls())]

for(i in 1:length(dfs)){
dfToTest <- get(dfs[i])
homerToTest <- get(annotations[i])
cat(identical(sort(as.character(dfToTest[,"id"])),sort(as.character(homerToTest[,"id"]))),"\n")
cat(length(which(!dfToTest[,"id"] %in% homerToTest[,"id"])),"\n")
}

rm(dfToTest)
rm(homerToTest)
rm(i)

for(i in 1:length(dfs)){
dfToMerge <- get(dfs[i])
homerToMerge <- get(annotations[i])
toName <- gsub(".RDS",".merge",grNames[i])
merged <- merge(dfToMerge,homerToMerge,by="id")
assign(toName,merged)
}

rm(dfToMerge)
rm(homerToMerge)
rm(toName)
rm(merged)
rm(i)
rm(dfs)

repeats <- c("SINE\\|MIR", "SINE\\|Deu", "SINE\\|tRNA-RTE", "SINE\\|tRNA", "SINE\\|Alu", "SINE\\|5S", "Retroposon\\|SVA", "LINE\\|Penelope", "LINE\\|Dong-R4", "LINE\\|Jockey-I", "LINE\\|L2", "LINE\\|CR1", "LINE\\|RTE", "LINE\\|L1", "LTR\\|ERVK", "LTR\\|ERV1", "LTR", "LTR\\|ERVL", "LTR\\|Gypsy", "RC\\|Helitron", "DNA\\|TcMar", "DNA\\|PiggyBac", "DNA\\|MULE", "DNA\\|Merlin", "DNA", "DNA\\|Kolobok", "DNA\\|hAT", "DNA\\|Harbinger", "Unknown")

for(i in 1:length(grNames)){
	mergeName <- gsub(".RDS",".merge",grNames[i])
	merged <- get(mergeName)
	merged <- cbind(merged,Repetitive=0)
	repetitiveWindows <- grep(paste0(repeats,collapse="|"),merged[,"Detailed.Annotation"])
	merged[repetitiveWindows,"Repetitive"] <- 1
	assign(mergeName,merged)
}

rm(mergeName)
rm(merged)
rm(repetitiveWindows)
rm(repeats)


# Identify pyrosequencing candidates

for(i in 1:length(grNames)){
	
	mergeName <- gsub(".RDS",".merge",grNames[i])
	merged <- get(mergeName)
	direction <- merged[,"Casemean"]-merged[,"Controlmean"]
	pyroCandidates <- merged[which(direction<0),]
	pyroCandidates <- pyroCandidates[which(pyroCandidates$CpGs>=5
	& pyroCandidates$Repetitive==0
	& pyroCandidates$adjacent==1
	),]
	pyroName <- gsub(".RDS",".pyro",grNames[i])
	assign(pyroName,pyroCandidates)
}

rm(direction)
rm(i)
rm(merged)
rm(mergeName)
rm(pyrocandidates)
rm(pyroCandidates)
rm(pyroName)

# Identify TCBS candidates

for(i in 1:length(grNames)){
	
	mergeName <- gsub(".RDS",".merge",grNames[i])
	merged <- get(mergeName)
	tcbsCandidates <- merged[which(
	merged$Repetitive==0
	& merged$CpGs>=5
	#& merged$adjacent==1
	),]
	tcbsName <- gsub(".RDS",".tcbs",grNames[i])
	assign(tcbsName,tcbsCandidates)
}

rm(i)
rm(merged)
rm(mergeName)
rm(tcbsCandidates)
rm(tcbsName)
