class Fabrication::Schematic::Evaluator < BasicObject + :instance_eval

  def initialize(definition, &block)
    @_definition = definition
    instance_eval(&block)
  end

  def method_missing(method_name, *args, &block)
    params = ::Fabrication::Support.extract_options!(args)
    value = args.first
    block = @_definition.generate_value(method_name, params) if args.empty? && !block_given?
    @_definition.append_or_update_attribute(method_name, value, params, &block)
  end

  def after_build(&block)
    @_definition.callbacks[:after_build] ||= []
    @_definition.callbacks[:after_build] << block
  end

  def after_create(&block)
    @_definition.callbacks[:after_create] ||= []
    @_definition.callbacks[:after_create] << block
  end

  def on_init(&block)
    @_definition.callbacks[:on_init] = block
  end

  def initialize_with(&block)
    @_definition.callbacks[:initialize_with] = block
  end

  def transient(*field_names)
    field_names.each do |field_name|
      @_definition.append_or_update_attribute(field_name, nil, transient: true)
    end
  end

  def sequence(name=::Fabrication::Sequencer::DEFAULT, start=nil, &block)
    name = "#{@_definition.klass.to_s.downcase.gsub(/::/, '_')}_#{name}"
    ::Fabrication::Sequencer.sequence(name, start, &block)
  end

end
