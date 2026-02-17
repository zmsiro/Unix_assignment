# UNIX Assignment – SNP Processing Pipeline

## Overview
This repository documents my workflow for inspecting and processing SNP genotype data to produce per-chromosome genotype files for maize and teosinte
Inputs:
- `fang_et_al_genotypes.txt`
- `snp_position.txt`
- `transpose.awk`

Outputs:
- `output/maize/` (20 chromosome-sorted files)
- `output/teosinte/` (20 chromosome-sorted files)
- `output/special/` (unknown + multiple position SNP files)

## Data Inspection
Commands used:
```bash
ls -lh fang_et_al_genotypes.txt snp_position.txt
wc -l fang_et_al_genotypes.txt snp_position.txt
awk -F $'\t' '{print NF; exit}' fang_et_al_genotypes.txt
awk -F $'\t' '{print NF; exit}' snp_position.txt
head -n 1 fang_et_al_genotypes.txt | cut -f1-3
head -n 1 snp_position.txt | cut -f1-4
# Unix_assignment
