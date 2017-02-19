# sconce

PyTorch runner for experiments in the cloud. Make good use of expensive server time by using a job queue system.

## Requirements

* Create a AWS EC2 instance
    * Install Anaconda 
        ```
        curl -LO https://repo.continuum.io/archive/Anaconda3-4.3.0-Linux-x86_64.sh
        bash Anaconda3-4.3.0-Linux-x86_64.sh
        ```
    * Install PyTorch
        ```
        conda install pytorch torchvision -c soumith
        ```
    * Create config for
        * Where to read jobs from (master panel?)
    * Download **sconce helper script** which will
        * Claim a job from a list when booted
        * Send results to a certain place when finished
        * Shut itself down
    * Create an image from this instance
    * Save the image ID with the master panel

## Master panel

* Create new jobs
* Lists jobs for workers to claim
* Allocate # of jobs to run at once?
* Set image ID to clone from

## Adding a job

* Write python project that uses sconce client library
    * Sconce library has common interface for running script with config json
    * Sconce config defines which variables are available to set
    * Sconce library also has helpers for posting real time progress and final results
* Zip up project, upload zipped project to control panel and set details
* Create individual jobs with configuration variables (similar to neural studio interface)
* Set a total # of 

## Worker management

* Workers signal when they start and finish jobs so the job distributer knows how many are working at one time
* There is a maximum quota of machines running at once to avoid costing too much
* If there are no jobs left for a certain amount of time, workers are turned off
* If there are jobs but no machines available it will start one up
    * Has to keep track of how many are in the process of starting

## Schema

* Machine
    * Host
    * Status [off, starting, idle, working, stopping]
* Job
    * Code
    * Variables
    * Assignments
* Assignment
    * Job
    * Machine
    * Variable values
    * Status [queued, working, finished]
    * Progress
    * Results
