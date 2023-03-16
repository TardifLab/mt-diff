#!/usr/bin/env python

import numpy as np
import amico
import pickle
import commit
import os
import shutil
import sys


path_analysis = '/data_/tardiflab/mwc'
os.chdir(path_analysis)


Subj_list = sys.argv[1:]


for subj in Subj_list:
	print("\n====Running subject ", sys.argv[0], subj)

	connectome_MToff_file = subj + '/COMMIT_BZ_prenorm/tracking/Results_StickZeppelinBall/COMMIT_connectomes/mitX_filtered_connectome_sumXbyL_over_meanL.csv'
	connectome_MTon_file = subj + '/COMMIT_BZ_MT_on_prenorm/tracking/Results_StickZeppelinBall/COMMIT_connectomes/mitX_filtered_connectome_sumXbyL_over_meanL.csv'

	connectome_MToff = np.genfromtxt(connectome_MToff_file,delimiter=',')
	connectome_MTon = np.genfromtxt(connectome_MTon_file,delimiter=',')
	
	connectome_MTR1 = 1 - ( connectome_MTon/connectome_MToff )

	np.nan_to_num(connectome_MTR1, copy=False, nan=0.0, posinf=0, neginf=0)

    #diff=(connectome_MToff-connectome_MTon)
	#out_file ='/tmp/blach'+ subj
	out_file = subj + '/COMMIT_BZ_prenorm/tracking/Results_StickZeppelinBall/COMMIT_connectomes/mitX_filtered_connectome_COMMIT.csv'
	np.savetxt(out_file,connectome_MTR1 , fmt="%.5f", delimiter=",")
	print("\n===DONE",sys.argv)
