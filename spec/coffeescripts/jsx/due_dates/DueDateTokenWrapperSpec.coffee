define [
  'react'
  'react-dom'
  'underscore'
  'jsx/due_dates/DueDateTokenWrapper'
  'jsx/due_dates/OverrideStudentStore'
  'helpers/fakeENV'
], (React, ReactDOM, _, DueDateTokenWrapper, OverrideStudentStore, fakeENV) ->

  Simulate = React.addons.TestUtils.Simulate
  SimulateNative = React.addons.TestUtils.SimulateNative

  module 'DueDateTokenWrapper',
    setup: ->
      fakeENV.setup(context_asset_string = "course_1")
      @clock = sinon.useFakeTimers()
      @props =
        tokens: [
          {name: "Atilla", student_id: "3", type: "student"},
          {name: "Huns", course_section_id: "4", type: "section"},
          {name: "Reading Group 3", group_id: "3", type: "group"}
        ]
        potentialOptions: [
          {course_section_id: "1", name: "Patricians"},
          {id: "1", name: "Seneca The Elder"},
          {id: "2", name: "Agrippa"},
          {id: "3", name: "Publius"},
          {id: "4", name: "Scipio"},
          {course_section_id: "2", name: "Plebs | [ $"}, # named strangely to test regex
          {course_section_id: "3", name: "Foo"},
          {course_section_id: "4", name: "Bar"},
          {course_section_id: "5", name: "Baz"},
          {course_section_id: "6", name: "Qux"},
          {group_id: "1", name: "Reading Group One"},
          {group_id: "2", name: "Reading Group Two"}
        ]
        handleTokenAdd: ->
        handleTokenRemove: ->
        defaultSectionNamer: ->
        allStudentsFetched: false
        currentlySearching: false
        rowKey: "nullnullnull"

      @mountPoint = $('<div>').appendTo('body')[0]
      DueDateTokenWrapperElement = React.createElement(DueDateTokenWrapper, @props)
      @DueDateTokenWrapper = ReactDOM.render(DueDateTokenWrapperElement, @mountPoint)
      @TokenInput = @DueDateTokenWrapper.refs.TokenInput

    teardown: ->
      @clock.restore()
      ReactDOM.unmountComponentAtNode(@mountPoint)
      fakeENV.teardown()

  test 'renders', ->
    ok @DueDateTokenWrapper.isMounted()

  test 'renders a TokenInput', ->
    ok @TokenInput.isMounted()

  test 'call to fetchStudents on input changes', ->
    fetch = @stub(@DueDateTokenWrapper, "safeFetchStudents")
    @DueDateTokenWrapper.handleInput("to")
    equal fetch.callCount, 1
    @DueDateTokenWrapper.handleInput("tre")
    equal fetch.callCount, 2

  test 'if a user types handleInput filters the options', ->
    # having debouncing enabled for fetching makes tests hard to
    # contend with.
    @DueDateTokenWrapper.removeTimingSafeties()

    # 1 prompt, 3 sections, 4 students, 2 groups, 3 headers = 13
    equal @DueDateTokenWrapper.optionsForMenu().length, 13

    @DueDateTokenWrapper.handleInput("scipio")
    # 0 sections, 1 student, 1 header = 2
    equal @DueDateTokenWrapper.optionsForMenu().length, 2

  test 'menu options are grouped by type', ->
    equal @DueDateTokenWrapper.optionsForMenu()[1].props.value, "course_section"
    equal @DueDateTokenWrapper.optionsForMenu()[2].props.value, "Patricians"
    equal @DueDateTokenWrapper.optionsForMenu()[5].props.value, "group"
    equal @DueDateTokenWrapper.optionsForMenu()[6].props.value, "Reading Group One"
    equal @DueDateTokenWrapper.optionsForMenu()[8].props.value, "student"
    equal @DueDateTokenWrapper.optionsForMenu()[9].props.value, "Seneca The Elder"

  test 'handleTokenAdd is called when a token is added', ->
    addProp = @stub(@props, "handleTokenAdd")
    DueDateTokenWrapperElement = React.createElement(DueDateTokenWrapper, @props)
    @DueDateTokenWrapper = ReactDOM.render(DueDateTokenWrapperElement, @mountPoint)
    @DueDateTokenWrapper.handleTokenAdd("sene")
    ok addProp.calledOnce
    addProp.restore()

  test 'handleTokenRemove is called when a token is removed', ->
    removeProp = @stub(@props, "handleTokenRemove")
    DueDateTokenWrapperElement = React.createElement(DueDateTokenWrapper, @props)
    @DueDateTokenWrapper = ReactDOM.render(DueDateTokenWrapperElement, @mountPoint)
    @DueDateTokenWrapper.handleTokenRemove("sene")
    ok removeProp.calledOnce
    removeProp.restore()

  test 'findMatchingOption can match a string with a token', ->
    foundToken = @DueDateTokenWrapper.findMatchingOption("sci")
    equal foundToken["name"], "Scipio"
    foundToken = @DueDateTokenWrapper.findMatchingOption("pub")
    equal foundToken["name"], "Publius"

  test 'findMatchingOption can handle strings with weird characters', ->
    foundToken = @DueDateTokenWrapper.findMatchingOption("Plebs | [")
    equal foundToken["name"], "Plebs | [ $"

  test 'findMatchingOption can match characters in the middle of a string', ->
    foundToken = @DueDateTokenWrapper.findMatchingOption("The Elder")
    equal foundToken["name"], "Seneca The Elder"

  test 'hidingValidMatches updates as matching tag number changes', ->
    ok @DueDateTokenWrapper.hidingValidMatches()

    @DueDateTokenWrapper.handleInput("scipio")
    ok !@DueDateTokenWrapper.hidingValidMatches()
