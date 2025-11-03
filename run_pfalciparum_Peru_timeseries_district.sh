#!/bin/bash
#SBATCH --mail-user=cobi@unc.edu
#SBATCH --mail-type=ALL
#SBATCH -p general
#SBATCH -n 1
#SBATCH --time=0-0:20
#SBATCH --mem=20m
#SBATCH -a 1-1000%500               # Runs 1000 array jobs, 500 at a time
#SBATCH -o /proj/johrilab/projects/PfalPeruSims/haploid/LOGFILES/PeruSims_%A_rep%a.out
#SBATCH -e /proj/johrilab/projects/PfalPeruSims/haploid/LOGFILES/PeruSims_%A_rep%a.err
#SBATCH --job-name=pfalPeruSim

# Environment 
module load slim/5.1

# SLURM metadata 
echo "SLURM_JOBID:         ${SLURM_JOBID:-none}"
echo "SLURM_ARRAY_TASK_ID: ${SLURM_ARRAY_TASK_ID:-none}"
echo "SLURM_ARRAY_JOB_ID:  ${SLURM_ARRAY_JOB_ID:-none}"

# Replicate ID
repID=${SLURM_ARRAY_TASK_ID:-1}

# Simulation parameters -- EDIT THESE TO CHANGE SELECTION COEFFICIENTS
SEL1="0.07"   # hrp2 selection coefficient
SEL2="0.07"   # hrp3 selection coefficient
SLIM_SCRIPT="pfalciparum_Peru_timeseries_district.slim"

# Directory structure
BASE_DIR="/proj/johrilab/projects/PfalPeruSims/haploid/simulations_district"
UNIQUE_FOLDER="hrp2_${SEL1}_hrp3_${SEL2}"
OUTPUT_FOLDER="${BASE_DIR}/${UNIQUE_FOLDER}"

# Create output directories 
mkdir -p "${OUTPUT_FOLDER}/haplotype_frequencies"

echo "Starting simulation ${repID} in ${OUTPUT_FOLDER}"
echo "Current working directory: $(pwd)"

# Run SLiM 
# (single line — prevents Bash from misinterpreting float values as commands)
slim -d "d_folder='${OUTPUT_FOLDER}'" -d "d_repID=${repID}" -d "d_f_sel_hrp2=${SEL1}" -d "d_f_sel_hrp3=${SEL2}" "${SLIM_SCRIPT}"

echo "Finished simulation ${repID}"

