Machine
    name String
    host String
    jobs Job < machine_id

Program
    name String
    params JSON
    jobs Job < program_id

Job
    name String
    params JSON
    program Program > program_id
    machine Machine > machine_id
    points Point < job_id
    logs Log < job_id

Log
    body String

Point
    x Float
    y Float
