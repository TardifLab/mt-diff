#!/usr/bin/env python

import os
import numpy as np
import sys

## NB change these files name/path
path_analysis = '/data_/tardiflab/mwc'
COMMIT_type = 'COMMIT_BZ_prenorm'
COMMIT_type_on = 'COMMIT_BZ_MT_on_prenorm'
# Subj_list = ['S04', 'S07', 'S08', 'S09']
#Subj_list = ['hc24r']
Subj_list = sys.argv[1:]

for subj in Subj_list:

    print("==Running subject ", subj)
    subj_path = os.path.join(path_analysis,subj,COMMIT_type)
    #path_registration = '/media/diffusion/Volume/Pietro/COMMIT/for-simona/validation'
    input_tck = 'iFOD2_ACT_3M_hcp_connecting.tck'
    nodes_file = os.path.join(path_analysis, subj, 'Diffusion', 'Connectome', 'nodes_fixSGM_tob0.nii.gz')


    os.chdir(os.path.join(subj_path, 'tracking', 'Results_StickZeppelinBall'))
    # os.chdir('Results_StickZeppelinBall')

    # treshold the MToff and MTon weights at the same time, remove spurious fomr both
    print("--Thresholding MTon and MToff weights jointly\n")
    weights_off = np.loadtxt('streamline_weights.txt')
    weights_on = np.loadtxt(os.path.join(path_analysis,subj,COMMIT_type_on,'tracking', 'Results_StickZeppelinBall','streamline_weights.txt'))
    #mtr = 1 - weights_on/weights_off
    #np.nan_to_num(mtr, copy=False, nan=0.0, posinf=0, neginf=0)
    #mtr[mtr < 0.01] = 0
    #mtr[mtr > 0.99] = 0
    unusable = (weights_off <= 0.000000000001) | (weights_on <= 0.000000000001)
    weights_off[unusable] = 0
    weights_on[unusable] = 0
    np.savetxt('streamline_weights-thresh.txt', weights_off, fmt='%.16f', delimiter='\n')
    np.savetxt(os.path.join(path_analysis,subj,COMMIT_type_on,'tracking', 'Results_StickZeppelinBall','streamline_weights-thresh.txt'), weights_on, fmt='%.16f', delimiter='\n')

    cmd = 'tckedit -minweight 0.000000000001 -tck_weights_in ' + 'streamline_weights-thresh.txt' + ' -tck_weights_out ' + 'mitX_filtered.txt' + ' ' + os.path.join(path_analysis,subj,'Diffusion','Tractography','iFOD2_ACT_3M_hcp_connecting.tck') + ' ' +  'mitX_filtered.tck'
    print(cmd)
    os.system(cmd)

    if not os.path.exists('COMMIT_connectomes'):
        os.mkdir('COMMIT_connectomes')

    print('-- Mapping back to connectome--\n') 
    cmd = 'tck2connectome -symmetric ' + 'mitX_filtered.tck' + ' -out_assignments ' + os.path.join('COMMIT_connectomes', 'mitX_filtered_assignments.txt') + ' ' + os.path.join(path_analysis, subj,'Diffusion','Connectome','nodes_fixSGM_tob0.nii.gz') + ' ' + os.path.join('COMMIT_connectomes','mitX_filtered_connectome.csv')
    os.system(cmd)

    print("--Computing the length of each streamline\n")
    # computing the lenght of each streamline and saving it in a file
    cmd = 'tckstats mitX_filtered.tck -dump mitX_filtered_length.txt'
    os.system(cmd)

    # computing the connectome mean(lenghts)
    cmd = 'tck2connectome mitX_filtered.tck ' + nodes_file + ' ' + os.path.join('COMMIT_connectomes','mitX_filtered_connectome_meanL.csv') + ' -scale_file mitX_filtered_length.txt -stat_edge mean -symmetric'
    os.system(cmd)

    # creating the file containing per each streamline the results of x*L and saving it 
    mitX_filtered = np.loadtxt('mitX_filtered.txt')
    mitX_filtered_length = np.loadtxt('mitX_filtered_length.txt')
    mitX_filtered_XbyL = np.multiply(mitX_filtered,mitX_filtered_length)

    np.savetxt('mitX_filtered_XbyL.txt', mitX_filtered_XbyL, fmt='%.16f', delimiter='\n')

    print("--Creating the connectome sum(x_i*L_i)\n")
    # creating the connectome sum(x_i*L_i)
    cmd = 'tck2connectome mitX_filtered.tck ' + nodes_file + ' ' + os.path.join('COMMIT_connectomes','mitX_filtered_connectome_sumXbyL.csv') + ' -scale_file mitX_filtered_XbyL.txt -stat_edge sum -symmetric'
    os.system(cmd)

    # Creating the connectome sum(x*L)/mean(L)
    connectome_sumXbyL = np.loadtxt('COMMIT_connectomes/mitX_filtered_connectome_sumXbyL.csv', delimiter=',')
    connectome_meanL = np.loadtxt('COMMIT_connectomes/mitX_filtered_connectome_meanL.csv', delimiter=',')

    connectome_sumXbyL_over_meanL = connectome_sumXbyL/connectome_meanL
    connectome_sumXbyL_over_meanL[connectome_meanL==0]=0
    np.savetxt('COMMIT_connectomes/mitX_filtered_connectome_sumXbyL_over_meanL.csv', connectome_sumXbyL_over_meanL, fmt='%.16f', delimiter=',')

    print("--Creating the connectome sum x\n")
    # Creating the connectome sum x
    cmd = 'tck2connectome mitX_filtered.tck ' + nodes_file + ' ' + os.path.join('COMMIT_connectomes','connectome_sumX.csv') + ' -scale_file ' + os.path.join('.','mitX_filtered.txt') + ' -stat_edge sum -symmetric'
    os.system(cmd)

print("===DONE===",sys.argv)
