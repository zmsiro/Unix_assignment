# UNIX Assignment README

```bash
# Checking file size
ls -lh fang_et_al_genotypes.txt

# Checking number of rows
wc -l fang_et_al_genotypes.txt

# Count number of columns
awk -F $'\t' '{print NF; exit}' fang_et_al_genotypes.txt

# Viewing first three metadata columns
head -n 1 fang_et_al_genotypes.txt | cut -f1-3

# Observations:
# The file is approximately 11 MB in size.
# It contains 2,783 rows and 986 columns.
# The first three columns are metadata: Sample_ID, JG_OTU, and Group.
# The remaining columns correspond to SNP genotype markers.
# Missing genotype values are encoded as ?/?.

# Checing file size
ls -lh snp_position.txt

# Counting number of rows
wc -l snp_position.txt

# Counting number of columns (tab-delimited file)
awk -F $'\t' '{print NF; exit}' snp_position.txt

# View SNP ID, chromosome, and position columns
head -n 1 snp_position.txt | cut -f1-4

# Observations
# The file contains 984 rows and 15 columns
# The first column contains SNP identifiers
# Chromosome information is whown in the third column
# Nucleotide position information is in the fourth column
# Some SNPs have unknown/multiple genomic positions


# Full pipeline:

rm -rf working output
mkdir -p working output/maize output/teosinte output/special

# General inspection of files
ls -lh fang_et_al_genotypes.txt snp_position.txt
wc -l fang_et_al_genotypes.txt snp_position.txt
awk -F $'\t' '{print NF; exit}' fang_et_al_genotypes.txt
awk -F $'\t' '{print NF; exit}' snp_position.txt
head -n 1 fang_et_al_genotypes.txt | cut -f1-3
head -n 1 snp_position.txt | cut -f1-4

# Split maize, teosinte
(head -n 1 fang_et_al_genotypes.txt && \
 awk -F $'\t' '$3=="ZMMIL" || $3=="ZMMLR" || $3=="ZMMMR"' fang_et_al_genotypes.txt) \
> working/maize_genotypes.txt

(head -n 1 fang_et_al_genotypes.txt && \
 awk -F $'\t' '$3=="ZMPBA" || $3=="ZMPIL" || $3=="ZMPJA"' fang_et_al_genotypes.txt) \
> working/teosinte_genotypes.txt

# Transpose each group
awk -f transpose.awk working/maize_genotypes.txt    > working/maize_transposed.txt
awk -f transpose.awk working/teosinte_genotypes.txt > working/teosinte_transposed.txt

# Generating SNP position table, special lists
awk -F $'\t' 'BEGIN{OFS="\t"} NR>1 {print $1,$3,$4}' snp_position.txt > working/snp_pos_3col.txt

awk -F $'\t' 'NR>1 && ($3=="unknown" || $4=="unknown") {print $1}' snp_position.txt | sort -u \
> working/unknown_snp_ids.txt

awk -F $'\t' 'NR>1 && $3=="multiple" {print $1}' snp_position.txt | sort -u \
> working/multiple_snp_ids.txt

# Sorting for join of files
sort -k1,1 working/maize_transposed.txt    > working/maize_transposed.sorted.txt
sort -k1,1 working/teosinte_transposed.txt > working/teosinte_transposed.sorted.txt
sort -k1,1 working/snp_pos_3col.txt        > working/snp_pos_3col.sorted.txt

# Join positions into genotype tables (SNP_ID matching variable)
join -t $'\t' -1 1 -2 1 \
  working/maize_transposed.sorted.txt working/snp_pos_3col.sorted.txt \
> working/maize_joined.txt

join -t $'\t' -1 1 -2 1 \
  working/teosinte_transposed.sorted.txt working/snp_pos_3col.sorted.txt \
> working/teosinte_joined.txt

# Reorder columns to: SNP_ID chromosome position genotypes
awk -F $'\t' 'BEGIN{OFS="\t"}{
  snp=$1; chr=$(NF-1); pos=$NF;
  printf "%s\t%s\t%s", snp, chr, pos;
  for(i=2;i<=NF-2;i++) printf "\t%s", $i;
  printf "\n";
}' working/maize_joined.txt > working/maize_ready.body.txt

awk -F $'\t' 'BEGIN{OFS="\t"}{
  snp=$1; chr=$(NF-1); pos=$NF;
  printf "%s\t%s\t%s", snp, chr, pos;
  for(i=2;i<=NF-2;i++) printf "\t%s", $i;
  printf "\n";
}' working/teosinte_joined.txt > working/teosinte_ready.body.txt

echo -e "SNP_ID\tChromosome\tPosition\t$(head -n 1 working/maize_transposed.txt | cut -f2-)" \
> working/maize_ready.txt
cat working/maize_ready.body.txt >> working/maize_ready.txt

echo -e "SNP_ID\tChromosome\tPosition\t$(head -n 1 working/teosinte_transposed.txt | cut -f2-)" \
> working/teosinte_ready.txt
cat working/teosinte_ready.body.txt >> working/teosinte_ready.txt

# Generate maize chromosome files (1 through 10)
for chr in {1..10}; do
  (head -n 1 working/maize_ready.txt && \
   awk -F $'\t' -v c="$chr" 'NR>1 && $2==c' working/maize_ready.txt \
   | sort -t $'\t' -k3,3n | sed 's/NA/?/g') \
  > output/maize/maize_chr${chr}_increasing.txt

  (head -n 1 working/maize_ready.txt && \
   awk -F $'\t' -v c="$chr" 'NR>1 && $2==c' working/maize_ready.txt \
   | sort -t $'\t' -k3,3nr | sed 's#\?/\?#-#g') \
  > output/maize/maize_chr${chr}_decreasing.txt
done

# Generate teosinte chromosome files (1 through 10)
for chr in {1..10}; do
  (head -n 1 working/teosinte_ready.txt && \
   awk -F $'\t' -v c="$chr" 'NR>1 && $2==c' working/teosinte_ready.txt \
   | sort -t $'\t' -k3,3n | sed 's/NA/?/g') \
  > output/teosinte/teosinte_chr${chr}_increasing.txt

  (head -n 1 working/teosinte_ready.txt && \
   awk -F $'\t' -v c="$chr" 'NR>1 && $2==c' working/teosinte_ready.txt \
   | sort -t $'\t' -k3,3nr | sed 's#\?/\?#-#g') \
  > output/teosinte/teosinte_chr${chr}_decreasing.txt
done

# Make special files (unknown or multiple)
(head -n 1 working/maize_ready.txt && \
 awk 'NR>1' working/maize_ready.txt | grep -Ff working/unknown_snp_ids.txt) \
> output/special/maize_unknown_positions.txt

(head -n 1 working/maize_ready.txt && \
 awk 'NR>1' working/maize_ready.txt | grep -Ff working/multiple_snp_ids.txt) \
> output/special/maize_multiple_positions.txt

(head -n 1 working/teosinte_ready.txt && \
 awk 'NR>1' working/teosinte_ready.txt | grep -Ff working/unknown_snp_ids.txt) \
> output/special/teosinte_unknown_positions.txt

(head -n 1 working/teosinte_ready.txt && \
 awk 'NR>1' working/teosinte_ready.txt | grep -Ff working/multiple_snp_ids.txt) \
> output/special/teosinte_multiple_positions.txt

# Final check (shoudl be 44 files)
find output -type f | wc -l


#Data processing:
# Run the full processing pipeline
bash process.sh

# Overall description of pipeline:
# Splits the genotype data into maize, teosinte groups based on the "Group" column
# SNPs now shown on rows
# Joins genotype data with SNP position
# Sorts SNPs by chromosome, genomic position
# Produces per-chromosome genotype files for maize, teosinte in both increasing, decreasing order
# Generated other "special" files for SNPs utilizing unknown and multiple genomic positions

# Maize output data (total 22 files)
# 10 files (chromosomes 1 through 10) sorted by increasing genomic position with missing data coded as '?'
# 10 files (chromosomes 1 through 10) sorted by decreasing genomic position with missing data encoded as '-'
# 1 file containing SNPs with unknown genomic positions
# 1 file containing SNPs with multiple genomic positions

#Output directories (maize, special):
output/maize/
output/special/

# Teosinte data (22 files total)
# 10 files (chromosomes 1 through 10) sorted by increasing genomic position with missing data coded as '?'
# 10 files (chromosomes 1 through 10) sorted by decreasing genomic position with missing data encoded as '-'
# 1 file containing SNPs with unknown genomic positions
# 1 file containing SNPs with multiple genomic positions

# Output directories (teosinte, special:
output/teosinte/
output/special/

# Verifying output
# Count total number of output files - expecting 44 files total
find output -type f | wc -l
