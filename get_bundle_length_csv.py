#!/usr/bin/env python
### Gets length of bundles
###
##########################################################
##########################################################
## usage: get_bundle_length_csv -dir [all subjs in dir] -bundle [list of bundles] -log [name of logfile]
##			
#### dirs: list of subject directories (e.g. "hc21,hc22")
###  bundle : list of bundle patterns (e.g. "35-85, 36-85")
#### logfile : logfile name to record subject name and average + variance in each roi
####
###########################################
#### Aug 25 2022
## This verison gets the average bundle length

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


# open the file in the write mode
with open(log, 'w') as out:
  # create the csv writer
  writer = csv.writer(out)

  # write a row to the csv file
  writer.writerow(['SUBJ','bundle','COMMIT'])
  for subj in dirs:
    commit_cvs = subj+'/COMMIT_BZ/tracking/Results_StickZeppelinBall/COMMIT_connectomes/mitX_filtered_connectome_meanL.csv'
          
    for b in bundles:   
      idx=b.split(',')

      vals1=pd.read_csv(commit_cvs, sep=',',header=None)
      c=vals1.values
      commit=c[int(idx[0])-1,int(idx[1])-1] #the bundles are numbered 1-85, convert to index
  
      
      #writer.writerow([subj,b,c,cb,cd])
      writer.writerow([subj,b,commit])


def main(dirs, bundles):
    print('hello')
    print(dirs)
#os.path.join(path_analysis, subj, 'Diffusion'))
