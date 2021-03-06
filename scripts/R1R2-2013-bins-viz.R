library(tidyverse)
library(patchwork)
library(formattable)
library(htmltools)
library(webshot)

mapping = read_delim('results/2013_mapping/R1R2-abundance.txt', delim="\t", col_names=FALSE)
stats = read_delim('results/2013_binning/R1R2-May2013-final-rep-species-bins-stats-table.csv', delim=',')
colnames(mapping) = c('Bin', '2013-05-13', '2013-05-23', '2013-05-28')
merged = left_join(stats, mapping)
write.csv(merged, 'results/2013_binning/2013_R1R2_finalBins_stats_mapping.csv', quote=FALSE, row.names = FALSE)

# manual classfs added
ebpr = read.csv('results/2013_R1R2_finalBins_stats_mapping_classfs.csv')

# quality figure
qual = ebpr %>% select(Highest_Classf, comp, contam)
qualFig = qual %>% ggplot(aes(x=comp, y=contam, color=Highest_Classf)) + geom_point(size=4) + scale_color_brewer(palette="Paired") + theme_classic()
qualFig

# averaging relative abundance across all may samples and 28th may day for when transcriptional experiment was done
abundance = ebpr %>% select(Bin, Highest_Classf, X5.13.13, X5.23.13, X5.28.13)
abundance$average = (abundance$X5.13.13 + abundance$X5.23.13 + abundance$X5.28.13) / 3
may2013 = abundance %>% select(Bin, Highest_Classf, X5.28.13)

# abundance figures
avgFig = abundance %>% ggplot(aes(x=reorder(Bin, -average), y=average, fill=Highest_Classf)) + geom_col() + labs(x="Genome", y="% Average Relative Abundance") + theme_classic() + scale_fill_brewer(palette="Paired")
mayFig = may2013 %>% ggplot(aes(x=reorder(Bin, -X5.28.13), y=X5.28.13, fill=Highest_Classf)) + geom_col() + labs(x="Genome", y="% Relative Abundance") + theme_classic() + scale_fill_brewer(palette="Paired")
mayFig

# TPM transcriptional results added
counts = read.csv('results/2013_transcriptomes/results/2013_R1R2_ebpr_normalized_TPM_counts_kallisto.csv')
# get average of counts
sumCounts = aggregate(counts[3:8], list(counts$Bin), sum)
sumCounts$Avg = rowMeans(sumCounts[,-1])
colnames(sumCounts)[1] = "Bin"
# merge with classf names
names = ebpr %>% select(Bin, Highest_Classf)
countsClassf = left_join(names, sumCounts)
avgCounts = countsClassf %>% select(Bin, Highest_Classf, Avg)
countsFig = avgCounts %>% ggplot(aes(x=reorder(Bin, -Avg), y=Avg, fill=Highest_Classf)) + geom_col() + labs(x="Genome", y="Average Relative Activity in Transcripts per Million [TPM]") + theme_classic() + scale_fill_brewer(palette="Paired")
countsFig

# calc raw counts
raw = read.csv('results/2013_transcriptomes/results/2013_R1R2_ebpr_raw_counts_kallisto.csv')
sumRaw = aggregate(raw[3:8], list(counts$Bin), sum)  
sumRaw$total = rowSums(sumRaw[2:7])
colnames(sumRaw)[1] = c("Bin")
rawNames = left_join(ebpr, sumRaw) %>% select(Bin, Classification, comp, contam, total)
write.csv(rawNames, 'results/2013_transcriptomes/R1R2-allBins-raw-total-counts.csv', row.names = FALSE, quote=FALSE)

# looking at abundance and activity of bins w/ > 1 million raw counts
highBins = rawNames %>% filter(total > 1000000) %>% select(Bin, Classification, comp, contam) %>% filter(comp > 90)
highAbundance = left_join(highBins, may2013)
activity = left_join(highBins, sumCounts)
highActivity = left_join(activity, names)

# plots of abundance and qual
highABPlot = highAbundance %>% ggplot(aes(x=reorder(Bin, -X5.28.13), y=X5.28.13, fill=Highest_Classf)) + geom_col() + labs(x="Genome", y="% Relative Abundance") + theme_classic() + scale_fill_brewer(palette="Paired") + theme(legend.position="none", axis.text.x= element_text(angle=85, hjust=1))
highABPlot
highQualPlot = highAbundance %>% ggplot(aes(x=comp, y=contam, color=Highest_Classf)) + geom_point(size=4) + scale_color_brewer(palette="Paired") + theme_classic()

# analyze TPM expression by anaerobic/aerobic cycles
highActivity$Anaerobic = (highActivity$B_15min_Anaerobic + highActivity$D_52min_Anaerobic + highActivity$F_92min_Anaerobic) / 3
highActivity$Aerobic = (highActivity$H_11min_Aerobic + highActivity$J_51min_Aerobic + highActivity$N_134min_Aerobic) / 3

anaerobic = highActivity %>% ggplot(aes(x=reorder(Bin, -Anaerobic), y=Anaerobic, fill=Highest_Classf)) + geom_col() + theme_classic() + theme(legend.position="none", axis.text.x= element_text(angle=85, hjust=1), axis.title.x = element_blank(), axis.title.y=element_blank()) + scale_fill_brewer(palette="Paired")

aerobic = highActivity %>% ggplot(aes(x=reorder(Bin, -Aerobic), y=Aerobic, fill=Highest_Classf)) + geom_col() + theme_classic() + theme(legend.position="none", axis.text.x= element_text(angle=85, hjust=1), axis.title.x = element_blank(), axis.title.y=element_blank()) + scale_fill_brewer(palette="Paired")

