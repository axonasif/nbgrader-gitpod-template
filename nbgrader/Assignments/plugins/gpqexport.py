#Author: Adam Taranto 2022
import pathlib
from nbgrader.plugins import ExportPlugin
from nbgrader.api import Gradebook, MissingEntry


class gpqExporter(ExportPlugin):
    """
    Exports grades per questions for each assignment.
    Use: nbgrader export --exporter=plugins.gpqexport.gpqExporter
    """
    def export(self, gradebook: Gradebook) -> None:
        # Set output directory
        if self.to == "":
            dest = "grades"
        else:
            self.log.info('Warning: This custom exporter expects the "--to" '
                          'argument to refer to a directory where it will '
                          'write a separate csv for each assignment.')
            dest = self.to

        if len(self.student) == 0:
            allstudents = []
        else:
            # Make sure studentID(s) are a list of strings
            allstudents = [str(item) for item in self.student]

        if len(self.assignment) == 0:
            allassignments = []
        else:
            # Make sure assignment(s) are a list of strings
            allassignments = [str(item) for item in self.assignment]

        # Create path to output dir if does not exist
        pathlib.Path(dest).mkdir(parents=True, exist_ok=True)

        self.log.info("Exporting grades to %s", dest)

        if allassignments:
            self.log.info("Exporting only assignments: %s", allassignments)

        if allstudents:
            self.log.info("Exporting only students: %s", allstudents)

        # Loop over each assignment in the database
        for assignment in gradebook.assignments:

            # Only continue if assignment is required
            if allassignments and assignment.name not in allassignments:
                continue

            self.log.info("Exporting grades for: %s", assignment.name)

            # Check for notebooks belonging to assignment
            if len(assignment.notebooks) == 0:
                continue

            # Non-grade metadata to collect about submission
            tag_keys = [
                "assignment",
                "student_id",
                "first_name",
                "last_name",
                "timestamp",
                "needs_manual_grade",
            ]

            # Dict to collect names of graded cells per assignment notebook
            cells = {}
            # Dict to collect ordered list of graded cell names per assignment
            # notebook
            ordered_grade_cells = {}

            # For each notebook in an Assignment,
            # get names of grade/task cells and their max scores
            for notebook in assignment.notebooks:

                # Presumes notebooks within assignments have unique names
                # Add nested dict for current notebook
                cells[notebook.name] = {}
                # Add new list for current notebook
                ordered_grade_cells[notebook.name] = []

                # Get autograded cell names and max scores
                for cell in notebook.grade_cells:
                    cells[notebook.name][cell.name] = cell.max_score

                # Get manual task cell names and max scores
                for cell in notebook.task_cells:
                    cells[notebook.name][cell.name] = cell.max_score

                # Create combined list of grade_cells & task_cells
                # so that order matches question order in source notebook
                for cell in notebook.source_cells:
                    if cell.name in cells[notebook.name].keys():
                        ordered_grade_cells[notebook.name].append(cell.name)

            # Format grade cell names for headers with max score per Q
            # "cell_name ([max_score])"
            grade_headers = []

            for notebook in ordered_grade_cells.keys():
                for cell in ordered_grade_cells[notebook]:
                    grade_headers.append(cell +
                                         " (" +
                                         str(cells[notebook][cell]) +
                                         ")")

            # Make header list
            headers = tag_keys + grade_headers

            # Set output order for student data rows
            # Keys objects are ordered key lists to retrive from input dicts

            # Format metadata tags
            fmt_tags = ",".join(["{" + x + "}" for x in tag_keys])

            # Formating for scores for each notebook
            fmt_scores = {}
            for notebook in ordered_grade_cells.keys():
                # Get ordered list of grade cell names for each notebook
                grade_keys = ordered_grade_cells[notebook]
                fmt_scores[notebook] = ",".join(
                                                ["{" + x + "}" for x
                                                 in grade_keys]
                                                )

            # Open output CSV
            self.log.info('Writing grades to: %s/%s.csv',
                          dest, assignment.name)

            fh = open(dest + "/" + assignment.name + "_grades_per_q.csv", "w")

            # Write header row
            fh.write(",".join(headers) + "\n")

            # Loop over each student in the database
            for student in gradebook.students:

                # Only continue if student is required
                if allstudents and student.id not in allstudents:
                    continue
                tags = {}
                scores = {}
                tags['assignment'] = assignment.name
                tags['student_id'] = student.id
                tags['first_name'] = student.first_name
                tags['last_name'] = student.last_name
                # This loop only matters if notebook.grades is not same
                # as ordered_grade_cells set.
                for notebook in ordered_grade_cells.keys():
                    scores[notebook] = {}
                    # Get ordered list of grade cell names for each notebook
                    for cell in ordered_grade_cells[notebook]:
                        if cell in scores[notebook].keys():
                            self.log.info('Warning: Duplicate grade cell name:'
                                          ' %s in notebook %s',
                                          cell,
                                          notebook)
                        else:
                            # Populate null scores for each question
                            scores[notebook][cell] = None

                try:
                    submission = gradebook.find_submission(assignment.name,
                                                           student.id
                                                           )
                except MissingEntry:
                    # Note: May throw error if no student name assigned.
                    self.log.info('No %s submission found for student: '
                                  '%s, %s %s',
                                  assignment.name,
                                  student.id,
                                  student.first_name,
                                  student.last_name)
                    tags['needs_manual_grade'] = 'NA'
                    tags['timestamp'] = ''

                else:
                    # Log submission metadata
                    tags['needs_manual_grade'] = str(
                        submission.needs_manual_grade)
                    tags['timestamp'] = submission.timestamp

                    # Log grades for each notebook in submission
                    for notebook in submission.notebooks:
                        for grade in notebook.grades:
                            scores[notebook.name][grade.name] = grade.score

                # Convert empty keys and non-str values to strings for tags
                for key in tags:
                    if tags[key] is None:
                        tags[key] = ''
                    if not isinstance(tags[key], str):
                        tags[key] = str(tags[key])

                # Convert empty keys and non-str values to strings for scores
                for notebook in scores.keys():
                    for key in scores[notebook]:
                        if scores[notebook][key] is None:
                            scores[notebook][key] = ''
                        if not isinstance(scores[notebook][key], str):
                            scores[notebook][key] = str(scores[notebook][key])

                # Assemble ouput string for student
                # Add metadata tags to output string
                student_scores = fmt_tags.format(**tags)

                # Add grades for each notebook in assignment
                for notebook in ordered_grade_cells.keys():
                    student_scores = (student_scores +
                                      ',' +
                                      fmt_scores[notebook].format(
                                                            **scores[notebook]
                                                                 )
                                      )
                # Write the student output string to file
                fh.write(student_scores + "\n")

        fh.close()
