# Working with nbgrader
## Quickstart upon reopening a stopped Gitpod workspace

```bash
# Open grading env (if not using base env)
conda activate graderenv

# Increase gitpod timeout setting
gp timeout set 6h

# Navigate to Assignments db location
cd nbgrader/Assignments

# Launch jupyter-lab
# Only use this for teaching or grading
jupyter lab --NotebookApp.allow_origin='*' --NotebookApp.allow_remote_access=True --NotebookApp.token='' --NotebookApp.password='' --no-browser --port=8888

# If using older nbgrader < v0.9.0, can use jupyter-notebook for creating assignment notebooks.
# nbgrader 0.8.5 has the good cell toolbars.
jupyter notebook --NotebookApp.allow_origin='*' --NotebookApp.allow_remote_access=True --NotebookApp.token='' --NotebookApp.password='' --no-browser --port=8888

```

**Note:** See other [gitpod settings](https://www.gitpod.io/docs/references/gitpod-cli#set) here.

## Installing nbgrader

```bash
# Create conda env from yml
conda env create -f nbgrader/environment.yml

# or create manually
conda create --name graderenv python=3.11
source activate graderenv
conda install -c conda-forge 'nbgrader>=0.8.1'
# Note: Check that you are using the latest versions of
# nbconvert
# jupyter-client

## Install Jupyter extensions
# Jupyter notebook
jupyter nbextension install --sys-prefix --py nbgrader
jupyter nbextension enable --sys-prefix --py nbgrader

# Optional extensions
# Jupyter Lab
jupyter labextension enable nbgrader
# Jupyter Server
jupyter serverextension enable --sys-prefix --py nbgrader

# Packages for Comp Gen Assignment 1 & 2 2024
#pip install numpy pandas seaborn matplotlib pysam biopython
#conda install blast bwa samtools
```

## Setting up Gitpod Environment

Notes on Gitpod setup:
- Added channels defaults, conda-forge, and bioconda
- pip installed nbgrader and all python deps (conda was too slow)
- conda installed non-python packages (blast bwa samtools)

```bash

# Create and activate an conda environment
conda env create -f nbgrader/Assignments/environment.yml

# Activate env
conda activate graderenv

# Activate nbgrader extensions
jupyter nbextension install --sys-prefix --py nbgrader
jupyter nbextension enable --sys-prefix --py nbgrader

# Only need these ones if using nbgrader with Jupyter Lab or Server
jupyter labextension enable nbgrader
jupyter serverextension enable --sys-prefix --py nbgrader

# Populate nbgrader student database (on first run only)
cd nbgrader/Assignments
nbgrader db student import ../students/students_2024.csv

# Create a config for jupyter notebook
jupyter notebook --generate-config 

# Add these lines:
'''
c.NotebookApp.allow_origin = '*'
c.NotebookApp.allow_remote_access = True
'''

# Open jupyter for grading
# Launch jupyter-lab
jupyter lab --NotebookApp.allow_origin='*' --NotebookApp.allow_remote_access=True --NotebookApp.token='' --NotebookApp.password='' --no-browser --port=8888

# or if using older nbgrader < v0.9.0, can use jupyter-notebook
jupyter notebook --NotebookApp.allow_origin='*' --NotebookApp.allow_remote_access=True --NotebookApp.token='' --NotebookApp.password='' --no-browser --port=8888

```

## Setting up nbgrader instance

Generate blank config file.

```bash
# Generate blank config file
nbgrader generate_config
```

Add the following line to the config file to create temp dirs as required:

``` Python
import tempfile
c.Exchange.root = tempfile.mkdtemp()
```

You may wish to edit some of the default timeout settings if you find student
solutions take too long to run.


To populate the student database import a csv with the format:

```
id,first_name,last_name
33145,John,Smith
26281,Jane,Doe
```

```bash
# Populate nbgrader student database
cd nbgrader/Assignments
nbgrader db student import ../students/students_2024.csv
```

Or manually add a student

```bash
#Manually create a student
nbgrader db student add --first-name=Adam --last-name=Taranto --email=adam.p.taranto@gmail.com --lms-user-id=U001 U001
```



Set up directory structure for assignment submissions.
Should be run in top level nbgrader dir that also contains "source" folder.


This code imports student IDs from a single column file.

```bash
cd nbgrader/Assignments
cat ../students/id_list_2024.csv | tr -d '\r' | while IFS=, read -r ID
do
    mkdir -p "submitted/${ID}/Assignment_1"
    mkdir -p "submitted/${ID}/Assignment_2"
    mkdir -p "submitted/${ID}/Assignment_3"
done
```

## Creating a new assignment

Configure a project
https://medium.com/analytics-vidhya/5-steps-to-auto-grade-your-jupyter-notebooks-nbgrader-simplified-4cbebf8943ef

```
# Edit the assignment notebook
jupyter notebook
# view --> cell toolbar --> create assignment
```

If updating an old assignment update metadata with 
```
nbgrader update . #from source dir
```

Note on Cell types:
https://nbgrader.readthedocs.io/en/stable/user_guide/creating_and_grading_assignments.html

Notes on writing tests:
https://nbgrader.readthedocs.io/en/stable/user_guide/autograding_resources.html
https://gist.github.com/psychemedia/27638941d7dd94a16a33ff632e0aee8b




## Generate & release assignment from within jupyter, or manually:

```
nbgrader generate_assignment Assignment_1
nbgrader release_assignment Assignment_1
```

## Grading an assignment

Student submissions should be located in the following path and have the
same name as the source assignment:

```
submitted/[STUDENT ID]/Assignment_1/Assignment_1.ipynb
```

Check submission metadata:
```
cd submitted
nbgrader update . #from submission dir
```


To bulk autograde submissions:

```bash
# Submissions must be in the student folders with generic Assignment name
# Bulk autograde
nbgrader autograde --assignment Assignment_1
nbgrader autograde --assignment Assignment_2
nbgrader autograde --assignment Assignment_3
nbgrader autograde --assignment Exam_B

#nbgrader autograde --force --assignment Assignment_3

```

If you need to amend any test in an assignment during marking:

```bash
# First edit the *source* notebook, then generate a new release:
nbgrader generate_assignment Assignment_1
nbgrader release_assignment Assignment_1
# The re-run autograding
nbgrader autograde --force --assignment Assignment_1
```

## Exporting grades

Export grades to CSV

```
nbgrader export --to grades/A1_grades_nbgrader.csv --assignment Assignment_1
nbgrader export --to grades/A2_grades_nbgrader.csv --assignment Assignment_2
nbgrader export --to grades/A3_grades_nbgrader.csv --assignment Assignment_3
nbgrader export --to grades/Exam_B_grades_nbgrader.csv --assignment Exam_B
```

### Custom export grades per question to CSV

You can use the custom exporter module gpqExporter to export grades per question.

```
# Note: In this case "--to" sets an output directory that individual assignment
# grade reports are written to.

nbgrader export --to grades --exporter=plugins.gpqexport.gpqExporter --assignment Assignment_1
nbgrader export --to grades --exporter=plugins.gpqexport.gpqExporter --assignment Assignment_2
nbgrader export --to grades --exporter=plugins.gpqexport.gpqExporter --assignment Assignment_3
nbgrader export --to grades --exporter=plugins.gpqexport.gpqExporter --assignment Exam_B

# Use --student to get grades for a specific student
nbgrader export --to grades --exporter=plugins.gpqexport.gpqExporter --assignment Assignment_1 --student 217020

```

Note: When formatting for Canvas, must use linux EOL characters


## Generating feedback

Create feedback dir with html reports

```
nbgrader generate_feedback "Assignment_1"
nbgrader generate_feedback "Assignment_2"
nbgrader generate_feedback "Assignment_3"
```

Generate feedback for one student:

```
nbgrader generate_feedback "Assignment_2" --student 188001
```


## Format feedback html reports

```bash
# Studentlist file format:
# ../students/students_2024.csv
# ID,FirstName,LastName

#cd nbgrader/Assignments

mkdir -p feedback/A1_feedback

OUTDIR="feedback/A1_feedback"
STUDENTLIST="../students/students_2024.csv"
ASSNAME="Assignment_1"

while IFS=',' read -r ID Fname Lname
do
  FILE="feedback/${ID}/${ASSNAME}/${ASSNAME}.html"
  if [ -f "$FILE" ]; then
    mv -f "${FILE}" "${OUTDIR}/${Fname}_${Lname}_feedback_${ASSNAME}.html" && \
    rm -rf "feedback/${ID}" && \
    echo "Moved: ${FILE}"
  else
    echo "File not found: ${FILE} Student: ${Fname} ${Lname}"
  fi
done < $STUDENTLIST

```