p1 =  (anaerobic + aerobic)

# plot of anaerobic and aerobic together in paired bar plot
cycles = highActivity %>% select(Bin, Anaerobic, Aerobic)
write.csv(cycles, "~/Desktop/R1R2-trans-cycles.csv", quote = FALSE, row.names = FALSE)
cyclesM = read.csv("~/Desktop/cycles-melted.csv")
p2 <- ggplot(cyclesM, aes(x=reorder(Bin, -counts), y=counts, fill=cycle)) + geom_bar(stat = "identity", position="dodge") + theme_classic() + theme(axis.text.x= element_text(angle=85, hjust=1))

ggsave(plot = highABPlot, filename="~/Desktop/R1R2-relative-abundance.png", units=c('cm'), width=15, height=10)
ggsave(plot = highQualPlot, filename="~/Desktop/R1R2-qual.png", units=c('cm'), width=10, height=5)
ggsave(plot = p1, filename="~/Desktop/R1R2-an-aer-expression.png", units=c('cm'), width=15, height=10)
ggsave(plot = p2, filename="~/Desktop/R1R2-an-aer-expression.png", units=c('cm'), width=15, height=10)

# plot of aerobic vs anaerobic expression of all bins regardless of total mapped reads
allCounts = sumCounts
allCounts$Anaerobic = (allCounts$B_15min_Anaerobic + allCounts$D_52min_Anaerobic + allCounts$F_92min_Anaerobic) / 3
allCounts$Aerobic = (allCounts$H_11min_Aerobic + allCounts$J_51min_Aerobic + allCounts$N_134min_Aerobic) / 3
cycles = allCounts %>% select(Bin, Anaerobic, Aerobic)

binOrder = readLines("results/2013_taxonomy/r1r2-bins-grouped.txt")

write.csv(cycles, "results/2013_transcriptomes/results/R1R2-anaerobic-aerobic-sums-expression.csv", quote=FALSE, row.names = FALSE)
cycles_m <- read.csv("results/2013_transcriptomes/results/R1R2-anaerobic-aerobic-sums-expression-melted.csv")

expression <- ggplot(cycles_m, aes(x=reorder(Bin, -expression), y=expression, fill=phase)) + geom_col( width=0.7, position="dodge") + scale_fill_manual(values=c("#B3B3B3", "#4D8C84")) + scale_y_log10(limits=c(1,1e6), expand=c(0,0), breaks = scales::log_breaks(n=7) ) + scale_x_discrete(limits = binOrder) + theme_classic() + theme(axis.text.x= element_text(angle=85, hjust=1), aspect.ratio=1/8)

ggsave(plot=expression, file="figs/R3R4-2013MAGs-anaerobic-aerobic-expression.png", width=8, height=10, units=c("in"))

# Final EBPR table 

ebpr_mapping <- read.csv("results/2013_R1R2_finalBins_stats_mapping_classfs.csv") %>% select(-Highest_Classf)
ebpr_stats <- read.csv("results/2013_binning/R1R2-May2013-final-rep-species-bins-stats-table.csv") %>% select(Bin, rRNA, tRNA, X5S, X16S, X23S)

colnames(ebpr_mapping) <- c("Bin", "Code", "Classification", "Completeness", "Contamination", "Size_Mbp", "Contigs", "GC", "abund-2013-5-13", "abund-2013-5-23", "abund-2013-5-28")
colnames(ebpr_stats) <- c("Bin", "rRNA", "tRNA", "rRNA_5S", "rRNA_16S", "rRNA_23S")
ebpr_table <- left_join(ebpr_mapping, ebpr_stats)
ebpr_table$Size_Mbp <- ebpr_table$Size_Mbp / 1000000

write.csv(ebpr_table, "results/R1R2-EBPR-MAGs-table.csv", quote=FALSE, row.names = FALSE)

#######################################################
# table for EBPR MAGs stats

ebpr_metadata <- ebpr_table %>% 
  select(Code, Classification, Completeness, Contamination, Size_Mbp, GC, Contigs, tRNA, rRNA, rRNA_5S, rRNA_16S, rRNA_23S, `abund-2013-5-13`, `abund-2013-5-23`, `abund-2013-5-28`)

ebpr_metadata$Size_Mbp <- round(ebpr_metadata$Size_Mbp, digits=2)
ebpr_metadata[,13:15] <- round(ebpr_metadata[,13:15], digits=2)
colnames(ebpr_metadata) <- c("Genome", "GTDB-tk Classification", "Completeness", "Redundancy", "Size (Mbp)", "GC Content", "Contigs", "tRNAs", "rRNAs", "5S rRNA", "16S rRNA", "23S rRNA", "2013-05-13 Abundance", "2013-05-23 Abundance", "2013-05-28 Abundance")

metadata_table <- formattable(ebpr_metadata, align = c("l", "l", rep("r", NCOL(ebpr_metadata) - 2)))

export_formattable <- function(f, file, width = "100%", height = NULL, 
                               background = "white", delay = 0.2)
{
  w <- as.htmlwidget(f, width = width, height = height)
  path <- html_print(w, background = background, viewer = NULL)
  url <- paste0("file:///", gsub("\\\\", "/", normalizePath(path)))
  webshot(url,
          file = file,
          selector = ".formattable_widget",
          delay = delay)
}

export_formattable(metadata_table, "figs/ebpr-metadata-table.pdf")
