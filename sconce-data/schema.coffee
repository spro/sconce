module.exports =
    machines:
        _:
            jobs:
                reverse_id_key: 'machine_id'
                _:
                    program: {}

    programs:
        _:
            jobs:
                reverse_id_key: 'program_id'
                type: 'jobs'
                _:
                    machine: {}

    jobs:
        _:
            program: {}
            machine: {}
            points: {reverse_id_key: 'job_id'}
            logs: {reverse_id_key: 'job_id'}
            results: {reverse_id_key: 'job_id'}

    points: {}
    logs: {}
    results: {}
