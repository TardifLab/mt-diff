#!/usr/bin/env python
### Gets list of bundle values
###
##########################################################
##########################################################
## usage: get_bundle_vals_csv -dir [all subjs in dir] -bundle [list of bundles] -log [name of logfile]
##			
#### dirs: list of subject directories (e.g. "hc21,hc22")
###  bundle : list of bundle patterns (e.g. "35-85, 36-85")
#### logfile : logfile name to record subject name and average + variance in each roi
####
###########################################
#### July25 2022
## This version reads in the connectomes rather than wait for the assigments on bundles
## Writing to the bundles takes a lot of I/O time
##   COMMIT_connectomes/mitX_filtered_connectome_COMMIT.csv

import os
import numpy as np
import nibabel as nib
import sys
import argparse
import csv
import pandas as pd

parser = argparse.ArgumentParser(description='')
parser.add_argument('--dirs', nargs='+', dest='dirs', help='list of subject directories e.g. hc20 hc20r')
parser.add_argument('--bundles' , nargs='+', dest='bundles', help='list of bundles e.g. 35,85 23,85')
parser.add_argument('--log', nargs=1, dest='log', help='output file with list of values')

myargs = parser.parse_args()

path_analysis = '/data_/tardiflab/mwc'
os.chdir(path_analysis)

dirs = myargs.dirs
bundles = myargs.bundles
log = myargs.log[0]

# We have 3 analysis on connectomes
# COMMIT MTR: eg hc21/COMMIT_BZ/tracking/Results_StickZeppelinBall/COMMIT_connectomes/mitX_filtered_connectome_COMMIT.csv
# Tractometry MTR with b=0: eg hc21/COMMIT_BZ/tracking/Results_StickZeppelinBall/COMMIT_connectomes/mitX_filtered_connectome_tractometry.csv
# Tractometry MTR with dw only:eg hc21/COMMIT_BZ/tracking/Results_StickZeppelinBall/COMMIT_connectomes/mitX_filtered_connectome_tractometry-nob0.csv

# open the file in the write mode
with open(log, 'w') as out:
  # create the csv writer
  writer = csv.writer(out)

  # write a row to the csv file
  writer.writerow(['SUBJ','bundle','COMMIT','tracto_b0', 'tracto_dw'])
  for subj in dirs:
    commit_cvs = subj+'/COMMIT_BZ/tracking/Results_StickZeppelinBall/COMMIT_connectomes/mitX_filtered_connectome_COMMIT.csv'
    tracto_b0_cvs = subj+'/COMMIT_BZ/tracking/Results_StickZeppelinBall/COMMIT_connectomes/mitX_filtered_connectome_tractometry.csv'
    tracto_dw_cvs = subj+'/COMMIT_BZ/tracking/Results_StickZeppelinBall/COMMIT_connectomes/mitX_filtered_connectome_tractometry-nob0.csv'
          
    for b in bundles:   
      idx=b.split(',')

      vals1=pd.read_csv(commit_cvs, sep=',',header=None)
      c=vals1.values
      commit=c[int(idx[0])-1,int(idx[1])-1] #the bundles are numbered 1-85, convert to index
  
      vals2=pd.read_csv(tracto_b0_cvs, sep=',',header=None)
      b0=vals2.values
      tractoB0=b0[int(idx[0])-1,int(idx[1])-1] #the bundles are numbered 1-85, convert to index
      
      vals3=pd.read_csv(tracto_dw_cvs, sep=',',header=None)
      dw=vals3.values
      tractoDW=dw[int(idx[0])-1,int(idx[1])-1] #the bundles are numbered 1-85, convert to index
    

      #writer.writerow([subj,b,c,cb,cd])
      writer.writerow([subj,b,commit,tractoB0,tractoDW])


def main(dirs, bundles):
    print('hello')
    print(dirs)
#os.path.join(path_analysis, subj, 'Diffusion'))
