# Working with nbgrader in Gitpod

## Quickstart upon reopening a stopped Gitpod workspace

```bash
# Increase gitpod timeout setting
gp timeout set 6h

# Launch Jupyter session in Assignment dir
gogo assignments
```

Or manually start Jupyter session to work on assignments

```bash
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

## Setting up new nbgrader Course in Gitpod

In this repo setup of the Gitpod workspace is handled via `.gitpod.yml` ans `.gitpod.Dockerfile`.

These config files do the following tasks:
- Add channels defaults, conda-forge, and bioconda
- pip install nbgrader and all python deps (conda was too slow)
- conda install non-python packages (blast bwa samtools)
- init the nbextensions
- alias 'gogo' launcher script

In this example we will create an nbgrader course called "Assignments"

```bash

# Create the course dir
mkdir -p nbgrader/Assignments

# Navigate to nbgrader course dir
cd nbgrader/Assignments

# Generate a blank nbgrader config file
nbgrader generate_config
```

After creating the `nbgrader_config.py` file you will need to edit the following settings.

```python
# Add these lines to nbgrader_config.py
# Manage root dir with tempfile module
import tempfile
c.Exchange.root = tempfile.mkdtemp()

# These settings make Jupyter play nice with Gitpod and can also be set when invoking Jupyter from the cmd line
c.NotebookApp.allow_origin = '*'
c.NotebookApp.allow_remote_access = True

# Update the course name (check that is variable is only set once)
c.CourseDirectory.course_id = 'COURSE_ID_2024'
```

```bash
# Populate nbgrader student database (on first run only)
nbgrader db student import ../students/students_2024.csv
# Where file student file format is:
#id,first_name,last_name
#123456,Testy,McTest
```

Open Jupyter for grading or assignment development:

```bash
# Launch jupyter-lab
jupyter lab --NotebookApp.allow_origin='*' --NotebookApp.allow_remote_access=True --NotebookApp.token='' --NotebookApp.password='' --no-browser --port=8888

# or if using older nbgrader < v0.9.0, can use jupyter-notebook (has a nicer interface)
jupyter notebook --NotebookApp.allow_origin='*' --NotebookApp.allow_remote_access=True --NotebookApp.token='' --NotebookApp.password='' --no-browser --port=8888

```

## Installing nbgrader locally

If you want to set up nbgrader in an env on your local computer (not in Gitpod), follow these instructions.

```bash
# Create conda env from yml
conda env create -f nbgrader/environment.yml

# or create manually
conda create --name graderenv python=3.11
source activate graderenv
conda install -c conda-forge 'nbgrader==0.8.5'
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
pip3 install -r requirements.txt
#pip install numpy pandas seaborn matplotlib pysam biopython
conda install -c bioconda blast bwa samtools
```

### Setting up local nbgrader instance

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
submitted/[STUDENT_ID]/Assignment_1/Assignment_1.ipynb
```

If you happen to be importing assignment submissions from UniMelb's Canvas LMS you can use the `nb_load` utility included in this template.

To use `nb_load` your raw submissions exported from canvas should be in one directory and have a name fortmat where the first run of numbers bounded by underscores corresponds to a student ID in your database.

Here is an example submission name:

```
# nb_load will extract 123456 as the student ID
submissions/mctesttesty_123456_19058741_Assignment_1.ipynb
```

To place this submission in its correct location for grading with nbgrader:

```bash
nb_load --submissions submissions --assignment Assignment_1 --idlist nbgrader/students/id_list_2024.csv
```

This command will move the example submission to the location:

```
nbgrader/Assignments/submitted/123456/Assignment_1/Assignment_1.ipynb
```

Before running the autograder you can check submission metadata:

```bash
cd nbgrader/Assignments/submitted
# This will test all notebooks below this level. 
# Note that this may include other submitted assignments.
nbgrader update . 
```


To bulk autograde submissions:

```bash
# Submission notebooks must be in the student folders and have a name matching the assignment source book
# Bulk autograde
nbgrader autograde --assignment Assignment_1
nbgrader autograde --assignment Assignment_2
nbgrader autograde --assignment Assignment_3
nbgrader autograde --assignment Exam_B

```

By default this will skipp any submissions that have already been graded.

If you need to amend any test cases in an assignment during marking, you must first edit the source notebook 
then generate a new release.

```bash
# First edit the *source* notebook, then generate a new release:
nbgrader generate_assignment Assignment_1
nbgrader release_assignment Assignment_1
```
To update the autograding results with the new tests run autograder with the `--force` option.

```bash 
# The re-run autograding
nbgrader autograde --force --assignment Assignment_1
```

## Exporting grades

Export grades to CSV  

Note: When formatting for Canvas, must use linux EOL characters

```bash
nbgrader export --to grades/A1_grades_nbgrader.csv --assignment Assignment_1
nbgrader export --to grades/A2_grades_nbgrader.csv --assignment Assignment_2
nbgrader export --to grades/A3_grades_nbgrader.csv --assignment Assignment_3
nbgrader export --to grades/Exam_B_grades_nbgrader.csv --assignment Exam_B
```

### Custom export grades per question to CSV

You can use the custom exporter module gpqExporter to export grades per question.

```bash 
# Note: In this case "--to" sets an output directory that individual assignment
# grade reports are written to.

nbgrader export --to grades --exporter=plugins.gpqexport.gpqExporter --assignment Assignment_1
nbgrader export --to grades --exporter=plugins.gpqexport.gpqExporter --assignment Assignment_2
nbgrader export --to grades --exporter=plugins.gpqexport.gpqExporter --assignment Assignment_3
nbgrader export --to grades --exporter=plugins.gpqexport.gpqExporter --assignment Exam_B

# Use --student to get grades for a specific student
nbgrader export --to grades --exporter=plugins.gpqexport.gpqExporter --assignment Assignment_1 --student 123456

```


## Generating feedback

Create feedback dir with html reports

```bash
nbgrader generate_feedback "Assignment_1"
nbgrader generate_feedback "Assignment_2"
nbgrader generate_feedback "Assignment_3"
```

Generate feedback for one student:

```bash
nbgrader generate_feedback "Assignment_2" --student 123456
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
