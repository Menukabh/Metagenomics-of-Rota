# Metagenomics analysis

```bash
# Most of the Metagenomics analysis was done by IDI-GEMS. The steps in their analyses were:
1. Trimmomatic - Trim primers and bad quality sequences
2. Kraken - Assign reads , MetaPhlAn for high resolution taxonomic profiling
3. MEGAHIT- Assemble genome to contigs
4. Check quality of assembly - QUAST
5. Classification of Contigs - CAT, based on Prodigal, Diamond
6. Annotation of assembly - DRAM
7. Binning - Grouping assembled contigs into draft genomes, Metagenome assembled genome (MAGs) - complete or near complete genome
8. Matawrap- remove duplicated contigs
9. CheckM- completeness and contamination of bins
10. De-replication of bins (dRep 3.4.0) - Remove duplicate bins and select highest quality representative MAG for each unique genome
11. Taxonomy assignment - GTDBtk
12. CoverM - Mapping each sample read to MAG and produced coverage based abundance table
13. Resulting coverage was further normalized by sequencing depth per sample (total read count per sample)

# Additional things needed to be done
1. AMR genes
2. Virulence genes
3. Alpha diversity
4. Beta diversity
 
```

```bash
- Find output of CoverM
Abundance File_normalized - metaG/stats/full_bin_coverage_normalized.tsv
Abundance file_not-normalized - metaG/stats/full_bin_coverage_non-norm.tsv
Taxonomy table- metaG/GTDBTk_refine_bins/classify/gtdbtk.bac120.summary.tsv

- Copy the taxonomy files and the count file
cp metaG/stats/full_bin_coverage_normalized.tsv menuka/data
cp metaG/stats/full_bin_coverage_non-norm.tsv menuka/data
cp metaG/GTDBTk_refine_bins/classify/gtdbtk.bac120.summary.tsv menuka/data

- Check the number of line
wc -l menuka/data/gtdbtk.bac120.summary.tsv
wc -l menuka/data/full_bin_coverage_normalized.tsv

- Count table has 115 lines whereas taxonomic assignment has 114 lines. So, one of the binned file did not have the taxonomic assignment.

- Get the sample name: You need it compute the alpha and beta diversity
cut -d ',' -f 1 metaG/stats/percent_mapped_hostrm.csv >menuka/sample_name.txt
```

**1.** AMR genes using AMRFinder plus 
```bash
# Amrfinder plus database was downloaded on 03-12-2026
CONTAINER=oras://community.wave.seqera.io/library/ncbi-amrfinderplus:4.2.7--83fb0e0d410b6f76
apptainer exec $CONTAINER amrfinder --help
database=/fs/ess/PAS3107/menuka_Metagenomics/amrfinder/amrfinder_db

## Run for all files using for loop - submitting script
for fasta in metaG/DRAM_refine_bins/AVlasova001_*/*.faa; do
sample_ID=$(basename "$fasta" .faa)
sbatch menuka/scripts/amrfinder_plus.sh "$fasta" "$database" menuka/results/AMRfinder/"$sample_ID"
done
```

**2.** Virulence genes 
```bash
# Use the database VFDB, and program ABRICATE to look for virulence genes -comes with the prebuilt database. Abricate runs on contigs file, so we will use the scaffold to run ABRICATE- metaG/DRAM_refine_bins/AVlasova001_A03_382_251028_S13binsABC_Refined_1/AVlasova001_A03_382_251028_S13binsABC_Refined_1_scaffolds.fna

for fasta in ../metaG/DRAM_refine_bins/AVlasova001_*/*_scaffolds.fna; do
sample_ID=$(basename "$fasta" _scaffolds.fna)
sbatch scripts/abricate.sh vfdb "$fasta" results/Abricate/"$sample_ID"
done
```
**3.** Alpha and Beta diversity
```bash
# Alpha and beta diversity is computed at two levels - read and genome (MAGs)
- Read level was computed using the output of MetaPhlAn [MetaPhlAn](https://github.com/biobakery/biobakery/wiki/metaphlan4#131-the-metaphlan-taxonomic-profile)
[original paper](https://www.sciencedirect.com/science/article/pii/S2211124723004758#sec4)

- At the genome level/MAG level - the output of coverM was used. Try to use the count data rather than coverage because the coverage data does not allow to compute richness metrices such as observed, ACE and chao1

- Follow these steps to get read counts per MAG [MAG dereplication and mapping](https://www.earthhologenome.org/bioinformatics/dereplication-and-mapping.html)

A. Concatenate MAG to create a MAG catalogue
ls metaG/drep_refine_bins/dereplicated_genomes/AVla*.fa | wc -l
cat metaG/drep_refine_bins/dereplicated_genomes/AVla*.fa > mag_catalogue.fa.gz

B. Build Bowtie2 index - index the MAG catalogue to speed up down stream analysis
MAG_catalogue=/fs/ess/PAS3107/mag_catalogue.fa.gz
mkdir menuka/results/bowties2_index/
out_dir=menuka/results/bowties2_index/bt2index
sbatch menuka/scripts/bowtie_index.sh "$MAG_catalogue" "$out_dir"

C. Map reads to MAGs - produce BAM : how many reads mapped to each MAGs, then sort/order the alignment by their genomic coordinates position
MAGs_indexed=/fs/ess/PAS3107/menuka/results/bowties2_index/bt2index
outdir=menuka/results/bowtie2_mapping
mkdir $outdir

for R1 in metaG/raw_reads/AVlasova001_*_R1_001.fastq.gz; do
R2="${R1/_R1_/_R2_}"
sample_Id=$(basename "$R1" _R1_001.fastq.gz)
sbatch menuka/scripts/bowtie2_BAM.sh "$MAGs_indexed" "$R1" "$R2" "$outdir"/"$sample_Id".sorted.bam
done

## Visualize the MAG catalogue
head -n 2 mag_catalogue.fa.gz

## Run CoverM - get read counts per MAGS
infile=*.sorted.bam
outdir=menuka/results/MAGS_counts
# View BAM file - to find the separator
samtools=oras://community.wave.seqera.io/library/samtools:1.23.1--5cb989b890127f7a
apptainer exec "$samtools" samtools view $infile
apptainer exec "$samtools" samtools view $infile | less -S

for BAM in menuka/results/bowtie2_mapping/*.sorted.bam; do
sample_Id=$(basename "$BAM" .sorted.bam)
sbatch menuka/scripts/coverm.sh "$BAM" "$outdir"/"$sample_Id"
done

## Add the extension to the files so that you can merge it in R
for f in menuka/results/MAGS_counts/AVlasova*; do 
 mv "$f" "${f}.txt"
done

## Copy the de-replicated MAGs and change the extension from .fa to .fna for coverM 
## CoverM only recognizes .fna, .fa.gz and .fna.gz
cp metaG/drep_refine_bins/dereplicated_genomes/*.fa menuka/results/dereplicated_MAGS
cd menuka/results/dereplicated_MAGS
for f in *.fa; do 
    mv "$f" "${f%.fa}.fna"
done

## Alpha and beta diversity was computed in R
```