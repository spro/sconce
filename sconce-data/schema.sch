Job
    name String
    params JSON
    hostname String
    points Point < job_id
    logs Log < job_id

Log
    body String

Point
    x Float
    y Float
