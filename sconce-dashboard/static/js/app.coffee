React = require 'react'
ReactDOM = require 'react-dom'
moment = require 'moment'
{Router, Link} = require 'zamba-router'
{ReloadableList, Spinner, Dropdown} = require 'common-components'
KefirBus = require 'kefir-bus'
Dispatcher = require './dispatcher'
{MultiLineChart} = require 'zamba-charts'
somata = require 'somata-socketio-client'
d3 = require 'd3'
tinycolor = require 'tinycolor2'

Store =
    job_name: 'test'

d3_color = d3.scaleOrdinal(d3.schemeCategory10)

color = (d) ->
    c = d3_color d
    tinycolor(c).lighten(20).toHexString()

dateFromObjectId = (objectId) ->
    new Date(parseInt(objectId.substring(0, 8), 16) * 1000)

inv = (key) -> (state) ->
    state[key] = !state[key]

if config.debug
    require './reload'

JobLogs = React.createClass
    getInitialState: ->
        open: false
        logs: @props.job.logs or []

    componentDidMount: ->
        somata.subscribe$('sconce:engine', "jobs:#{@props.job.id}:logs")
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
                    log.t ||= dateFromObjectId log.id
                    <div key=log.id>
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
            console.log 'jobs.onvalue'
            @setState {jobs}
            jobs.map (job) =>
                key = "jobs:#{job.id}:points"
                subscription = @subscriptions[key] =
                    sub: somata.subscribe$('sconce:engine', key)
                    fn: @addPoint job.id
                subscription.sub.onValue subscription.fn

        window.addEventListener 'resize', @resize

    resize: ->
        console.log 'resize'
        @setState {}

    componentWillUnmount: ->
        {jobs} = @state
        jobs.map (job) =>
            key = "jobs:#{job.id}:points"
            subscription = @subscriptions[key]
            subscription.sub.offValue subscription.fn

    addPoint: (job_id) -> (point) =>
        job = @state.jobs.filter((j) -> j.id == job_id)[0]
        job.points ||= []
        job.points.push point
        @setState {}

    render: ->
        width = window.innerWidth
        height = window.innerHeight

        data = @state.jobs
            .filter (job) =>
                job.name == @props.job_name and job.points? and !job.hidden
            .map (job) ->
                data = job.points.filter (point) ->
                    point.y < 7
                data.id = job.id
                data

        <MultiLineChart
            data=data
            width=width
            height=height
            color=color
            padding={left: 40, bottom: 40}
            axis_size=40
            follower=true
            y_axis={padding: 10, format: (y) -> y.toFixed(2)}
            x_axis={padding: 10}
        />

JobSummary = ({item}) ->
    removeJob = -> Dispatcher.remove 'jobs', item.id
    toggleHidden = -> jobs$.updateItem item.id, hidden: !item.hidden
    toggleCollapsed = -> jobs$.updateItem item.id, collapsed: !item.collapsed

    item_color =  color(item.id)

    class_name = 'item job-summary'
    if item.hidden
        class_name += ' hidden'
    if item.collapsed
        class_name += ' collapsed'

    <div className=class_name>
        <div className='summary' style={borderLeft: "3px solid #{item_color}"}>
            <div className='row'>
                <a className='hostname' onClick=toggleCollapsed>{item.hostname}</a>
                <a className='mini-button' onClick=toggleHidden><i className='fa fa-eye' /></a>
                <a className='mini-button' onClick=removeJob>&times;</a>
            </div>
            <div className='row'>
                <span className='status'>{item.status}</span>
                {if item.start_time?
                    <span className='elapsed'>{moment(item.start_time).fromNow(true)}</span>
                }
            </div>
            <Params params=item.params />
        </div>
        <JobLogs job=item />
    </div>

Params = ({params}) ->
    <div className='params' onClick=@toggleCollapsed>
        {Object.keys(params).map (key) ->
            value = params[key]
            <div className='param' key=key>
                <span className='key'>{key}</span>
                <span className='value'>{value}</span>
            </div>
        }
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
            <Router.render routes=routes route=@state.route />
        </div>

JobPage = ({job_name}) ->
    Store.job_name = job_name

    <section className='jobs-page' key='jobs'>
        <JobsCharts job_name={job_name} />
        <div id='sidebar'>
            <div className='tabs'>
                <span className='brand'>🔥 sconce</span>
                <span>Logged in as <strong>spro</strong></span>
            </div>

            <JobsDropdown selected=job_name />

            <ReloadableList loadItems={-> jobs$} filter={(j) -> j.name == job_name}>
                <JobSummary />
            </ReloadableList>
        </div>
    </section>

JobsDropdown = React.createClass
    getInitialState: ->
        options: []

    componentDidMount: ->
        jobs$.onValue (jobs) =>
            options = []
            counts = {}
            for job in jobs
                if job.name? and job.name not in options
                    counts[job.name] ||= 0
                    counts[job.name] += 1
            for name, count of counts
                options.push {name, count}
            @setState {options}

    render: ->
        navigate = (option) ->
            Router.navigate path: "/jobs/#{option.name}"

        <Dropdown options={@state.options} selected=@props.selected id_key='name' onChoose=navigate>
            <DropdownOption />
        </Dropdown>

DropdownOption = ({option}) ->
    <span className='option'>
        <span className='name'>{option.name}</span>
        <span className='count'>{option.count} jobs</span>
        <i className='fa fa-angle-down' />
    </span>

routes =
    '/jobs/:job_name': <JobPage />

ReactDOM.render <App />, document.getElementById('app')
