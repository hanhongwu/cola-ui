class cola.WidgetDataModel extends cola.AbstractDataModel
	constructor: (model, @widget) ->
		super(model)

	get: (path, loadMode, context) ->
		if path.charCodeAt(0) is 64 # `@`
			return @widget.get(path.substring(1))
		else
			return @model.parent?.data.get(path, loadMode, context)

	set: (path, value) ->
		if path.charCodeAt(0) is 64 # `@`
			@widget.set(path.substring(1), value)
			@onDataMessage(path.split("."), cola.constants.MESSAGE_PROPERTY_CHANGE, {})
		else
			@model.parent?.data.set(path, value)
		return

	processMessage: (bindingPath, path, type, arg) ->
		@onDataMessage(path, type, arg)

		entity = arg.entity or arg.entityList
		if entity
			for attr, value of @widget._entityProps
				isParent = false
				e = entity
				while e
					if e is value
						isParent = true
						break
					e = e.parent

				if isParent
					targetPath = value.getPath()
					if targetPath?.length
						relativePath = path.slice(targetPath.length)
						@onDataMessage(["@" + attr].concat(relativePath), type, arg)
		return

	getDataType: (path) ->
		if path.charCodeAt(0) is 64 # `@`
			return null
		else
			return @model.parent?.data.getDataType(path)

	getProperty: (path) ->
		if path.charCodeAt(0) is 64 # `@`
			return null
		else
			return @model.parent?.data.getDataType(path)

	flush: (name, loadMode) ->
		if path.charCodeAt(0) isnt 64 # `@`
			@model.parent?.data.getDataType(name, loadMode)
		return @

class cola.WidgetModel extends cola.SubScope
	constructor: (@widget, @parent) ->
		widget = @widget
		@data = new cola.WidgetDataModel(@, widget)
		@parent?.data.bind("**", @)

		@action = (name) ->
			method = widget[name]
			if method instanceof Function
				return () -> method.apply(widget, arguments)
			return widget._scope.action(name)

	repeatNotification: true

	processMessage: (bindingPath, path, type, arg) ->
		if @messageTimestamp >= arg.timestamp then return
		return @data.processMessage(bindingPath, path, type, arg)

class cola.TemplateWidget extends cola.Widget