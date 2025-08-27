# CBioPortal_Slurm
Running entire CBioPortal importing pipeline using SLURM

3 Part Pipeline:

1. Preprocessing: This step involves changing sample name and variant annotation using VEP. Outputs VCF files.
2. MAF Generation: Finally, the annotated variants are converted into MAF (Mutation Annotation Format) files for downstream analysis. Outputs MAF files.
3. Metadata and Clinical Data Generation: This step generates the necessary metadata, clinical data and case lists files required for CBioPortal upload. Outputs final study directory.

<br><br>

# Setting Up Local Instance

To set up a local instance of cBioPortal, you will need to have Docker and Docker Compose installed on your machine. Then follow the steps.

```bash
git clone https://github.com/cBioPortal/cbioportal-docker-compose.git

./init.sh
docker compose up
```
If you are using an older version of docker compose use `docker-compose up` instead.

After this cBioPortal should be running in http://localhost:8080. Do not close the terminal.

<br><br>

# Importing Project to Local Instance of cBioPortal
To import your project into the local instance of cBioPortal, you can use the `metaImport.py` script found in the docker image. Then the script has to be executed within the container environment. Ensure that your cBioPortal instance is running before executing the import command.

```bash
# First, go to the cbioportal-docker-compose directory
cd cbioportal-docker-compose

# Then, run the metaImport.py script with the appropriate parameters
docker-compose run cbioportal metaImport.py -u http://cbioportal:8080 -s /path/to/study --html /path/to/report.html -v -o

# Note that your study has to be copied into the cbioportal-docker-compose/study/ directory. This is because your local files are not accessible within the Docker container.
```
- -u: URL of the cBioPortal instance
- -s: Path to the study directory to import
- -html: Path to save the HTML report
- -v: Verbose output
- -o: Override warnings
- -h: Show help message

After this refresh your cBioPortal instance in the browser. You should see your project listed there. The report file will show any validation errors or warnings found during the import process.


## Common Issues
Missing Perl module:
```bash
conda install -y -c conda-forge perl-app-cpanminus
cpanm List::MoreUtils
```
Setting Locale failed:
```bash
export LANG=C
export LC_ALL=C
```