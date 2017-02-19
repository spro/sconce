# Schema

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

# API

## Jobs

* `GET /jobs`
    * find jobs &rarr; [Job]
* `POST /jobs` &larr; $new_job
    * create job $new_job &rarr; Job
* `PUT /jobs/$job_id` &larr; $job_update
    * update job $job_id $job_update &rarr; Job
* `POST /jobs/$job_id/claim` &larr; $machine_id
    * claim job $job_id $machine_id &rarr; Assignment

## Machines

* `GET /machines`
    * find machines &rarr; [Machine]
* `POST /machines` &larr; $new_machine
    * create machine $new_machine &rarr; Machine
* `PUT /machines/$machine_id` &larr; $machine_update
    * update machine $machine_id $machine_update &rarr; Machine

## Assignments

* `GET /assignments`
    * find assignments &rarr; [Assignment]
* `PUT /assignments/$assignment_id` &larr; $assignment_update
    * update assignment $assignment_id $assignment_update &rarr; Assignment
* `POST /assignments/$assignment_id/points` &larr; $point
    * create point $assignment_id $point &rarr; Ok
* `POST /assignments/$assignment_id/results` &larr; $result
    * create result $assignment_id $result &rarr; Ok
