#!/usr/bin/env python

import numpy as np
import amico
import pickle
import commit
import os
import shutil
import sys


path_analysis = '/data_/tardiflab/mwc'
COMMIT_type = 'COMMIT_BZ_MT_on_prenorm'
dwi_file = 'dwi_preproc_B1corr_upsampl_MT_on_norm.nii.gz' #IRL dont' subsitute the b=0
os.chdir(path_analysis)

##Subj_list = ['S04', 'S07', 'S08', 'S09']
#Subj_list = ['hc23']
Subj_list = sys.argv[1:]

for subj in Subj_list:

    print("====Processing subject ", sys.argv[0], subj)
    path_COMMIT_subj = os.path.join(path_analysis, subj,COMMIT_type)

    if not os.path.exists(path_COMMIT_subj):
        os.mkdir(path_COMMIT_subj)

    print(' ')
    print(path_COMMIT_subj)


    # If you want to use zeppelin compartment
    ## print('\n Computing the peaks file\n ')
    # If you want to use zeppelin compartment
    ## cmd = 'sh2peaks ' + os.path.join(path_analysis,subj,'Tractography','FOD','WM_FODs.mif') + ' ' + path_COMMIT_subj + '/peaks.nii.gz -num 3'
    ## os.system(cmd)

    os.chdir(path_COMMIT_subj)
    
    if not os.path.exists("tracking/Results_StickZeppelinBall/streamline_weights.txt"):
        print('\n Remove Nan from input \n')
        orig = os.path.join(path_analysis,subj,'Diffusion',dwi_file)
        cmd = 'fslmaths '+ orig + ' -nan /tmp/mton.nii.gz'
        os.system(cmd)
        cmd = 'mv /tmp/mton.nii.gz ' + orig
        os.system(cmd)

        # Setting the input data
        from commit import trk2dictionary
        trk2dictionary.run(
            ndirs = 500,
            filename_tractogram   = os.path.join(path_analysis,subj,'Diffusion','Tractography','iFOD2_ACT_3M_hcp_connecting.tck'), # iFOD2_ACT_3M_hcp_connecting.tck PER LO SCRIPT ORIGINALE!
            filename_mask         = os.path.join(path_analysis,subj,'Diffusion','Tractography','T1_on_DTI','WM_mask_to_b0.nii.gz'),
            TCK_ref_image         = os.path.join(path_analysis,subj,'Diffusion',dwi_file),
            path_out              = 'tracking',
            fiber_shift           = 0.5,
            min_seg_len           = 1e-3#,
            ## filename_peaks        = 'peaks.nii.gz',#<-- only if I want to use also zeppelin
            ## peaks_use_affine      = True
        )

        commit.core.setup(ndirs=500)

        # Setting parameters
        print('\n Setting parameters \n') 
        mit = commit.Evaluation('.', '.')
        mit.set_config('doNormalizeSignal', False) #IRL don't normalize, pre-normalize by the MToff b=0
        mit.set_config('doMergeB0', False)
        mit.set_config('doNormalizeKernels', True)

        print('\n Creating the scheme file \n')    
        amico.util.fsl2scheme(os.path.join(path_analysis,subj,'Diffusion',"dwi_preproc.bvals"),os.path.join(path_analysis,subj,'Diffusion',"dwi_preproc.bvecs"),subj+"_scheme.txt")

        mit.load_data(os.path.join(path_analysis,subj,'Diffusion',dwi_file), subj + '_scheme.txt')
        # If you need to flip data
        #scheme = np.loadtxt(subj + '_dwi.scheme')
        #scheme_xflip = np.copy(scheme)
        #scheme_xflip[:,0] = -1.0*scheme_xflip[:,0]
        #np.savetxt(subj + '_dwi_BSZ.scheme_xflip', scheme_xflip,  fmt='%.16f')

        # Set model and generate the kernel
        print('\n Set model and generate the kernel \n')   
        mit.set_model( 'StickZeppelinBall' )
        d_par = 1.7E-3 # Parallel diffusivity [mm^2/s] for the streamline
        d_perp = 0.6E-3 # Perpendicular diffusivity [mm^2/s] for the streamline
        d_perps = [] # Perpendicular diffusivities [mm^2/s] for zeppelin in the voxel
        d_ISOs = [3.0E-3] # Isotropic diffusivitie(s) [mm^2/s]
        mit.model.set( d_par, d_perps, d_ISOs, d_perp=d_perp ) 
        mit.generate_kernels( ndirs=500, regenerate=True )
        mit.load_kernels()

        # Load dictionary and buid the operator
        print('\n Load dictionary and buid the operator \n')
        mit.load_dictionary( 'tracking' )
        
        mit.set_threads(8)
        mit.build_operator()
        
        # fitting
        print('\n Start fitting \n')
        mit.fit( tol_fun=1e-3, max_iter=1000, verbose=True, confidence_map_filename = os.path.join(path_analysis,subj,'Diffusion','confidence_map_3D.nii.gz'), confidence_map_rescale=False) 
        mit.save_results()
        mit.get_coeffs()
    
    print('\n COMMIT fitting done \n')
    # extracting non-zero streamlines
    # No, do this jointly with MToff in ee1
    #print('\n Extracting non-zero streamlines \n') 
    #cmd = 'tckedit -minweight 0.000000000001 -tck_weights_in ' + os.path.join('tracking','Results_StickZeppelinBall','streamline_weights.txt') + ' -tck_weights_out ' + os.path.join('tracking','Results_StickZeppelinBall','mitX_filtered.txt') + ' ' + os.path.join(path_analysis,subj,'Diffusion','Tractography','iFOD2_ACT_3M_hcp_connecting.tck') + ' ' + os.path.join('tracking','Results_StickZeppelinBall', 'mitX_filtered.tck')
    #os.system(cmd)

    #os.mkdir(os.path.join('tracking','Results_StickZeppelinBall','COMMIT_connectomes'))

    #print('\n Mapping back to connectome \n') 
    #cmd = 'tck2connectome -symmetric ' + os.path.join('tracking','Results_StickZeppelinBall','mitX_filtered.tck') + ' -out_assignments ' + os.path.join('tracking','Results_StickZeppelinBall', 'COMMIT_connectomes', 'mitX_filtered_assignments.txt') + ' ' + os.path.join(path_analysis, subj,'Diffusion','Connectome','nodes_fixSGM_tob0.nii.gz') + ' ' + os.path.join('tracking','Results_StickZeppelinBall','COMMIT_connectomes','mitX_filtered_connectome.csv')
    #os.system(cmd)

    #os.chdir(path_analysis)
    print("==Done==",sys.argv)
