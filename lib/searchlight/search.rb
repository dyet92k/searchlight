module Searchlight
  class Search
    extend DSL

    attr_accessor :options

    def self.search_target
      return @search_target           if defined?(@search_target)
      return superclass.search_target if superclass.respond_to?(:search_target) && superclass != Searchlight::Search
      guess_search_class!
    end

    def initialize(options = {})
      self.options = options.reject {|k, v| blank_value?(v) }
      options.each { |key, value| public_send("#{key}=", value) } if options && options.any?
    rescue NoMethodError => e
      raise UndefinedOption.new(e.name, self.class.name)
    end

    def search
      @search ||= self.class.search_target
    end

    def results
      @results ||= run
    end

    protected

    attr_writer :search

    private

    def self.guess_search_class!
      if self.name.end_with?('Search')
        @search_target = name.sub(/Search\z/, '').split('::').inject(Kernel, &:const_get)
      else
        raise MissingSearchTarget, "No search target provided via `search_on` and Searchlight can't guess one."
      end
    rescue NameError => e
      if /uninitialized constant/.match(e.message)
        raise MissingSearchTarget, "No search target provided via `search_on` and Searchlight's guess was wrong. Error: #{e.message}"
      end
      raise e
    end

    def self.search_target=(value)
      @search_target = value
    end

    def search_methods
      public_methods.map(&:to_s).select { |m| m.start_with?('search_') }
    end

    def run
      search_methods.each do |method|
        new_search  = run_search_method(method)
        self.search = new_search unless new_search.nil?
      end
      search
    end

    def run_search_method(method_name)
      option_value = instance_variable_get("@#{method_name.sub(/\Asearch_/, '')}")
      option_value = option_value.reject { |item| blank_value?(item) } if option_value.respond_to?(:reject)
      public_send(method_name) unless blank_value?(option_value)
    end

    # Note that false is not blank
    def blank_value?(value)
      (value.respond_to?(:empty?) && value.empty?) || value.nil? || value.to_s.strip == ''
    end

    MissingSearchTarget = Class.new(Searchlight::Error)

    class UndefinedOption < Searchlight::Error

      attr_accessor :message

      def initialize(option_name, search_class)
        option_name = option_name.to_s.sub(/=\Z/, '')
        self.message = "#{search_class} doesn't search '#{option_name}'."
        if option_name.start_with?('search_')
          # Gee golly, I'm so helpful!
          self.message << " Did you just mean '#{option_name.sub(/\Asearch_/, '')}'?"
        end
      end

      def to_s
        message
      end

    end

  end
end
