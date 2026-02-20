#!/usr/bin/env bash
set -euo pipefail

rm -rf working output
mkdir -p working output/maize output/teosinte output/special

# Basic inspection
ls -lh fang_et_al_genotypes.txt snp_position.txt
wc -l fang_et_al_genotypes.txt snp_position.txt
awk -F $'\t' '{print NF; exit}' fang_et_al_genotypes.txt
awk -F $'\t' '{print NF; exit}' snp_position.txt
head -n 1 fang_et_al_genotypes.txt | cut -f1-3
head -n 1 snp_position.txt | cut -f1-4

# Split maize and teosinte
(head -n 1 fang_et_al_genotypes.txt && \
 awk -F $'\t' '$3=="ZMMIL" || $3=="ZMMLR" || $3=="ZMMMR"' fang_et_al_genotypes.txt) \
> working/maize_genotypes.txt

(head -n 1 fang_et_al_genotypes.txt && \
 awk -F $'\t' '$3=="ZMPBA" || $3=="ZMPIL" || $3=="ZMPJA"' fang_et_al_genotypes.txt) \
> working/teosinte_genotypes.txt

# Transpose each group
awk -f transpose.awk working/maize_genotypes.txt    > working/maize_transposed.txt
awk -f transpose.awk working/teosinte_genotypes.txt > working/teosinte_transposed.txt

# Prep SNP position table + special lists
awk -F $'\t' 'BEGIN{OFS="\t"} NR>1 {print $1,$3,$4}' snp_position.txt > working/snp_pos_3col.txt

awk -F $'\t' 'NR>1 && ($3=="unknown" || $4=="unknown") {print $1}' snp_position.txt | sort -u \
> working/unknown_snp_ids.txt

awk -F $'\t' 'NR>1 && $3=="multiple" {print $1}' snp_position.txt | sort -u \
> working/multiple_snp_ids.txt

# Sort for join
sort -k1,1 working/maize_transposed.txt    > working/maize_transposed.sorted.txt
sort -k1,1 working/teosinte_transposed.txt > working/teosinte_transposed.sorted.txt
sort -k1,1 working/snp_pos_3col.txt        > working/snp_pos_3col.sorted.txt

# Join positions into genotype tables (SNP_ID match)
join -t $'\t' -1 1 -2 1 \
  working/maize_transposed.sorted.txt working/snp_pos_3col.sorted.txt \
> working/maize_joined.txt

join -t $'\t' -1 1 -2 1 \
  working/teosinte_transposed.sorted.txt working/snp_pos_3col.sorted.txt \
> working/teosinte_joined.txt

# Reorder columns to: SNP_ID Chromosome Position genotypes...
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

# Make maize chromosome files (1–10)
for chr in {1..10}; do
  (head -n 1 working/maize_ready.txt && \
   awk -F $'\t' -v c="$chr" 'NR>1 && $2==c' working/maize_ready.txt \
   | sort -t $'\t' -k3,3n | sed 's/NA/?/g') \
  > output/maize/maize_chr${chr}_increasing.txt

  (head -n 1 working/maize_ready.txt && \
   awk -F $'\t' -v c="$chr" 'NR>1 && $2==c' working/maize_ready.txt \
   | sort -t $'\t' -k3,3nr | sed 's#\?/\?#-#g') \
  > output/maize/maize_chr${chr}ddecreasing.txt
done

# Make teosinte chromosome files (1–10)
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

# Make special files (unknown + multiple)
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

# Final check: 44 files
find output -type f | wc -l
