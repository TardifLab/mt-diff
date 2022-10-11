#!/usr/bin/env python
### Gets list of bundle values
###
##########################################################
##########################################################
## usage: get_bundle_vals -dir [all subjs in dir] -bundle [list of bundles] -log [name of logfile]
##			
#### dirs: list of subject directories (e.g. "hc21,hc22")
###  bundle : list of bundle patterns (e.g. "35-85, 36-85")
#### logfile : logfile name to record subject name and average + variance in each roi
####
###########################################


import os
import numpy as np
import nibabel as nib
import sys
import argparse
import csv


parser = argparse.ArgumentParser(description='')
parser.add_argument('--dirs', nargs='+', dest='dirs', help='list of subject directories e.g. hc20 hc20r')
parser.add_argument('--bundles' , nargs='+', dest='bundles', help='list of bundles e.g. 35-85 23-85')
parser.add_argument('--log', nargs=1, dest='log', help='output file with list of values')

myargs = parser.parse_args()

path_analysis = '/data_/tardiflab/mwc'
os.chdir(path_analysis)

dirs = myargs.dirs
bundles = myargs.bundles
log = myargs.log[0]

# We have 3 analysis on coonectomes
# COMMIT MTR: eg hc21/COMMIT_BZ/tracking/Results_StickZeppelinBall/connect2tck_COMMIT/bundles_23-85.csv
# Tractometry MTR with b=0: eg hc21/COMMIT_BZ/tracking/Results_StickZeppelinBall/connect2tck_tractometry/bundles_23-85.csv
# Tractometry MTR with dw only:eg hc21/COMMIT_BZ/tracking/Results_StickZeppelinBall/connect2tck_tractometry-nob0/bundles_23-85.csv

# open the file in the write mode
with open(log, 'w') as out:
  # create the csv writer
  writer = csv.writer(out)

  # write a row to the csv file
  writer.writerow(['SUBJ','bundle','COMMIT','tracto_b0', 'tracto_dw'])
  for subj in dirs:
      for b in bundles:
          
          commit = subj+'/COMMIT_BZ/tracking/Results_StickZeppelinBall/connect2tck_COMMIT/bundles_' + b + '.csv'
          tracto_b0 = subj+'/COMMIT_BZ/tracking/Results_StickZeppelinBall/connect2tck_tractometry/bundles_' + b + '.csv'
          tracto_dw = subj+'/COMMIT_BZ/tracking/Results_StickZeppelinBall/connect2tck_tractometry-nob0/bundles_' + b + '.csv'
          
          with open(commit) as f:
              c = f.readline().rstrip()
              #print("subj, bundle, commit:",subj, b, c)
          #with open(tracto_b0) as f:
          #    cb = f.readline().rstrip()
              #print("tracto_b0:",cb)
          #with open(tracto_dw) as f:
          #    cd = f.readline().rstrip()
              #print("tracto_dw:",cd)


          #writer.writerow([subj,b,c,cb,cd])
          writer.writerow([subj,b,c])



            

def main(dirs, bundles):
    print('hello')
    print(dirs)
#os.path.join(path_analysis, subj, 'Diffusion'))
