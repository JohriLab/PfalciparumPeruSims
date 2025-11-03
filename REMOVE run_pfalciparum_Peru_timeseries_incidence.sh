#!/bin/bash
#SBATCH --mail-user=pjohri@unc.edu
#SBATCH --mail-type=ALL
#SBATCH -p general
#SBATCH -n 1
#SBATCH --time=0-0:20
#SBATCH --mem=20m
#SBATCH -a 1-1000%500
#SBATCH -o /proj/johrilab/projects/PfalPeruSims/LOGFILES/PeruSims_%A_rep%a.out
#SBATCH -e /proj/johrilab/projects/PfalPeruSims/LOGFILES/PeruSims_%A_rep%a.err
#SBATCH --job-name=pfalPeruSim

echo "SLURM_JOBID:         $SLURM_JOBID"
echo "SLURM_ARRAY_TASK_ID: $SLURM_ARRAY_TASK_ID"
echo "SLURM_ARRAY_JOB_ID:  $SLURM_ARRAY_JOB_ID"

# Set replicate ID based on task ID
repID=$SLURM_ARRAY_TASK_ID

# Path to Singularity image
SIF_PATH="/proj/johrilab/projects/yChrom/slim_5/slim_v5.0.sif"

# Directories to bind inside the container
BIND_DIRS="/proj/johrilab/projects/PfalPeruSims"

# Move to the directory with SLiM scripts
cd /proj/johrilab/projects/PfalPeruSims/programs || { echo "Cannot find programs directory"; exit 1; }

# Confirm SLiM is accessible in container
echo "Testing SLiM binary inside container:"
singularity exec "$SIF_PATH" which slim
singularity exec "$SIF_PATH" echo $PATH

# Run simulation
echo "Starting simulation $repID"
singularity exec \
  --bind "$BIND_DIRS" \
  "$SIF_PATH" \
  slim \
  -d "d_folder='/proj/johrilab/projects/PfalPeruSims/simulations_incidence'" \
  -d "d_repID=${repID}" \
  pfalciparum_Peru_timeseries_incidence.slim

echo "Finished simulation $repID"

