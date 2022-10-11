#!/usr/bin/env python

import os
import numpy as np
import nibabel as nib
import sys

path_analysis = '/data_/tardiflab/mwc'
os.chdir(path_analysis)

#Subj_list = ['hc21r']
Subj_list = sys.argv[1:]

for subj in Subj_list:

    print ("==Processing subject ", sys.argv[0], subj)
    os.chdir(os.path.join(path_analysis, subj, 'Diffusion'))

    cmd = 'fslroi dwi_preproc_B1corr_upsampl.nii.gz b0_MT_off 0 1'
    os.system(cmd)

    cmd = 'fslroi dwi_preproc_B1corr_upsampl_MT_on.nii.gz b0_MT_on 0 1'
    os.system(cmd)

    cmd = 'fslmaths b0_MT_off -sub b0_MT_on -div b0_MT_off MTR'
    os.system(cmd)

    cmd = 'rm b0_MT_off.nii.gz'
    os.system(cmd)

    cmd = 'rm b0_MT_on.nii.gz'
    os.system(cmd)


    path_subj = path_analysis + '/' + subj + '/COMMIT_BZ/tracking/Results_StickZeppelinBall'
    os.chdir(path_subj)
    print(path_subj)

    print ("---Creating tractometry to compare, MTR.nii.gz is located in path_analysis\n")
    # Creating tractometry to compare, MTR.nii.gz is located in path_analysis
    cmd = 'tcksample mitX_filtered.tck ../../../Diffusion/MTR.nii.gz COMMIT_connectomes/mitX_filtered_tractometry.txt -stat_tck mean' 

    #
    os.system(cmd)

    cmd = 'tck2connectome mitX_filtered.tck ../../../Diffusion/Connectome/nodes_fixSGM_tob0.nii.gz ./COMMIT_connectomes/mitX_filtered_connectome_tractometry.csv -scale_file ./COMMIT_connectomes/mitX_filtered_tractometry.txt -stat_edge mean -symmetric'
    os.system(cmd)


    # Creating txt to color code the streamlines
    print('\n ---Creating txt to color code the streamlines with tractometry')
    region_connected = np.loadtxt('COMMIT_connectomes/mitX_filtered_assignments.txt')   
    connectome_tractometry = np.loadtxt('COMMIT_connectomes/mitX_filtered_connectome_tractometry.csv',delimiter=',')
    connectome_COMMIT = np.loadtxt('COMMIT_connectomes/mitX_filtered_connectome_COMMIT.csv',delimiter=',')
    assignment_COMMIT =[]
    assignment_tractometry = []
    for ii in range(region_connected.shape[0]):
        assignment_COMMIT.append(connectome_COMMIT[ int(region_connected[ii,0]-1.0), int(region_connected[ii,1]-1.0) ] )
        assignment_tractometry.append(connectome_tractometry[ int(region_connected[ii,0]-1.0), int(region_connected[ii,1]-1.0) ] )

    np.savetxt('assignment_tractometry_color.txt', assignment_tractometry, fmt='%.16f', delimiter='\n')
    np.savetxt('assignment_COMMIT_color.txt', assignment_COMMIT, fmt='%.16f', delimiter='\n')


    # Splitting the bundles relative to FS parcelation in different files
    print("\n---Splitting the bundles relative to FS parcelation in different files\n")
    os.mkdir('connect2tck_COMMIT')
    print("connectome2tck -nthreads 8 -tck_weights_in assignment_COMMIT_color.txt -prefix_tck_weights_out connect2tck_COMMIT/bundles_ mitX_filtered.tck COMMIT_connectomes/mitX_filtered_assignments.txt connect2tck_COMMIT/bundle -keep_self")
    cmd = 'connectome2tck -nthreads 8 -tck_weights_in assignment_COMMIT_color.txt -prefix_tck_weights_out connect2tck_COMMIT/bundles_ mitX_filtered.tck COMMIT_connectomes/mitX_filtered_assignments.txt connect2tck_COMMIT/bundle -keep_self'
    os.system(cmd)

    os.mkdir('connect2tck_tractometry')
    print("connectome2tck -nthreads 8 -tck_weights_in assignment_tractometry_color.txt -prefix_tck_weights_out connect2tck_tractometry/bundles_ mitX_filtered.tck COMMIT_connectomes/mitX_filtered_assignments.txt connect2tck_tractometry/bundle -keep_self")
    cmd = 'connectome2tck -nthreads 8 -tck_weights_in assignment_tractometry_color.txt -prefix_tck_weights_out connect2tck_tractometry/bundles_ mitX_filtered.tck COMMIT_connectomes/mitX_filtered_assignments.txt connect2tck_tractometry/bundle -keep_self'
    os.system(cmd)

print("\n===DONE",sys.argv)
