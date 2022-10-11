#/bin/bash
#
# initializes dependencies & paths necessary to run micapipe & related functions
#
#
# 2021 Mark C Nelson, McConnell Brain Imaging Centre, MNI, McGill
#------------------------------------------------------------------------------------------------------------------------------------

# Save OLD PATH
 export OLD_PATH=$PATH

# Declare path vars for all necessary binaries
 export root_dir=/data_/tardiflab
 export softwareDir=${root_dir}/01_programs
 export mrtrixDir=${softwareDir}/mrtrix3
 export mrtrix3tissueDir=${softwareDir}/MRtrix3Tissue # DEFINE PATH TO MRTRIX3TISSUE
 export AFNIDIR=${softwareDir}/afni
 export ANTSPATH=${softwareDir}/ANTs/bin
 export workbench_path=${softwareDir}/workbench/bin_linux64
 export FSLDIR=${softwareDir}/fsl && source ${FSLDIR}/etc/fslconf/fsl.sh
# export FSLDIR=/export01/local/fsl && source ${FSLDIR}/etc/fslconf/fsl.sh

# MODIFY THE FOLLOWING LINES TO SWITCH BETWEEN FREESURFER 6 OR FREESURFER 7 VERSIONS
# export FREESURFER_HOME=${softwareDir}/freesurfer && source $FREESURFER_HOME/FreeSurferEnv.sh
 export FREESURFER_HOME=${softwareDir}/freesurfer_v7 && source $FREESURFER_HOME/FreeSurferEnv.sh

 export FIXPATH=${softwareDir}/fix				# make sure fix knows where to find mcr (see fix/settings.sh, set FSL_FIX_MCRROOT variable)
# export PYTHONPATH=${softwareDir}/anaconda3/bin
 export MATLABPATH=/usr/local/bin				# Matlaab dir may not be necesarry, ICAFIX uses Matlab Runtime Compiler (mcr)
# export RPATH=${softwareDir}/R-3.6.3
 export RPATH=/usr/lib/R/bin
export myBin=${softwareDir}/bin


# Export new PATH with all the necessary binaries. MODIFIED FOR MRTRIX3TISSUE.
 export PATH="${myBin}:${MATLABPATH}:${RPATH}/bin:${AFNIDIR}:${ANTSPATH}:${workbench_path}:${FREESURFER_HOME}/bin:/data_/tardiflab/01_programs/anaconda3/bin:${mrtrixDir}/bin:${mrtrixDir}/lib:${FSLDIR}/bin:${FIXPATH}:${PATH}:${mrtrix3tissueDir}/bin"





# Set the libraries paths for mrtrIx, fsl and freesurfer brainstem V. 6
 #export LD_LIBRARY_PATH="/tmp/tmp.Ua5KXXA3pk/install-target/v80/runtime/glnxa64:/tmp/tmp.Ua5KXXA3pk/install-target/v80/bin/glnxa64:/tmp/tmp.Ua5KXXA3pk/install-target/v80/sys/os/glnxa64:/tmp/tmp.Ua5KXXA3pk/install-target/v80/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/tmp/tmp.Ua5KXXA3pk/install-target/v80/sys/java/jre/glnxa64/jre/lib/amd64/server:/tmp/tmp.Ua5KXXA3pk/install-target/v80/sys/java/jre/glnxa64/jre/lib/amd64:${FSLDIR}/lib:${FSLDIR}/bin:${mrtrixDir}/lib:${RPATH}/lib"

# Set the libraries paths for mrtrIx, fsl and freesurfer brainstem V. 7
 export LD_LIBRARY_PATH="/tmp/tmp.UTqh4469rp/install-target/v84/runtime/glnxa64:/tmp/tmp.UTqh4469rp/install-target/v84/bin/glnxa64:/tmp/tmp.UTqh4469rp/install-target/v84/sys/os/glnxa64:${FSLDIR}/lib:${FSLDIR}/bin:${RPATH}/lib" #:/data_/tardiflab/01_programs/anaconda3/lib/" #${mrtrixDir}/lib:

# PER BRAINSTEM-STRUCTURES FS VERSIONE 6
#export XAPPLRESDIR="/tmp/tmp.Ua5KXXA3pk/install-target/v80/X11/app-defaults"

# PER BRAINSTEM-STRUCTURES FS VERSIONE 7
export XAPPLRESDIR="/tmp/tmp.UTqh4469rp/install-target/v84/X11/app-defaults"

# Append my R library  			*** (NOT TESTED) ***
myRLibs=${softwareDir}/Rlibs
#[[ ! -e $myRLibs ]] && mkdir $myRLibs
if [ -n "$R_LIBS" ]; then
    export R_LIBS=$myRLibs:$R_LIBS
else
    export R_LIBS=$myRLibs
fi

# Language utilities
 export LC_ALL=en_US.UTF-8
 export LANG=en_US.UTF-8

# Paths
 export micadir=${root_dir}/mnelson/myelinWeightedConnectome/micadata20-21
 export MICAPIPE=${micadir}/scripts/micapipe
 export OUT_DIR=${micadir}/procLocal/micapipe
 export RAW_DIR=${micadir}/rawdata
 export OUT_DIR2=${micadir}/procLocal/commit

 export pyvenv_commit=${root_dir}/mnelson/commit/env
 export scripts=${micadir}/scripts

# To run on cluster
 export SGE_ROOT=/opt/sge

# To run mrview in X2go
export LD_PRELOAD=/opt/nvidia/nsight-systems/2021.3.2/host-linux-x64/Mesa/libGL.so && /data_/tardiflab/01_programs/anaconda3/bin/mrview $image
