# mt-diff
Processing of dual encoded magnetization and diffusion data, from pre-processsing to connectomes. Manuscript available on arxiv:https://arxiv.org/abs/2303.03449

## Acquisition
This analysis requires data from a custom dual-encoded magnetization-transfer and diffusion-weigthed sequence (Leppert et al. ,ISMRM 2022, Abstract #1044). Available for Siemens software version VE11c.
The pipeline expects consists of 2 datasets, one with and one without MT saturation.

## Dependencies
- MRTrix3 https://www.mrtrix.org/
- MRtrix3Tissue https://3tissue.github.io/
- afni https://afni.nimh.nih.gov/
- ANTs https://github.com/ANTsX/ANTs/wiki/ANTS-and-antsRegistration
- FreeSurfer https://github.com/freesurfer/freesurfer
- FSL https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation
- COMMIT https://github.com/daducci/COMMIT
  
## Pipeline
### Setup
Setup paths and dependencies

`init.sh`

### Preprocessing
- Anatomical segmentation with FreeSurfer
- Eddy current and distortion correction, as well and B1 bias correction of the diffusion

`aa2_preprocesssing_samebias.sh`

### Diffusion processing
- Compute fiber orientation distribution function
- Tractography
- Connectome

`bb1_Script_05_iPOF_ss3t_tractography_upsampling_as_ISMRM.sh`

### COMMIT processing
- Generate confidence map

`cc1_condfidence_map.sh`

- Setup environment

`dd1_enable_python_venv.sh`

- Apply COMMIT on MTon and MToff datasets

`dd2_COMMIT_MToff_as_ISMRM.py`

`dd3_COMMIT_MTon_as_ISMRM.py`

- Apply COMMIT results to MToff and MTon connectomes and compute MTR

`ee1_connectomes_MToff_jointFilter.py`

`ee2_connectomes_MTon_jointFilter.py`

`ff1_MTRconnectome.py`

- Map COMMIT results back onto tracts

`gg1_MTR_bundle.py`

`gg2_MTRdw_bundle.py`

## Data availability
Sample data is available through Dataverse (https://doi.org/10.5683/SP3/LNFHGO) or upon request through a formal data sharing agreement and approval from the local ethics committees.
	
The dataset contains the dual-encoded raw MT-weighted diffusion data and processed files for 1 subject. It also contains the MTR connectivity matrices (tract-specific and tractometry) for all 10 subjects (scan-rescan)

