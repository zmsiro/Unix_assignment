# UNIX Assignment – SNP Processing Pipeline

## Data Inspection

### Attributes of fang_et_al_genotypes.txt

# --- Code snippet used for data inspection ---
```bash
# Check file size
ls -lh fang_et_al_genotypes.txt

# Count number of rows
wc -l fang_et_al_genotypes.txt

# Count number of columns (tab-delimited)
awk -F $'\t' '{print NF; exit}' fang_et_al_genotypes.txt

# View first three metadata columns
head -n 1 fang_et_al_genotypes.txt | cut -f1-3

Observations:
By inspecting this file I learned that:
- The file is approximately 11 MB in size.
- It contains 2,783 rows and 986 columns.
- The first three columns are metadata: Sample_ID, JG_OTU, and Group.
- The remaining columns correspond to SNP genotype markers.
- Missing genotype values are encoded as ?/?.

Data inspection:
# Check file size
ls -lh snp_position.txt

# Count number of rows
wc -l snp_position.txt

# Count number of columns (tab-delimited)
awk -F $'\t' '{print NF; exit}' snp_position.txt

# View SNP ID, chromosome, and position columns
head -n 1 snp_position.txt | cut -f1-4

Observations from above:
By inspecting this file I learned that:
- The file contains 984 rows and 15 columns.
- The first column contains SNP identifiers.
- Chromosome information is stored in the third column.
- Nucleotide position information is stored in the fourth column.
- Some SNPs have unknown or multiple genomic positions.

Data processing:
# Run the full processing pipeline
bash process.sh

# Description:
This processing pipeline performs the following steps:
- Splits the genotype data into maize and teosinte groups based on the Group column.
- Transposes genotype tables so that SNPs become rows.
- Joins genotype data with SNP position information.
- Sorts SNPs by chromosome and genomic position.
- Produces per-chromosome genotype files for maize and teosinte in both increasing and decreasing order.
- Generates special files for SNPs with unknown and multiple genomic positions.

# Maize data
The maize data output includes:
- 10 files (chromosomes 1–10) sorted by increasing genomic position with missing data encoded as '?'
- 10 files (chromosomes 1–10) sorted by decreasing genomic position with missing data encoded as '-'
- 1 file containing SNPs with unknown genomic positions
- 1 file containing SNPs with multiple genomic positions

Output directories:
output/maize/
output/special/

# Teosinte data
The teosinte data output includes:
- 10 files (chromosomes 1–10) sorted by increasing genomic position with missing data encoded as '?'
- 10 files (chromosomes 1–10) sorted by decreasing genomic position with missing data encoded as '-'
- 1 file containing SNPs with unknown genomic positions
- 1 file containing SNPs with multiple genomic positions

Output directories:
output/teosinte/
output/special/

# Verifying output
# Count total number of output files
find output -type f | wc -l

# Expected output of 44 files
