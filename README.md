# TransdiagnosticConnectomeProject
Post-HCP processing code for the Transdiagnostic Connectome Project (TCP) dataset release, 2024

<hr>
<h1>About the TCP data release </h1>   

**Title**: The Transdiagnostic Connectome Project: a richly phenotyped open dataset for advancing the study of brain-behavior relationships in psychiatry

**Authors**:  
Sidhant Chopra<sup>$1,2</sup>, Carrisa V. Cocuzza<sup>$1,2</sup>, Connor Lawhead<sup>$1,3</sup>, Jocelyn A. Ricard<sup>1,4</sup>, Loïc Labache<sup>1,2</sup>, Lauren Patrick<sup>1,5</sup>, Poornima Kumar<sup>6,7</sup>, Arielle Rubenstein<sup>1</sup>, Julia Moses<sup>1</sup>, Lia Chen<sup>8</sup>, Crystal Blankenbaker<sup>9</sup>, Bryce Gillis<sup>10,11</sup>, Laura T. Germine<sup>10,11</sup>, Ilan Harpaz-Rote<sup>1,12,13</sup>, BT Thomas Yeo<sup>14-18</sup>, Justin T. Baker<sup>10,11</sup>, Avram J. Holmes<sup>1,2</sup>   

**Affiliations**:   
1.	Department of Psychology, Yale University, New Haven, CT, USA
2.	Department of Psychiatry, Brain Health Institute, Rutgers University, Piscataway, NJ, USA
3.	Department of Psychology, Stony Brook University, Stony Brook, NY, USA
4.	Stanford Neurosciences Interdepartmental Program, Stanford University School of Medicine, Stanford, CA, USA
5.	Lauren UPenn 
6.	Department of Psychiatry, Harvard Medical School, Boston, USA
7.	Centre for Depression, Anxiety and Stress Research, McLean Hospital, Boston, USA
8.	Department of Psychology, Cornell University, Ithaca, NY, USA
9.	(tba)
10.	Department of Psychiatry, Harvard Medical School, Boston, USA
11.	Institute for Technology in Psychiatry, McLean Hospital, Boston, USA
12.	Department of Psychiatry, Yale University, New Haven, USA 
13.	Wu Tsai Institute, Yale University, New Haven, USA
14.	Centre for Sleep and Cognition & Centre for Translational Magnetic Resonance Research, Yong Loo Lin School of Medicine, National University of Singapore, Singapore, Singapore
15.	Department of Electrical and Computer Engineering, National University of Singapore, Singapore, Singapore
16.	National Institute for Health & Institute for Digital Medicine, National University of Singapore, Singapore, Singapore
17.	Integrative Sciences and Engineering Programme (ISEP), National University of Singapore, Singapore, Singapore
18.	Martinos Center for Biomedical Imaging, Massachusetts General Hospital, Charlestown, USA

$ These authors contributed equally to this work.

**Abstract:**   
An important aim in psychiatry is the establishment of valid and reliable associations linking profiles of  brain functioning to clinically-relevant symptoms and behaviors across patient populations. To advance progress in this area, we introduce an open dataset containing behavioral and neuroimaging data from 244 individuals aged 18 to 70, including 149 meeting diagnostic criteria for a broad range of psychiatric illnesses and a healthy comparison group of 95 individuals. These data include high-resolution anatomical scans and multiple resting-state and task-based functional MRI runs. Additionally, participants completed over 50 psychological and cognitive assessments. Here, we detail available behavioral data as well as raw and processed analysis-ready MRI derivatives. Associations between data processing and quality metrics, such as head motion, are reported. Processed data exhibit classic task activation effects and canonical functional network organization. 

In doing so, we provide a comprehensive and analysis-ready transdiagnostic dataset which we hope  will contribute to the identification of illness-relevant biotypes, the establishment of brain-behavior associations, and progress in the development of personalized therapeutic interventions.

<hr>
<h1>About the repository:</h1>

1. /HolmesLab/TransdiagnosticConnectomeProject/docs/: documents, e.g., TCP manuscript, supplemental information, etc.
2. /HolmesLab/TransdiagnosticConnectomeProject/figures/: figures from the manuscript
3. /HolmesLab/TransdiagnosticConnectomeProject/scripts/: post-minimal-processing scripts, e.g., parcellation, functional connectivity (FC) estimation, global signal regression (GSR), framewise displacement (FD), etc.

<hr>
<h1>Supporting workflows and open source tools:</h1>

1. HCP minimal processing: https://github.com/Washington-University/HCPpipelines
2. Brain network metrics (python): https://github.com/aestrivex/bctpy
3. Cortical parcellation atlas: https://github.com/ThomasYeoLab/CBIG/tree/master/stable_projects/brain_parcellation/Yan2023_homotopic
4. Subcortical parcellation atlas: https://github.com/yetianmed/subcortex
5. Cerebellar parcellation atlas: https://github.com/DiedrichsenLab/cerebellar_atlases

<hr>
