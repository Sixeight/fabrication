class Fabrication::Schematic::Definition

  GENERATORS = [
    Fabrication::Generator::ActiveRecord,
    Fabrication::Generator::DataMapper,
    Fabrication::Generator::Sequel,
    Fabrication::Generator::Mongoid,
    Fabrication::Generator::Base
  ]

  attr_accessor :klass
  def initialize(klass, &block)
    self.klass = klass
    Fabrication::Schematic::Evaluator.new(self, &block) if block_given?
  end

  def attribute(name)
    attributes.detect { |a| a.name == name }
  end

  def append_or_update_attribute(attribute_name, value, params={}, &block)
    attribute = Fabrication::Schematic::Attribute.new(attribute_name, value, params, &block)
    if index = attributes.index { |a| a.name == attribute.name }
      attribute.transient! if attributes[index].transient?
      attributes[index] = attribute
    else
      attributes << attribute
    end
  end

  attr_writer :attributes
  def attributes
    @attributes ||= []
  end

  attr_writer :callbacks
  def callbacks
    @callbacks ||= {}
  end

  def generator
    @generator ||= GENERATORS.detect { |gen| gen.supports?(klass) }
  end

  def build(overrides={}, &block)
    Fabrication.schematics.build_stack << self
    merge(overrides, &block).instance_eval do
      generator.new(klass).build(attributes, callbacks)
    end
  ensure
    Fabrication.schematics.build_stack.pop
  end

  def fabricate(overrides={}, &block)
    if Fabrication.schematics.build_stack.empty?
      merge(overrides, &block).instance_eval do
        generator.new(klass).create(attributes, callbacks)
      end
    else
      build(overrides, &block)
    end
  end

  def to_attributes(overrides={}, &block)
    merge(overrides, &block).instance_eval do
      generator.new(klass).to_hash(attributes, callbacks)
    end
  end

  def initialize_copy(original)
    self.callbacks = {}
    original.callbacks.each do |type, callbacks|
      self.callbacks[type] = callbacks.clone
    end

    self.attributes = original.attributes.clone
  end

  def init_with(*args); args end

  def merge(overrides={}, &block)
    clone.tap do |schematic|
      schematic.instance_eval(&block) if block_given?
      overrides.each do |name, value|
        schematic.append_or_update_attribute(name.to_sym, value)
      end
    end
  end

  private

  def generate_value(name, params)
    if params[:count]
      name = name.to_s.singularize if name.to_s.respond_to?(:singularize)
      Proc.new { Fabricate.build(params[:fabricator] || name) }
    else
      Proc.new { Fabricate(params[:fabricator] || name) }
    end
  end
end
