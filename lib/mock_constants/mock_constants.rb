class MockConstants
  attr_reader :target
  
  def self.on target
    new.on target
  end
  def self.with add_or_update_hash={}, remove_list={}
    new.with add_or_update_hash, remove_list
  end
  
  def initialize target = Object
    @removed_constants = {} 
    @updated_constants = {}
    @added_constants = []
    @added_or_changed_constants = []
    on target
  end

  def on target
    @target = target
    self
  end
  
  def with update_hash={}, remove_list={}
    install update_hash
    remove remove_list
    result = yield
  ensure
    restore
    result
  end
  
  def install update_hash={}
    raise ArgumentError unless (update_hash.keys & (@added_or_changed_constants | @removed_constants.keys)).empty?
    @added_or_changed_constants += update_hash.keys
    update_hash.each do |name, value|
      if target.const_defined? name
        @updated_constants[name] = target.const_get name
        target.send(:remove_const, name)
      else
        @added_constants << name
      end
      target.const_set name, value
    end
    self
  end
  
  def remove symbol_or_list
    symbol_or_list = [symbol_or_list] if symbol_or_list.kind_of? Symbol
    raise ArgumentError unless symbol_or_list.all?{|const| target.const_defined? const}
    raise ArgumentError unless (symbol_or_list & @added_or_changed_constants).empty?
    remove_list symbol_or_list
    self
  end
  
  def restore
    @updated_constants.each do |name, value|
      target.send(:remove_const, name)
      target.const_set name, value
    end
    @added_constants.each do |name|
      target.send(:remove_const, name)
    end
    @removed_constants.each do |name, value|
      target.const_set name, value
    end
  end

private
  
  def remove_list remove_list
    remove_list.each do |name|
      @removed_constants[name] = target.const_get name
      target.send :remove_const, name
    end
  end
end