# Load packages
library(phyloseq)
library(tidyverse)
library(readxl)

# Read the count data and taxonomy assignment table
outdir <- "/fs/ess/PAS3107/menuka/results"
count_file <- "/fs/ess/PAS3107/menuka/data/full_bin_coverage_normalized.tsv"
counts <- read.table(count_file,
                     sep="",  header=TRUE, 
                     row.names=1, check.names=FALSE)

count_matrix <- as.matrix(counts)
head(count_matrix)

# Taxonomy assignment table
taxonomy_file <- "/fs/ess/PAS3107/menuka/data/gtdbtk.bac120.summary.tsv"
taxonomy <- read.table(taxonomy_file,
                       sep="\t",  header=TRUE, 
                       row.names=1, check.names=FALSE)

tax_parsed <- taxonomy |> 
  separate(classification,
           into = c("Domain","Phylum","Class","Order",
                    "Family","Genus","Species"),
           sep=";", fill="right") |> 
  mutate(across(everything(),
                ~str_replace(.x, "^[a-z]__","")))

## Select first 7 columns
tax_ps <- tax_parsed |> 
  select(1:7)

# Build phyloseq object
# Row names of count matrix must match row names of taxonomy
taxa_common <- intersect(rownames(count_matrix), rownames(tax_ps))
counts_mat <- count_matrix[taxa_common, , drop = FALSE]
tax_mat <- tax_ps[taxa_common, , drop = FALSE]
## Convert the taxonomy to to matrix from dataframe, otherwise it will coerce automatically
tax_mat_matrix <- as.matrix(tax_mat) 


# make sure that the row names of count matrix matches the row names of taxonomy:
all(rownames(counts_mat) %in% rownames(tax_mat_matrix))

# Format for phyloseq
ps_count <- otu_table(counts_mat, taxa_are_rows = TRUE)
ps_tax <- tax_table(tax_mat_matrix)
sample <- 
ps <- phyloseq(ps_count, taxa_names(ps_tax))
str(ps)
## Read sample_data - sample name must matches the column name of the count table
sample_sheet <- read_excel("/fs/ess/PAS3107/menuka/sample_data.xlsx")
str(meta)
# Convert tibble to dataframe
meta <- data.frame(sample_sheet)
rownames(meta) <- meta$Sample
meta$Sample <- NULL
meta_data <- sample_data(meta)
## Make sure that rownames of metadata matches the sample/column name in count tables
all(colnames(counts_mat) %in% rownames(meta_data))

## Create phyloseq object
ps <- phyloseq(ps_count, ps_tax, meta_data)

## Save phyloseq object
saveRDS(ps, 
        file = file.path(outdir, "seqtab.rds"))

##########################################################################################
outdir <- "/fs/ess/PAS3107/menuka/results"
## read phyloseq obejct to compute alpha diversity
ps <- readRDS(file.path(outdir, "seqtab.rds"))
ps

## Alpha diversity
alpha_diversity <- estimate_richness(ps, measures = c( "Shannon", "Simpson", "InvSimpson"))


##########################################################################################
## Use the non-normalized data
# Read the count data and taxonomy assignment table
outdir <- "/fs/ess/PAS3107/menuka/results"
count_file <- "/fs/ess/PAS3107/menuka/data/full_bin_coverage_non-norm.tsv"
counts <- read.table(count_file,
                     sep="",  header=TRUE, 
                     row.names=1, check.names=FALSE)

count_matrix <- as.matrix(counts)
head(count_matrix)

# Taxonomy assignment table
taxonomy_file <- "/fs/ess/PAS3107/menuka/data/gtdbtk.bac120.summary.tsv"
taxonomy <- read.table(taxonomy_file,
                       sep="\t",  header=TRUE, 
                       row.names=1, check.names=FALSE)

tax_parsed <- taxonomy |> 
  separate(classification,
           into = c("Domain","Phylum","Class","Order",
                    "Family","Genus","Species"),
           sep=";", fill="right") |> 
  mutate(across(everything(),
                ~str_replace(.x, "^[a-z]__","")))

## Select first 7 columns
tax_ps <- tax_parsed |> 
  select(1:7)

# Build phyloseq object
# Row names of count matrix must match row names of taxonomy
taxa_common <- intersect(rownames(count_matrix), rownames(tax_ps))
counts_mat <- count_matrix[taxa_common, , drop = FALSE]
tax_mat <- tax_ps[taxa_common, , drop = FALSE]

## Convert the taxonomy to matrix from dataframe, otherwise it will coerce automatically
tax_mat_matrix <- as.matrix(tax_mat) 


# make sure that the row names of count matrix matches the row names of taxonomy:
all(rownames(counts_mat) %in% rownames(tax_mat_matrix))

# Format for phyloseq
ps_count <- otu_table(counts_mat, taxa_are_rows = TRUE)
ps_tax <- tax_table(tax_mat_matrix)

## Read sample_data - sample name must matches the column name of the count table
sample_sheet <- read_excel("/fs/ess/PAS3107/menuka/data/sample_data.xlsx")
str(meta)

# Convert tibble to dataframe
meta <- data.frame(sample_sheet)
rownames(meta) <- meta$Sample
meta$Sample <- NULL
meta_data <- sample_data(meta)

## Make sure that rownames of metadata matches the sample/column name in count tables
all(colnames(counts_mat) %in% rownames(meta_data))

## Create phyloseq object
ps <- phyloseq(ps_count, ps_tax, meta_data)

## Save phyloseq object
saveRDS(ps, 
        file = file.path(outdir, "seqtab_non_normalized.rds"))

##########################################################################################
outdir <- "/fs/ess/PAS3107/menuka/results"
## read phyloseq obejct to compute alpha diversity
ps <- readRDS(file.path(outdir, "seqtab_non_normalized.rds"))
ps

## Alpha diversity
alpha_diversity <- estimate_richness(ps, measures = c( "Shannon", "Simpson", "InvSimpson"))

## Beta diversity
do <- ordinate(ps, method = "PCoA", distance = "bray")

plot_ordination(ps, do) +
  geom_point(size=3)


