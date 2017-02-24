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
        <h4 className='id'>{item._id}</h4>
        <pre className='params'>{JSON.stringify item.params, null, 4}</pre>
    </div>

JobLogs = React.createClass
    getInitialState: ->
        open: false
        logs: @props.job.logs or []

    componentDidMount: ->
        somata.subscribe$('sconce:engine', "jobs:#{@props.job._id}:logs")
            .onValue @addLog
        @fixScroll()
        @update_interval = setInterval @updateState, 5000

    componentWillUnmount: ->
        clearInterval @update_interval

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
                    <div key=log._id>
                        <span>{log.body}</span>
                        <span className='t'>{moment(log.t).fromNow(true)}</span>
                    </div>
            else if log = @state.logs.slice(-1)[0]
                <div>
                    <span>{log.body}</span>
                    <span className='t'>{moment(log.t).fromNow(true)}</span>
                </div>
            }
        </div>

JobsCharts = React.createClass
    getInitialState: ->
        jobs: []

    componentDidMount: ->
        @subscriptions = {}
        jobs$.onValue (jobs) =>
            @setState {jobs}
            jobs.map (job) =>
                key = "jobs:#{job._id}:points"
                subscription = @subscriptions[key] =
                    sub: somata.subscribe$('sconce:engine', key)
                    fn: @addPoint job._id
                subscription.sub.onValue subscription.fn

    componentWillUnmount: ->
        {jobs} = @state
        jobs.map (job) =>
            key = "jobs:#{job._id}:points"
            subscription = @subscriptions[key]
            subscription.sub.offValue subscription.fn

    addPoint: (job_id) -> (point) =>
        job = @state.jobs.filter((j) -> j._id == job_id)[0]
        job.points ||= []
        job.points.push point
        @setState {}

    render: ->
        if !@state.jobs[0]?.points?.length
            return <div />

        width = window.innerWidth - 400
        height = window.innerHeight - 32

        datas = @state.jobs
            .filter (job) ->
                job.points?
            .map (job) ->
                data = job.points.filter (point) ->
                    point.y < 7
                data.id = job._id
                data

        <Chart datas=datas width=width height=height color=color>
            <LineChart fill=false />
        </Chart>

JobSummary = ({item}) ->
    removeJob = -> Dispatcher.remove 'jobs', item._id
    claimJob = -> Dispatcher.claimJob item._id, 0
    <div className='item job-summary'>
        <div className='header'>
            <div className='row'>
                <h3 className='name' style={{color: color(item._id)}}>{item.program.name}</h3>
                <h4 className='id'>{item._id}</h4>
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
        <h4 className='id'>{item._id}</h4>
        <code className='host'>{item.host}</code>
    </div>

jobs$ = Dispatcher.find('jobs', {})
somata.subscribe$('sconce:engine', "jobs")
    .onValue (job) -> jobs$.createItem job

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
                        <div className='row'>
                            <ReloadableList loadItems={-> jobs$} style={{height: window.innerHeight - 32}}>
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
