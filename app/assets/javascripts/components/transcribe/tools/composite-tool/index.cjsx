# @cjsx React.DOM
React      = require 'react'
Draggable  = require '../../../../lib/draggable'
DoneButton = require './done-button'
PrevButton = require './prev-button'

text_tool = require '../text-tool'
tools = require '../'

CompositeTool = React.createClass
  displayName: 'CompositeTool'

  # getInitialState: ->
  #   console.log 'BLAH', @props.task.tool_config.tools[0]
  #   active_field_key: @props.task.tool_config.tools[0]

  handleInitStart: (e) ->
    # console.log 'handleInitStart() '

    @setState preventDrag: false
    if e.target.nodeName is "INPUT" or e.target.nodeName is "TEXTAREA"
      @setState preventDrag: true

    @setState
      xClick: e.pageX - $('.transcribe-tool').offset().left
      yClick: e.pageY - $('.transcribe-tool').offset().top

  handleInitDrag: (e, delta) ->
    return if @state.preventDrag # not too happy about this one

    dx = e.pageX - @state.xClick - window.scrollX
    dy = e.pageY - @state.yClick # + window.scrollY

    @setState
      dx: dx
      dy: dy #, =>
      dragged: true

  getInitialState: ->
    # compute component location
    {x,y} = @getPosition @props.subject.data

    dx: x
    dy: y
    viewerSize: @props.viewerSize
    active_field_key: (key for key, value of @props.task.tool_config.tools)[0]

    # annotation: {}

  getPosition: (data) ->
    switch data.toolName
      when 'rectangleTool'
        x = data.x
        y = parseFloat(data.y) + parseFloat(data.height)
      when 'textRowTool'
        x = data.x
        y = data.yLower
      else # default for pointTool
        x = data.x
        y = data.y
    return {x,y}

  componentWillReceiveProps: ->
    @setState annotation: @props.annotation
      # active_field_key: (key for key, v of @props.task.tool_config.tools)[0]

  componentDidMount: ->
    @updatePosition()
    # @setState active_field_key: (key for key, v of @props.task.tool_config.tools)[0]

  # Expects size hash with:
  #   w: [viewer width]
  #   h: [viewer height]
  #   scale:
  #     horizontal: [horiz scaling of image to fit within above vals]
  #     vertical:   [vert scaling of image..]

  onViewerResize: (size) ->
    @setState
      viewerSize: size
    @updatePosition()

  updatePosition: ->
    # TODO: PB: Sascha is working on positioning; disabling this dep code for now:
    # if @state.viewerSize? && ! @state.dragged
      # @setState
        # dx: @props.subject.location.spec.x * @state.viewerSize.scale.horizontal
        # dy: (@props.subject.location.spec.y + @props.subject.location.spec.height) * @state.viewerSize.scale.vertical
      # console.log "TextTool#updatePosition setting state: ", @state

  # # this doesn't do anything?
  # handleFieldComplete: (key, ann) ->
  #   console.log 'COMPOSITE-TOOL::handleFieldComplete()'
  #   inp = @refs[key]
  #
  #   keys = (key for key, t in @props.task.tool_config.tools)
  #   next_key = keys[keys.indexOf(@state.active_field_key) + 1]
  #   if next_key?
  #     @setState active_field_key: next_key, () =>
  #       @forceUpdate()
  #   else
  #     @setState annotation: ann, () =>
  #       @commitAnnotation()

  handleChange: (annotation) ->
    console.log '>>>>>>>>>>>>>>>>>>>>>>>>>>>>> PAY ATTENTION TO ME <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'
    console.log "COMPOSITE-TOOL::handleChange(), key = #{key}, value = #{value}" for key, value of annotation

    console.log 'annotation = ', annotation
    @props.onChange annotation
    @setState active_field_key: key, => console.log 'SETTING STATE: ACTIVE_FIELD_KEY: ', @state.active_field_key


    return

    @props.key = key #@props.ref || 'value' # use 'value' key if standalone
    newAnnotation = []
    newAnnotation[@props.key] = value

    # if composite-tool is used, this will be a callback to CompositeTool::handleChange()
    # otherwise, it'll be a callback to Transcribe::handleDataFromTool()
    @props.onChange(newAnnotation) # report updated annotation to parent
    # @forceUpdate()

    @setState active_field_key: key, => console.log 'SETTING STATE: ACTIVE_FIELD_KEY: ', @state.active_field_key

  commitAnnotation: ->
    @props.onComplete @props.annotation

  render: ->
    console.log 'COMPOSITE-TOOL::render(), @props.annotation = ', @props.annotation
    # If user has set a custom position, position based on that:
    style =
      left: "#{@state.dx*@props.scale.horizontal}px"
      top: "#{@state.dy*@props.scale.vertical}px"

    # console.log "CompositeTool#render: ", @props, @props.task, text_tool, tools, @props.transcribe_tools
    <Draggable
      onStart = {@handleInitStart}
      onDrag  = {@handleInitDrag}
      onEnd   = {@handleInitRelease}
      x       = {@state.dx*@props.scale.horizontal}
      y       = {@state.dy*@props.scale.vertical}
    >

      <div className="transcribe-tool composite" style={style}>
        <div className="left">
          <div className="input-field active">
            <label>{@props.task.instruction}</label>
            { for annotation_key, tool_config of @props.task.tool_config.tools

              # console.log 'ANNOTATION_KEY: ', annotation_key
              # console.log 'RENDERING TOOL: ', tool_config.tool

              # console.log 'PROPS: ', @props

              # path = "../#{tool_config.tool.replace(/_/, '-')}"

              console.log 'RENDER(): ACTIVE_FIELD_KEY = ', @state.active_field_key
              ToolComponent = @props.transcribeTools[tool_config.tool]
              focus = annotation_key is @state.active_field_key

              # console.log "[[[[[[[ ANNOTATION[#{annotation_key}] ]]]]]]] = ", @props.annotation[annotation_key], ' FOCUS = ', focus

              <ToolComponent
                task={@props.task}
                subject={@props.subject}
                workflow={@props.workflow}
                standalone={false}
                viewerSize={@props.viewerSize}
                onChange={@handleChange}
                label={@props.task.tool_config.tools[annotation_key].label ? ''}
                focus={focus}
                scale={@props.scale}
                key={annotation_key}
                ref={annotation_key}
                annotation={@props.annotation}

              />
              # onComplete={@handleTaskComplete} onBack={@makeBackHandler()}
            }
          </div>
        </div>
        <div className="right">
          <PrevButton onClick={=> console.log "Prev button clicked!"} />
          <DoneButton onClick={@commitAnnotation} />
        </div>
      </div>
    </Draggable>

module.exports = CompositeTool
