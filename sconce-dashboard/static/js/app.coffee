React = require 'react'
ReactDOM = require 'react-dom'
moment = require 'moment'
{Router, Link} = require 'zamba-router'
{ReloadableList} = require 'common-components'
{ValidatedForm} = require 'validated-form'
Dispatcher = require './dispatcher'
{Chart, LineChart} = require 'zamba-charts'
somata = require 'somata-socketio-client'
d3 = require 'd3'

color = d3.scaleOrdinal d3.schemeCategory10

if config.debug
    require './reload'

NewProgram = React.createClass
    createProgram: (program) ->
        @refs.form.setState {loading: true}
        Dispatcher.create 'programs', program
            .onValue =>
                @refs.form.setState @refs.form.getInitialState()

    render: ->
        <ValidatedForm
            ref='form'
            fields={
                name: {}
                description: {type: 'textarea', optional: true}
                params: {type: 'object', optional: true}
            }
            onSubmit=@createProgram
        />

NewJob = React.createClass
    createJob: (job) ->
        @refs.form.setState {loading: true}
        Dispatcher.create 'jobs', job
            .onValue =>
                @refs.form.setState @refs.form.getInitialState()

    render: ->
        <ValidatedForm
            ref='form'
            fields={
                program_id: {type: 'number'}
                machine_id: {type: 'number', optional: true}
                params: {type: 'object', optional: true}
            }
            onSubmit=@createJob
        />

NewMachine = React.createClass
    createMachine: (machine) ->
        @refs.form.setState {loading: true}
        Dispatcher.create 'machines', machine
            .onValue =>
                @refs.form.setState @refs.form.getInitialState()

    render: ->
        <ValidatedForm
            ref='form'
            fields={
                name: {}
                host: {}
            }
            onSubmit=@createMachine
        />

ProgramSummary = ({item}) ->
    <div className='item program-summary'>
        <h3 className='name'>{item.name}</h3>
        <pre className='params'>{JSON.stringify item.params, null, 4}</pre>
    </div>

JobLogs = React.createClass
    getInitialState: ->
        open: false
        logs: @props.job.logs or []

    componentDidMount: ->
        somata.subscribe$('sconce:engine', "jobs:#{@props.job.id}:logs")
            .onValue @addLog
        @fixScroll()
        setInterval @updateState, 5000

    updateState: -> @setState @state

    fixScroll: ->
        @refs.logs.scrollTop = @refs.logs.scrollHeight

    addLog: (log) ->
        @state.logs.push log
        @setState {}, @fixScroll

    toggleOpen: -> @setState {open: !@state.open}

    render: ->
        class_name = 'logs'
        if @state.open
            class_name += ' open'
        <div className=class_name ref='logs' onClick=@toggleOpen>
            {if @state.open
                @state.logs.map (log) ->
                    <div key=log.id>
                        <span>{log.log}</span>
                        <span className='t'>{moment(log.t).fromNow(true)}</span>
                    </div>
            else if log = @state.logs.slice(-1)[0]
                <div>
                    <span>{log.log}</span>
                    <span className='t'>{moment(log.t).fromNow(true)}</span>
                </div>
            }
        </div>

JobsCharts = React.createClass
    getInitialState: ->
        jobs: []

    componentDidMount: ->
        jobs$.onValue (jobs) =>
            jobs = jobs.filter (j) -> j.points?.length
            @setState {jobs}
            jobs.map (job) =>
                somata.subscribe$('sconce:engine', "jobs:#{job.id}:points")
                    .onValue @addPoint job.id

    addPoint: (job_id) -> (point) =>
        job = @state.jobs.filter((j) -> j.id == job_id)[0]
        job.points.push point
        @setState {}

    render: ->
        if !@state.jobs[0]?.points?.length
            return <div />

        width = window.innerWidth - 400
        height = window.innerHeight - 32 - 75

        datas = @state.jobs.map (job) ->
            data = job.points.filter (p) -> p.y < 5
            data.id = job.id
            data

        <Chart datas=datas width=width height=height color=color>
            <LineChart fill=false />
        </Chart>

JobSummary = ({item}) ->
    removeJob = -> Dispatcher.remove 'jobs', item.id
    claimJob = -> Dispatcher.claimJob item.id, 0
    <div className='item job-summary'>
        <div className='header'>
            <div className='row'>
                <span className='id'>{item.id}</span>
                <h3 className='name' style={{color: color(item.id)}}>{item.program.name}</h3>
                <a className='mini-button' onClick=removeJob>&times;</a>
            </div>
            <div className='row'>
                <span className='status'>{item.status}</span>
                {if item.machine?
                    <span className='assigned'>{item.machine.name}</span>
                }
                {if item.start_time?
                    <span className='elapsed'>{moment(item.start_time).fromNow(true)}</span>
                }
            </div>
            <pre className='params'>{JSON.stringify item.params}</pre>
        </div>
        <JobLogs job=item />
    </div>

MachineSummary = ({item}) ->
    <div className='item machine-summary'>
        <h3 className='name'>{item.name}</h3>
        <code className='host'>{item.host}</code>
    </div>

jobs$ = Dispatcher.find 'jobs', {}

App = React.createClass
    getInitialState: ->
        route: Router.route

    componentDidMount: ->
        Router.route$.onValue (route) =>
            @setState {route}

    render: ->
        <div id='content'>
            <h1>sconce-dashboard</h1>
            <div className='tabs'>
                <Link to='/jobs'>Jobs</Link>
                <Link to='/programs'>Programs</Link>
                <Link to='/machines'>Machines</Link>
            </div>

            {switch @state.route.path
                when '/programs'
                    <section className='programs-page' key='programs'>
                        <NewProgram />
                        <ReloadableList loadItems={Dispatcher.find.bind(null, 'programs', {})}>
                            <ProgramSummary />
                        </ReloadableList>
                    </section>
                when '/jobs'
                    <section className='jobs-page' key='jobs'>
                        <NewJob />
                        <div className='row'>
                            <ReloadableList loadItems={-> jobs$} style={{height: window.innerHeight - 32 - 75}}>
                                <JobSummary />
                            </ReloadableList>
                            <JobsCharts />
                        </div>
                    </section>
                when '/machines'
                    <section className='machines-page' key='machines'>
                        <NewMachine />
                        <ReloadableList loadItems={Dispatcher.find.bind(null, 'machines', {})}>
                            <MachineSummary />
                        </ReloadableList>
                    </section>
                else
                    <h2>404</h2>
            }
        </div>

ReactDOM.render <App />, document.getElementById('app')
