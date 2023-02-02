#!/usr/bin/env python

import os
import numpy as np
import nibabel as nib
import sys
## This scripts does tractometry on the average diffusion-weighted MTR

path_analysis = '/data_/tardiflab/mwc'
os.chdir(path_analysis)

#Subj_list = ['hc21r']
Subj_list = sys.argv[1:]


for subj in Subj_list:

    print("\n====Running subject ", subj,sys.argv)
    os.chdir(os.path.join(path_analysis, subj, 'Diffusion'))

    print("mrconvert -coord 3 1:end dwi_preproc_B1corr_upsampl.nii.gz - | mrmath - mean MToff-nob0-mean.nii.gz -axis 3\n")
    if not os.path.exists("MToff-nob0-mean.nii.gz"):
        cmd = 'mrconvert -coord 3 1:end dwi_preproc_B1corr_upsampl.nii.gz - | mrmath - mean MToff-nob0-mean.nii.gz -axis 3'
        os.system(cmd)

    print ("mrconvert -coord 3 1:end dwi_preproc_B1corr_upsampl_MT_on.nii.gz - | mrmath - mean MTon-nob0-mean.nii.gz -axis 3\n")
    if not os.path.exists("MTon-nob0-mean.nii.gz"):
        cmd = 'mrconvert -coord 3 1:end dwi_preproc_B1corr_upsampl_MT_on.nii.gz - | mrmath - mean MTon-nob0-mean.nii.gz -axis 3'
        os.system(cmd)

    cmd = 'mrcalc MToff-nob0-mean.nii.gz MTon-nob0-mean.nii.gz -sub MToff-nob0-mean.nii.gz -div - | mrcalc - -finite - -mult mtr-nobzeros.nii.gz'
    os.system(cmd)

    #cmd = 'rm MToff-nob0.nii'
    #os.system(cmd)

    #cmd = 'rm MTon-nob0.nii'
    #os.system(cmd)


    path_subj = path_analysis + '/' + subj + '/COMMIT_BZ/tracking/Results_StickZeppelinBall'
    os.chdir(path_subj)
    print(path_subj)

    # Creating tractometry to compare, mtr-nobzeros.nii is located in path_analysis
    print ("---Creating tractometry with MTRdw\n")
    # IRL take median, otherwise end up with Nan
    cmd = 'tcksample mitX_filtered.tck ../../../Diffusion/mtr-nobzeros.nii.gz COMMIT_connectomes/mitX_filtered_tractometry-nob0.txt -stat_tck median' 
    os.system(cmd)

    print ("---Back to connectome\n")
    cmd = 'tck2connectome mitX_filtered.tck ../../../Diffusion/Connectome/nodes_fixSGM_tob0.nii.gz ./COMMIT_connectomes/mitX_filtered_connectome_tractometry-nob0.csv -scale_file ./COMMIT_connectomes/mitX_filtered_tractometry-nob0.txt -stat_edge mean -symmetric'
    os.system(cmd)


    # Creating txt to color code the streamlines
    print('\n---Creating txt to color code the streamlines with tractometry')
    region_connected = np.loadtxt('COMMIT_connectomes/mitX_filtered_assignments.txt')   
    connectome_tractometry = np.loadtxt('COMMIT_connectomes/mitX_filtered_connectome_tractometry-nob0.csv',delimiter=',')
    assignment_tractometry = []
    for ii in range(region_connected.shape[0]):
        #assignment_COMMIT.append(connectome_COMMIT[ int(region_connected[ii,0]-1.0), int(region_connected[ii,1]-1.0) ] )
        assignment_tractometry.append(connectome_tractometry[ int(region_connected[ii,0]-1.0), int(region_connected[ii,1]-1.0) ] )

    np.savetxt('assignment_tractometry_color-nob0.txt', assignment_tractometry, fmt='%.16f', delimiter='\n')
    #np.savetxt('assignment_COMMIT_color.txt', assignment_COMMIT, fmt='%.16f', delimiter='\n')


    # Splitting the bundles relative to FS parcelation in different files

    #os.mkdir('connect2tck_COMMIT')
    #cmd = 'connectome2tck -tck_weights_in assignment_COMMIT_color.txt -prefix_tck_weights_out connect2tck_COMMIT/bundles_ mitX_filtered.tck COMMIT_connectomes/mitX_filtered_assignments.txt connect2tck_COMMIT/bundle -keep_self'
    #os.system(cmd)

    if not os.path.exists('connect2tck_tractometry-nob0'):
        os.mkdir('connect2tck_tractometry-nob0')

    print("\n---Splitting the bundles relative to FS parcelation in different files\n")
    cmd = 'connectome2tck -nthreads 8 -tck_weights_in assignment_tractometry_color-nob0.txt -prefix_tck_weights_out connect2tck_tractometry-nob0/bundles_ mitX_filtered.tck COMMIT_connectomes/mitX_filtered_assignments.txt connect2tck_tractometry-nob0/bundle -keep_self'
    os.system(cmd)

print("\n===DONE",sys.argv)
